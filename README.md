# OpenPLC v4 Conveyor Belt Control & Item Counter

A Structured Text (ST) IEC 61131-3 PLC program designed for **OpenPLC Runtime v4**. This project implements a latched conveyor motor control system with HMI pushbuttons, a rising-edge item counter, and a built-in timer-based sensor simulator for standalone testing without physical hardware.

---

## 📋 Overview

This program simulates and controls an automated industrial conveyor belt. When started via an HMI signal, the conveyor motor latches on and runs continuously until a stop signal is received. While running, an internal timer simulates items passing an optical/proximity sensor every 4 seconds, incrementing a global item counter on each rising edge.

### Key Features
- **Start/Stop Latching Logic:** Stop-dominant motor control circuit ensuring safe shutdowns.
- **Built-in Sensor Simulation:** Uses an on-delay timer (`TON`) to automatically pulse the `Item_Sensor` every 4 seconds while the belt is active, ideal for HMI and SCADA testing.
- **Rising-Edge Detection:** Utilizes an `R_TRIG` function block to ensure each item is counted strictly once per pass.
- **HMI Momentary Button Handling:** Automatically resets simulated momentary HMI start states when the system stops.

---

## 🔌 I/O & Variable Mapping

### Local Variables (`VAR`)

| Variable | Data Type | IEC Address | Modbus Coil | Description |
| :--- | :--- | :--- | :--- | :--- |
| `HMI_Start` | `BOOL` | `%QX0.0` | Coil `0` (`00001`) | HMI Start pushbutton trigger |
| `HMI_Stop` | `BOOL` | `%QX0.1` | Coil `1` (`00002`) | HMI Stop pushbutton trigger (Stop-dominant) |
| `Conveyor_Motor` | `BOOL` | `%QX0.2` | Coil `2` (`00003`) | Output coil controlling the conveyor belt motor |
| `Item_Sensor` | `BOOL` | `%QX0.3` | Coil `3` (`00004`) | Simulated sensor output (`TRUE` during item detection) |
| `Item_Timer` | `TON` | *Internal* | — | 4-second cycle timer used for item sensor simulation |
| `Sensor_Trigger` | `R_TRIG` | *Internal* | — | Rising-edge detector for accurate item counting |

### External / Global Variables (`VAR_EXTERNAL`)

| Variable | Data Type | Scope | Description |
| :--- | :--- | :--- | :--- |
| `Item_Count` | `INT` | Global | Accumulator storing the total number of items counted |

> **Note:** Because `Item_Count` is declared as `VAR_EXTERNAL`, you must also define `Item_Count` as a `VAR_GLOBAL` of type `INT` in your OpenPLC configuration/resource settings. *(Tip: If you also want to read `Item_Count` over Modbus TCP, bind it to an output word such as `%QW0` so it maps to Modbus Holding Register `0` / `40001`).*

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

## 🌐 Setting Up the Modbus TCP Server in OpenPLC Runtime v4

In OpenPLC Runtime v4 (via OpenPLC Editor / Autonomy Edge), Modbus TCP runs as a built-in server plugin configured directly in your project tree (exporting `modbus_slave.json` upon deployment).

### 1. Create the Modbus TCP Server
1. In the **Project Tree** (left sidebar), click the **`+`** button at the top.
2. Select **Server** from the menu.
3. Enter a server name (e.g., `modbus_conveyor`, at least 3 characters).
4. Set **Protocol** to **`Modbus/TCP`** and click **Create**.
5. Click the newly created server under **Servers** in the project tree to open its configuration editor.

### 2. Configure Network & Server Settings
In the **Server Configuration** panel:
- **Enable Server:** Toggle **ON** (*"Server will start when PLC runs"*).
- **Network Interface:** Select **`All Interfaces (0.0.0.0)`** to allow external HMI/SCADA connections over the network (or `127.0.0.1` for local-only testing).
- **Port:** Set to **`502`** (standard Modbus TCP port). 
  > *Linux/macOS Note:* Ports below `1024` require root/elevated privileges. If the runtime cannot bind to port `502`, change this to **`1502`**.

### 3. Map I/O Buffers
Expand the **Buffer Mapping** accordion and configure **Coils (FC 1 / 5 / 15)** so your `%QX` bits are exposed:
- **`%QX` count:** Set to at least **`8`** (exposes `%QX0.0` through `%QX0.7` as Modbus Coils `0`–`7`).
- **`%MX` count:** Leave at `0` (not used in this program).
- *(Optional)* If exposing `Item_Count` at `%QW0`, expand **Holding Registers (FC 3 / 6 / 16)** and ensure **`%QW` count** is at least **`1`** (maps `%QW0` to Holding Register `0`).

Open the **Address Mapping Reference** accordion at the bottom of the server editor to verify the generated mapping:
- `Modbus Coil 0` $\Leftrightarrow$ `%QX0.0` (`HMI_Start`)
- `Modbus Coil 1` $\Leftrightarrow$ `%QX0.1` (`HMI_Stop`)
- `Modbus Coil 2` $\Leftrightarrow$ `%QX0.2` (`Conveyor_Motor`)
- `Modbus Coil 3` $\Leftrightarrow$ `%QX0.3` (`Item_Sensor`)

---

## 🚀 Getting Started & Testing

1. **Create a New Project:**
   * Open **OpenPLC Editor (v4)** and create a new project using **Structured Text (ST)**.
2. **Import the Code & Global Variables:**
   * Paste the `conveyor_control.st` code into your main program POU and ensure `Item_Count` (`INT`) is defined under `VAR_GLOBAL` in your Resource configuration.
3. **Configure Modbus TCP Server:**
   * Follow the [Modbus TCP Server setup steps](#-setting-up-the-modbus-tcp-server-in-openplc-runtime-v4) above.
4. **Build & Upload to Runtime v4:**
   * Connect to your **OpenPLC Runtime v4** target (or start the built-in Simulator), click **Build & Upload**, and press **Play** to start the PLC scan cycle and Modbus TCP server.
5. **Test with a Modbus Client (`mbpoll` or HMI):**
   * Connect your HMI/SCADA to `<PLC_IP>:502` (Unit ID `1`) or test from the terminal using `mbpoll`:

   ```bash
   # Trigger HMI_Start (Write 1 to Coil 0 / %QX0.0)
   mbpoll -t 0 -r 0 -1 <PLC_IP> 1

   # Read Coils 0–3 (%QX0.0 to %QX0.3) to monitor Motor and Sensor pulses
   mbpoll -t 0 -r 0 -c 4 <PLC_IP>

   # Trigger HMI_Stop (Write 1 to Coil 1 / %QX0.1)
   mbpoll -t 0 -r 1 -1 <PLC_IP> 1
   ```
   *(Note: Remember to write `0` back to Coil `1` (`HMI_Stop`) to release the simulated momentary stop button before starting the conveyor again.)*

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
