
# Timer Peripheral Verification Environment

## Overview
This project implements a SystemVerilog-based verification environment for a simple timer peripheral IP (DUT: `timer_periph.sv`). The timer supports countdown with optional auto-reload, status checking, and bus-based configuration. The verification uses a UVM-inspired methodology (without full UVM library) including transactions, driver, monitor, reference model, scoreboard, coverage collector, and sequencer for directed/random tests.

**Key Features**:
- Bus protocol with handshake (REQ/GNT) and assertions for protocol checking.
- Reference model for golden behavior comparison.
- Functional coverage for addresses, data, operations.
- Python scripts for file dependency sorting, result analysis, and simulation automation.
- ModelSim/QuestaSim scripts for compilation, elaboration, and simulation.

**Design Rationale**:
- **Modular and Reusable**: Components are classes connected via mailboxes for loose coupling, allowing easy extension (e.g., adding more tests or IPs).
- **UVM-Inspired but Lightweight**: Avoids full UVM overhead for simplicity, focusing on core verification patterns (transactions, phases, mailboxes).
- **Automation-First**: Scripts handle file ordering (topological sort for dependencies) and post-simulation analysis to reduce manual errors.
- **Coverage-Driven**: Includes directed tests for basic functionality, corner cases for edge behavior, and random stimulus for stress testing, with explicit coverage closure tasks.
- **Assertions**: Built-in SVAs in the interface for real-time protocol violation detection.
- **Simulation Modes**: Supports GUI (waveform viewing) and batch modes for CI/CD integration.

## File Structure
The project is organized into directories for clarity (inferred from file references; adjust as needed):

