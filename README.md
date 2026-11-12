# OpenPLC v4 Conveyor Belt Control & Item Counter

A Structured Text (ST) IEC 61131-3 PLC program designed for **OpenPLC Runtime v4**. This project implements a latched conveyor motor control system with HMI pushbuttons, a rising-edge item counter, and a built-in timer-based sensor simulator for standalone testing without physical hardware.

---

## 📋 Overview

This program simulates and controls an automated industrial conveyor belt. When started via an HMI signal, the conveyor motor latches on and runs continuously until a stop signal is received. While running, an internal timer simulates items passing an optical/proximity sensor every 4 seconds, incrementing a global item counter on each rising edge.

### Key Features
* **Start/Stop Latching Logic:** Stop-dominant motor control circuit ensuring safe shutdowns.
* **Built-in Sensor Simulation:** Uses an on-delay timer (`TON`) to automatically pulse the `Item_Sensor` every 4 seconds while the belt is active, ideal for HMI and SCADA testing.
* **Rising-Edge Detection:** Utilizes an `R_TRIG` function block to ensure each item is counted strictly once per pass.
* **HMI Momentary Button Handling:** Automatically resets simulated momentary HMI start states when the system stops.

---

## 🔌 I/O & Variable Mapping

### Local Variables (`VAR`)

| Variable | Data Type | Address | Description |
| :--- | :--- | :--- | :--- |
| `HMI_Start` | `BOOL` | `%QX0.0` | HMI Start pushbutton trigger |
| `HMI_Stop` | `BOOL` | `%QX0.1` | HMI Stop pushbutton trigger (Stop-dominant) |
| `Conveyor_Motor` | `BOOL` | `%QX0.2` | Output coil controlling the conveyor belt motor |
| `Item_Sensor` | `BOOL` | `%QX0.3` | Simulated sensor output (`TRUE` during item detection) |
| `Item_Timer` | `TON` | *Internal* | 4-second cycle timer used for item sensor simulation |
| `Sensor_Trigger` | `R_TRIG` | *Internal* | Rising-edge detector for accurate item counting |

### External / Global Variables (`VAR_EXTERNAL`)

| Variable | Data Type | Scope | Description |
| :--- | :--- | :--- | :--- |
| `Item_Count` | `INT` | Global | Accumulator storing the total number of items counted |

> **Note:** Because `Item_Count` is declared as `VAR_EXTERNAL`, you must also define `Item_Count` as a `VAR_GLOBAL` of type `INT` in your OpenPLC configuration/resource settings.

---

## ⚙️ Program Logic Breakdown

The PLC scan cycle executes four sequential stages:

1. **Automatic `Item_Sensor` Simulation:**
   * `Item_Timer` runs whenever `Conveyor_Motor` is `TRUE` and resets automatically once the elapsed time (`ET`) reaches `4s`.
   * Between `3s` and `4s` of the cycle, `Item_Sensor` is set to `TRUE` (simulating a 1-second item pass window); otherwise, it remains `FALSE`.
2. **Conveyor Motor Latching Logic:**
   * Evaluates `HMI_Stop` first (Stop-dominant safety priority). If `TRUE`, `Conveyor_Motor` and `HMI_Start` are immediately forced `FALSE`.
   * Otherwise, if `HMI_Start` is `TRUE`, `Conveyor_Motor` latches to `TRUE`.
3. **Item Counting Logic:**
   * `Sensor_Trigger` monitors `Item_Sensor` for a `FALSE -> TRUE` transition.
   * When a rising edge occurs (`Sensor_Trigger.Q`) while the motor is running, `Item_Count` increments by `1`.
4. **Auto-Reset Momentary HMI Buttons:**
   * Ensures `HMI_Start` is cleared to `FALSE` whenever the motor is stopped and `HMI_Stop` is inactive, preventing unintended restarts.

---

## 🚀 Getting Started with OpenPLC Runtime v4

1. **Create a New Project:**
   * Open the **OpenPLC Editor** (v4 compatible) and create a new project using **Structured Text (ST)** as the programming language.
2. **Configure Global Variables:**
   * Navigate to your **Resource** configuration and add `Item_Count` (`INT`) under `VAR_GLOBAL`.
3. **Import the Code:**
   * Copy the variable declarations and ST logic into your main program POU (`program0`).
4. **Compile & Upload:**
   * Build the project and upload the generated `.st` / binary program to your **OpenPLC Runtime v4** instance.
5. **Connect an HMI / Modbus Client:**
   * Map your HMI buttons and indicators to coils `%QX0.0` through `%QX0.3` (Modbus Coils `0`–`3`) to start, stop, and monitor the simulation.

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
