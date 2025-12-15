---
marp: true
theme: default
paginate: true
header: "Timer Peripheral Verification Plan"
footer: "VPlan | Rev 1.0"
style: |
  section {
    font-size: 22px;
  }
  table {
    font-size: 18px;
    width: 100%;
  }
  th {
    background-color: #f0f0f0;
  }
---

# Verification Plan (VPlan)
## Timer Peripheral
### Project Overview, Strategy, and Execution

---

# 1. Project Overview & Scope



**DUT Summary**
The design is a Simple Countdown Timer Peripheral for SoC integration.
* **Interface:** 32-bit word-aligned slave, REQ/GNT handshake.
* **Core:** Programmable countdown via `LOAD`, One-shot/Auto-reload modes.
* **Registers:** `CONTROL` (0x00), `LOAD` (0x04), `STATUS` (0x08).

**Verification Objectives**
* **Functional Accuracy:** Verify modes and register behavior.
* **Timing Correctness:** Adherence to bus protocol (latency).
* **Data Integrity:** Correct register access.

---

# 1.1 Scope Definitions

| **In Scope** | **Out of Scope** |
| :--- | :--- |
| Bus Read/Write interface operations. | Power consumption. |
| Timer behavior (reset/reload_en). | Misaligned address access. |
| **Bus timing:** Slave must assert `gnt` within ≤3 cycles after `req`. | External bus arbitration. |
| Corner cases (e.g., LOAD=0 treated as 1). | Other corner cases not explicitly mentioned. |

---

# 2. Verification Strategy & Architecture



**Methodology**
* SystemVerilog OOP testbench.
* Components (Driver, Monitor, Scoreboard, RefModel) run in parallel via `fork/join` in `TbEnv`.

**Stimulus Generation**
* **Hybrid Approach:**
    * **Constrained-Random:** `rand_read_write` for general coverage.
    * **Directed:** Specific features and corner cases (e.g., Loading zero).

---

# 2.1 Checking Mechanisms

**Self-Checking Scoreboard**
* Matches Monitor transactions (`mon_sb_mb`) against Reference Model (`ref_sb_mb`).
* Uses a unique transaction ID (`m_unique_id`) for synchronization.

**Protocol Checking (SVA)**
* Implemented in `bus_if`.
* Checks temporal requirements like `req_before_gnt_p` (GNT within 3 cycles).
* Verifies data stability (`master_data_stability_p`).

**Reference Model (`RefDutTimer`)**
* Maintains internal registers and models functional behavior.
* Implements logic to clear the status flag upon reading the `STATUS` register.

---

# 3. Requirements Traceability Matrix (RTM)

| ID | Requirement | Method | Artifact/Script |
| :--- | :--- | :--- | :--- |
| **R1** | `gnt` within ≤3 cycles after `req`. | Assertion | `bus_if: req_before_gnt_p`. |
| **R2** | `STATUS.EXPIRED` clears on read. | Dir / Ref | `checking_status()`, `read_ref`. |
| **R3** | Reload when `RELOAD_EN=1`. | Dir / SB | `Test3()`, `start_count(1)`. |
| **R4** | Write 0 to `LOAD` treated as 1. | Dir / Ref | `loading(0)`, Ref Logic. |
| **R5** | Writing `START=1` restarts timer. | Directed | `Test3()` (successive calls). |
| **R6** | Reset clears registers & stops counter. | Directed | `reset()` task. |

---

# 4. Functional Coverage Plan

**Target Goal:** 100% Coverage.

| Coverage Item | Description | Source Bins |
| :--- | :--- | :--- |
| **Address** (`addr_cp`) | Legal registers & out-of-range addresses. | `control`, `load`, `status`, `out_range`. |
| **Op Kind** (`kind_cp`) | WRITE and READ transactions. | `write`, `read`. |
| **Reload Mode** (`reload_en_cp`) | `RELOAD_EN` bit (bit 1) enabled/disabled. | `tr.m_data` on `CONTROL`. |
| **Expired** (`expired_cp`) | `EXPIRED` flag (bit 0) SET/CLEAR. | `tr.m_data` on `STATUS`. |
| **Cross Coverage** | Address vs. Op Kind; Op Kind vs. Reload. | `kind_addr_cross`, `cross_kind_reload`. |

---

# 5. Test Plan and Stimulus Execution

| Test Name | Type | Purpose | Sequencer Task |
| :--- | :--- | :--- | :--- |
| **Test1** | Directed | Basic One-shot/Reload & Status clear (R2, R3). | `loading`, `start_count`, `checking_status`. |
| **Test2** | Directed | Register access & Data integrity (R2). | `specific_write`, `specific_read`. |
| **Test3** | Directed | Complex sequencing: Reset, mid-count restart (R5, R6). | `reset()`, successive `start_count`. |
| **Load_Zero** | Directed | Corner Case: Load 0 treated as 1 (R4). | `m_seq.loading(0)`. |
| **Random_RW** | Random | Maximize address/data coverage. | `m_seq.rand_read_write(N)`. |

---

# 6. Closure & Metrics

**Exit Criteria**
1.  **Functional Coverage:** 100% of defined targets met.
2.  **Test Plan:** All directed/random tests passing.
3.  **Assertions:** Critical properties (`req_before_gnt_p`) must pass.
4.  **Bug Rate:** Critical/Major bugs fixed, 48hr stability.

**Reflection on Randomization**
Constrained-Random stimulus is essential to close coverage faster. It ensures exploration of valid address/data combinations and cross-coverage interactions that directed tests might miss.