- **design/**: RTL design files.
  - `timer_periph.sv`: DUT (timer peripheral module).
  - `bus_if.sv`: Bus interface with clocking blocks, modports, and SVAs.
  - `design_params_pkg.sv`: Parameters (e.g., addresses, bit positions).
  - `module_pkg.sv`: Imports params and includes interface/DUT (for top-level use).

- **verification/**: Verification components and tests.
  - `design_pkg.sv`: Main package including all verification classes.
  - `BusTrans.sv`: Base transaction class (address, data, kind).
  - `WriteTrans.sv`: Derived write transaction.
  - `ReadTrans.sv`: Derived read transaction.
  - `Driver.sv`: Drives transactions to DUT via virtual interface.
  - `Monitor.sv`: Observes bus, captures actual transactions, samples coverage.
  - `RefDutTimer.sv`: Golden reference model simulating timer behavior.
  - `Scoreboard.sv`: Compares expected (ref) vs. actual (mon) transactions.
  - `Sequencer.sv`: Generates stimulus (directed/random sequences).
  - `Coverage.sv`: Functional coverage group for transactions.
  - `TbEnv.sv`: Top environment connecting all components.
  - `BaseTest.sv`: Base test class with scenarios (from VPlan).
  - `tb_top_timer.sv`: Top testbench instantiating DUT, interface, and test.
  - `timer_ref.sv`: (Commented out) Alternative reference model (legacy?).

- **scripts/**: Automation scripts.
  - `run.py`: Main runner for compilation, simulation, coverage, and analysis.
  - `run_dependencies.py`: Sorts RTL files topologically (interfaces → packages → modules → TB).
  - `analyze_results.py`: Parses simulation logs for matches/mismatches/errors.

- **sim/**: Simulation-related (e.g., work libraries, logs).
  - `compile.do`: Questa script for compiling design/verification.
  - `elaborate.do`: Questa script for elaboration with coverage.

- **docs/**: Outputs (e.g., coverage reports, file lists).

## Component Purposes and Architecture
The architecture follows a standard verification flow: Stimulus generation → Driving to DUT → Monitoring responses → Comparison with reference → Coverage collection.

### Key Components and Purposes
1. **Transactions (`BusTrans.sv`, `WriteTrans.sv`, `ReadTrans.sv`)**:
   - Purpose: Represent bus operations (read/write) with fields like addr, data, kind, unique ID.
   - Design Choice: Base class with derived types for polymorphism; unique IDs for tracking in scoreboard.
   - Rationale: Encapsulates stimulus/data for easy randomization and display.

2. **Driver (`Driver.sv`)**:
   - Purpose: Receives transactions from sequencer, drives signals to DUT via virtual interface (handshake protocol: assert REQ, wait GNT).
   - Design Choice: Uses clocking block for timing; separates read/write tasks.

3. **Monitor (`Monitor.sv`)**:
   - Purpose: Passively samples bus signals, creates actual transactions, sends to scoreboard, samples coverage.
   - Design Choice: Queue for intended transactions (from driver) to match IDs; passive (no driving).

4. **Reference Model (`RefDutTimer.sv`)**:
   - Purpose: Golden model processes transactions like DUT, generates expected responses (e.g., timer countdown, reload).
   - Design Choice: Forked thread for async countdown; mailbox-based input/output.
   - Rationale: Behavioral model for self-checking (no need for assertions on every signal).

5. **Scoreboard (`Scoreboard.sv`)**:
   - Purpose: Collects expected (from ref) and actual (from mon) transactions, compares by ID (addr/data/kind match).
   - Design Choice: Associative array for expected queue; mismatch logging.

6. **Sequencer (`Sequencer.sv`)**:
   - Purpose: Generates stimulus sequences (directed: e.g., load/start/check; random: constrained RW; coverage closure).
   - Design Choice: Tasks for reusable sequences; randomization with constraints.

7. **Coverage (`Coverage.sv`)**:
   - Purpose: Collects functional coverage (bins/crosses for addr, data, kind, reload/expired bits).
   - Design Choice: Covergroup with per-instance options; sampled on monitor transactions.

8. **Environment (`TbEnv.sv`)**:
   - Purpose: Instantiates and connects all components via mailboxes; provides reset/run methods.
   - Design Choice: Mailboxes for communication (non-blocking, FIFO).

9. **Test (`BaseTest.sv`)**:
   - Purpose: Implements VPlan scenarios (basic countdown, reload, zero-load, mid-count restart, random RW).
   - Design Choice: Sequential phases (directed → corners → random → coverage); forks env in background.

10. **DUT and Interface (`timer_periph.sv`, `bus_if.sv`)**:
    - Purpose: Timer RTL (FSM for handshake/timer) and bus IF (clocking/modports/SVAs for protocol checks).
    - Design Choice: FSMs for state management; SVAs for liveness/stability/unknown checks.

11. **Top Testbench (`tb_top_timer.sv`)**:
    - Purpose: Instantiates DUT, interface, clock/reset, and runs test.

### Connections and Communication
- **Mailboxes**: Primary mechanism (loose coupling).
  - Sequencer → Driver/Ref: `m_seq_drv_mb` / `m_seq_ref_mb` (put transactions).
  - Monitor → Scoreboard: `m_mon_sb_mb` (actual transactions).
  - Ref → Scoreboard: `m_ref_sb_mb` (expected transactions).
- **Virtual Interface**: Driver/Monitor/Ref share `bus_if` for signal access (driver drives, monitor samples, ref uses clock for timing).
- **Flow**:
  1. Test calls Sequencer tasks → Transactions to Driver/Ref.
  2. Driver drives DUT → DUT responds on bus.
  3. Monitor samples bus → Sends actual to Scoreboard; samples Coverage.
  4. Ref processes same transaction → Sends expected to Scoreboard.
  5. Scoreboard compares (by ID) → Logs match/mismatch.
- **Rationale**: Mailboxes enable parallel execution (fork/join); virtual IF abstracts hardware access.

## Compile to Simulation Process
1. **Dependency Sorting** (`run_dependencies.py`):
   - Run: `python run_dependencies.py`.
   - Purpose: Scans `design/` for .sv/.v files, classifies (interfaces/packages/RTL/TB), sorts topologically → Outputs `docs/design.f` (compile list) and `docs/files_order.txt`.
   - Rationale: Ensures correct order (e.g., interfaces before modules).

2. **Compilation** (`compile.do` via `run.py`):
   - Run: `python run.py` (selects testbench, compiles).
   - Steps: Creates libraries (`work`, `design_work`); compiles params, IF, pkg, DUT, testbench using `vlog`.
   - Output: Compiled libraries in `sim/`.

3. **Elaboration** (`elaborate.do` via `run.py`):
   - Steps: Optimizes with coverage (`vopt +cover`); creates snapshot.
   - Output: Optimized design in `sim/`.

4. **Simulation** (via `run.py`):
   - Batch: `vsim` with logfile, coverage DB; runs non-GUI.
   - GUI: `vsim -gui` with wave do-file (adds waves).
   - Coverage: Generates `docs/coverage_report.txt` via `vcover`.

5. **Analysis** (`analyze_results.py` via `run.py`):
   - Parses log for matches/mismatches/errors/SVAs → Outputs colored summary and `summary_report.txt`.
   - Exit code: 0 (PASS) or 1 (FAIL).

**Full Flow**: `python run.py` (handles all; prompts for testbench/GUI/batch).
- **Rationale**: Automation reduces errors; supports regression (batch) and debug (GUI).

## Getting Started
1. Install QuestaSim/ModelSim and Python 3.
2. Run `python scripts/run_dependencies.py` for file ordering.
3. Run `python scripts/run.py` to compile/simulate/analyze.
4. View coverage: Open `docs/coverage_report.txt`.
5. Extend: Add tests in `BaseTest.sv`; update VPlan in comments.

## Known Limitations
- No full UVM (custom mailboxes instead).
- Randomization constraints are commented (enable for stricter tests).
- Assumes 10ns clock; adjust in `tb_top_timer.sv`.

For questions, see top of this README.

--- 
