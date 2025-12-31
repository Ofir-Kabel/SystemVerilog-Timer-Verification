
# SystemVerilog Timer Verification Environment

![Verification Environment Architecture](docs/MidProTB_diagram.png)

## 📌 Overview
This repository hosts a robust, **pure SystemVerilog (SV)** verification environment for a Timer Peripheral IP. 
Designed without the overhead of UVM, this project implements a **layered, object-oriented architecture** that mirrors UVM methodologies. It verifies a programmable countdown timer supporting one-shot and auto-reload modes via a standardized REQ/GNT bus protocol.

The environment demonstrates advanced verification concepts including **Constrained Random Verification (CRV)**, **Self-Checking mechanisms**, and **Functional Coverage**, automated via Python scripts.

## 🏗️ Architecture & Communication Mechanisms
The environment bridges the gap between dynamic testbench components and the static hardware design using SystemVerilog's powerful constructs:

### 1. Dynamic-to-Static Communication (Virtual Interface)
* **The Problem:** Class-based components (Driver, Monitor) are dynamic and cannot directly access static signals in the DUT (Device Under Test).
* **The Solution:** A **SystemVerilog Interface (`bus_if`)** encapsulates all bus signals and assertions. A **`virtual interface`** handle is passed from the top-level module to the class objects, allowing dynamic components to drive and sample physical signals synchronously and safely.

### 2. Dynamic-to-Dynamic Communication (Mailboxes)
* **Data Flow:** Components communicate via **typed Mailboxes**, ensuring thread-safe data transfer without global variables.
    * **Generator ➔ Driver:** Passes randomized `BusTrans` objects.
    * **Monitor ➔ Scoreboard:** Passes sampled transactions for verification.
* **Modularity:** This decoupled approach allows components to operate independently, making the environment highly reusable and scalable.

## ✨ Key Features
* **Methodology:** Layered Testbench (Test ➔ Env ➔ Agent ➔ Driver/Monitor).
* **Protocol Verification:** Embedded **SVA (SystemVerilog Assertions)** within the interface to validate REQ/GNT handshakes and timeouts.
* **Golden Reference Model:** A bit-accurate SV model (`RefDutTimer`) running in parallel to predict expected behavior.
* **Scoreboard:** Automatic, real-time comparison of DUT outputs vs. Reference Model.
* **Coverage Driven:** 100% functional coverage targets (Operations, Addresses, Modes, and Cross-coverage).
* **Automation:** Python-based workflow for dependency management, compilation, and regression analysis.

## 📂 Directory Structure
The project is organized for clarity and automation:

```text
ProjectFolder/
├── design/             # Source Code
│   ├── bus_if.sv       # Interface with Assertions
│   ├── timer_periph.sv # DUT (Timer IP)
│   ├── Driver.sv       # Drives signals via virtual interface
│   ├── Monitor.sv      # Samples signals via virtual interface
│   ├── Scoreboard.sv   # Data integrity check
│   └── ...             # Transactions, Coverage, etc.
├── verification/       # Top Level
│   └── tb_top_timer.sv # Connects DUT and Testbench
├── scripts/            # Python Automation
│   ├── run.py          # Main execution script
│   └── analyze_results.py
└── docs/               # Documentation & Logs
    ├── MidProTB_diagram.png
    └── VerificationPlanMidPro.pdf

```

## 🚀 Getting Started

### Prerequisites

* **Simulator:** Siemens ModelSim / QuestaSim.
* **Python:** 3.x (for build scripts).

### How to Run

1. **Clone the repository:**
```bash
git clone [https://github.com/YourUsername/SystemVerilog-Timer-Verification.git](https://github.com/YourUsername/SystemVerilog-Timer-Verification.git)
cd ProjectFolder

```


2. **Sort Dependencies & Compile:**
```bash
python scripts/run_dependencies.py

```


3. **Run Simulation:**
```bash
# Run in Batch mode (results saved to logs)
python scripts/run.py

# OR Run in GUI mode for debugging
# (Select GUI option when prompted)

```


4. **Analyze Results:**
Check `docs/summary_report.txt` for pass/fail status and coverage metrics.

## 📊 Verification Plan Summary

The environment validates the following scenarios:

* **Basic Operations:** Reset, Load, Enable, Countdown.
* **Modes:** One-shot vs. Auto-reload behavior.
* **Corner Cases:** Zero-value loads, Reset during active count, Wrap-around.
* **Protocol:** Bus contention and handshake validity (via SVA).

---

**Author:** Ofir Kabel

**Developed:** December 2025


