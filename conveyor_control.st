PROGRAM Conveyor_Control
VAR
  HMI_Start : BOOL AT %QX0.0; (* start button )
  HMI_Stop : BOOL AT %QX0.1; ( stop button )
  Conveyor_Motor : BOOL AT %QX0.2;
  Item_Sensor : BOOL AT %QX0.3;
  Item_Timer : TON;
  Sensor_Trigger : R_TRIG;
END_VAR

VAR_EXTERNAL
  Item_Count : INT; ( counted items on belt *)
END_VAR

// 1. AUTOMATIC ITEM_SENSOR SIMULATION (Moved to top so the PLC sees it first)
Item_Timer(IN := Conveyor_Motor AND (Item_Timer.ET < T#4s), PT := T#4s);

IF Conveyor_Motor AND (Item_Timer.ET >= T#3s) THEN
  Item_Sensor := TRUE;
ELSE
  Item_Sensor := FALSE;
END_IF;

// 2. CONVEYOR MOTOR LATCHING LOGIC
IF HMI_Stop THEN
  Conveyor_Motor := FALSE;
  HMI_Start := FALSE;
ELSIF HMI_Start THEN
  Conveyor_Motor := TRUE;
END_IF;

// 3. ITEM COUNTING LOGIC (Rising Edge Detector)
Sensor_Trigger(CLK := Item_Sensor);

IF Conveyor_Motor AND Sensor_Trigger.Q THEN
Item_Count := Item_Count + 1;
END_IF;

// 4. AUTO-RESET MOMENTARY HMI BUTTONS
IF NOT Conveyor_Motor AND NOT HMI_Stop THEN
  HMI_Start := FALSE;
END_IF;

END_PROGRAM

CONFIGURATION Config0
RESOURCE Res0 ON PLC

VAR_GLOBAL
  Item_Count : INT := 0; (* global item counter *)
END_VAR

TASK task0(INTERVAL := T#20ms, PRIORITY := 0);
PROGRAM instance0 WITH task0 : Conveyor_Control;

END_RESOURCE
END_CONFIGURATION
