# AXI-Lite-Slave-
A complete implementation of the AXI4-Lite protocol from the slave perspective, supporting both read and write channels.
This design follows the official AMBA AXI4-Lite protocol specification and includes complete FSM-based control logic, handshake signaling, and waveform validation using Icarus Verilog + GTKWave.

🔍 What I Built:

✅ AXI-Lite Write Channel (AW, W, B) with proper 3-phase handshake

✅ AXI-Lite Read Channel (AR, R) fully handshake compliant

✅ Separate FSMs for write and read paths

✅ Registered address + data capturing logic

✅ Error-free simulation with clean timing & protocol behavior

✅ Waveforms generated & analyzed via GTKWave

🧠 Key Learning Highlights:

Difference between AXI full vs AXI-Lite

How VALID/READY handshake guarantees timing decoupling

Why write response (BRESP/BVALID) is essential even in Lite mode

Separation of Address and Data phases improves bus efficiency

How FSM design simplifies AXI protocol implementation

🛠️ Tools & Tech Stack:

Verilog HDL

Icarus Verilog (Simulation)

GTKWave (Waveform Debug)


