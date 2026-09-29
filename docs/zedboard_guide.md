# ZedBoard guide: from HLS code to a running FPGA

Goal: run the AFDM modulator (`afdm_mod_top`) on the ZedBoard and check that its
output matches MATLAB bit for bit.

- **Part 1 - Vitis HLS**: turn the C++ into hardware (an "IP block") and read its cost report.
- **Part 2 - Vivado**: connect the IP to the Zynq ARM processor, generate the bitstream, export a `.xsa`.
- **Part 3 - Vitis (embedded)**: a small C program on the ARM feeds data to the IP and prints PASS/FAIL.

Tools: Vitis and Vivado 2025.2 in `D:\2025.2`. Board: ZedBoard (chip XC7Z020-CLG484-1).
Project folder: `C:\Users\hp\HW-AFDM-OTFS`. Use forward slashes (`C:/...`) wherever a path is typed into a tool.

Files used (already in the repo):

| File | What it is |
|---|---|
| `hls/src/board_top.cpp` | the IP's top function `afdm_mod_top` with AXI interfaces |
| `hls/src/blocks.cpp`, `fft.h`, `types.h` | the modulator itself |
| `hls/generated/R16_LEOKa/rom_tables.h` | chirp and twiddle tables (made by MATLAB) |
| `hls/tb/tb_board.cpp` | C testbench, compares with MATLAB |
| `hls/generated/W12_R16_LEOKa/` | MATLAB test vectors for the testbench |
| `hls/board/main.c`, `test_vectors.h` | the ARM test program (Part 3) |

> Before Part 2, tell Claude: the MATLAB jobs will be paused so Vivado has enough memory.

---

## Part 1 - Vitis HLS (about 20 minutes)

1. **Start Vitis.** Start menu -> "Vitis 2025.2", or double-click `D:\2025.2\Vitis\bin\vitis.bat`.
2. **Pick a workspace.** When asked (or File -> Set Workspace), create and choose
   `C:\Users\hp\HW-AFDM-OTFS\hls\ws`. A workspace is just a folder where Vitis keeps its projects.
3. **New HLS component.** File -> New Component -> **HLS**.
   - Component name: `afdm_mod_top`. Location: the workspace. Next.
   - Configuration file: **Empty File** (keep the name `hls_config.cfg`). Next.
4. **Source files.** Click **Add Files** and add
   `hls/src/board_top.cpp` and `hls/src/blocks.cpp`.
   - **CFLAGS** (the box next to the files - it tells the compiler the word lengths and where the headers are):
     `-DWD=12 -DWR=16 -IC:/Users/hp/HW-AFDM-OTFS/hls/src -IC:/Users/hp/HW-AFDM-OTFS/hls/generated/R16_LEOKa`
   - **Top function**: click Browse and pick `afdm_mod_top`.
   - **Test bench files**: Add `hls/tb/tb_board.cpp`, with the **same CFLAGS**. Next.
5. **Hardware.** Choose **Part** and search `xc7z020clg484-1` (or the **Board** tab -> ZedBoard). Next.
6. **Settings.** Clock: `10ns` (100 MHz). Flow target: **Vivado IP Flow Target**.
   Package output format: **Vivado IP**. Next -> Finish.
7. **C simulation** (checks the C++ before any hardware is built). In the **Flow** panel
   (bottom-left) under C SIMULATION click the gear icon (**Settings**) and set
   **Input arguments** (csim argv) to
   `C:/Users/hp/HW-AFDM-OTFS/hls/generated/W12_R16_LEOKa`.
   Then click **Run** under C SIMULATION. Expected in the console:
   `afdm_mod_top: 20 frames, 5120 samples, 0 mismatches` and `PASS: bit-exact with MATLAB`.
8. **C synthesis** (C++ -> hardware). Click **Run** under C SYNTHESIS (1-3 minutes).
   Open **Reports -> Synthesis**. Write down:
   - **Timing**: estimated clock period (must be below 10 ns).
   - **Latency**: cycles for one frame (at 100 MHz, 1 cycle = 10 ns).
   - **Utilization**: BRAM_18K, DSP, FF, LUT (and the % of the chip).
   - **Loops** section: the `butterflies` loops should show II = 2.
9. **C/RTL co-simulation** (optional, 5-10 minutes): **Run** under C/RTL COSIMULATION.
   It runs the same testbench on the generated hardware description. Expected: **Pass**.
10. **Package.** **Run** under PACKAGE. This creates the IP that Vivado will use, in
    `hls/ws/afdm_mod_top/afdm_mod_top/hls/impl/ip` (the exact subfolder is shown in the console).

**Checkpoint:** C simulation PASS, a synthesis report, and a packaged IP.

---

## Part 2 - Vivado: block design and bitstream (about 40 minutes, mostly waiting)

1. **Start Vivado.** Start menu -> "Vivado 2025.2", or `D:\2025.2\Vivado\bin\vivado.bat`.
2. **Create the project.** Quick Start -> **Create Project** -> Next.
   - Name `afdm_zed`, location `C:/Users/hp/HW-AFDM-OTFS/vivado`, keep "Create project subdirectory". Next.
   - **RTL Project**, tick **Do not specify sources at this time**. Next.
   - **Default Part**: open the **Boards** tab, search `ZedBoard`. If it is not listed, click
     **Refresh** and then the download/install icon next to ZedBoard. Select it. Next -> Finish.
3. **Add the HLS IP.** Flow Navigator (left) -> **Settings** -> Project Settings -> **IP** ->
   **Repository** -> **+** -> choose the `ip` folder from Part 1 step 10 -> Select.
   (If Part 1 was run in batch with `hls/scripts/run_board_hls.tcl`, the folder is
   `C:/Users/hp/HW-AFDM-OTFS/hls/proj/afdm_mod_top/sol/impl/ip`.) Vivado should
   report 1 IP found. OK.
4. **Block design.** Flow Navigator -> IP INTEGRATOR -> **Create Block Design** (name `design_1`) -> OK.
5. **Add the ARM processor.** In the Diagram, click **+** (Add IP), type `ZYNQ7`, double-click
   **ZYNQ7 Processing System**. Click the green banner **Run Block Automation** -> keep
   *Apply Board Preset* ticked -> OK. (This sets up DDR memory, clocks and the UART for the ZedBoard.)
6. **Let the IP reach DDR memory.** Double-click the ZYNQ7 block -> **PS-PL Configuration** ->
   **HP Slave AXI Interface** -> tick **S AXI HP0 interface** -> OK.
7. **Add your IP.** **+** -> type `afdm` -> double-click **Afdm_mod_top**.
8. **Connect everything.** Click the banner **Run Connection Automation** -> tick **All Automation** -> OK.
   Vivado adds the AXI interconnect and reset blocks: the ARM controls the IP through
   `s_axi_control`, and the IP reads/writes DDR through `m_axi_gmem` -> `S_AXI_HP0`.
9. **Check.** Click **Validate Design** (the check-mark icon, or F6). Expected: *Validation successful*.
   (Critical warnings about "DDR ... negative DQS skew" are normal on the ZedBoard preset.)
10. **HDL wrapper.** In the **Sources** pane right-click `design_1` -> **Create HDL Wrapper** ->
    *Let Vivado manage wrapper* -> OK.
11. **Bitstream.** Flow Navigator -> PROGRAM AND DEBUG -> **Generate Bitstream** -> Yes to run
    synthesis and implementation -> OK. Takes 10-25 minutes; progress is at the top right.
12. **Read the real cost** (these numbers go into the paper): when it finishes choose
    **Open Implemented Design**, then in Flow Navigator:
    - **Report Utilization** - LUT, FF, BRAM, DSP of `afdm_mod_top_0` (expand the hierarchy).
    - **Report Timing Summary** - **WNS** must be >= 0 (timing met at 100 MHz).
    - **Report Power** - total and dynamic power (vectorless estimate for now).
13. **Export the hardware.** File -> Export -> **Export Hardware** -> Next -> **Include bitstream** ->
    Next -> name `afdm_zed`, folder `C:/Users/hp/HW-AFDM-OTFS/vivado` -> Finish.
    This writes `afdm_zed.xsa`.

**Checkpoint:** bitstream generated, WNS >= 0, `afdm_zed.xsa` exported.

---

## Part 3 - Run it on the ZedBoard (about 30 minutes)

### Board setup (power OFF while changing jumpers)

1. **Boot mode = JTAG:** set the five boot jumpers **JP7 - JP11** all to the **GND** side
   (the board then waits for the PC to program it).
2. **Cables:** micro-USB into **J17 (PROG / JTAG)** and micro-USB into **J14 (UART)**; 12 V power into **J20**.
3. **Power on** with switch **SW8**. The green POWER LED lights.
4. **Drivers:** Windows Device Manager should show a *USB Serial Port (COMx)* under Ports (note **x**)
   and the Digilent JTAG device. If the JTAG device is missing, close Vivado/Vitis and run
   `D:\2025.2\data\xicom\cable_drivers\nt64\install_drivers_wrapper.bat` as Administrator.

### Software in Vitis

5. Start Vitis and choose a new workspace `C:\Users\hp\HW-AFDM-OTFS\vitis_sw`.
6. **Platform** (describes your hardware to the software): File -> New Component -> **Platform** ->
   name `zed_platform` -> Next -> **Hardware Design**: browse to `vivado/afdm_zed.xsa` -> Next ->
   Operating system **standalone**, processor **ps7_cortexa9_0** -> Next -> Finish.
   In the Flow panel click **Build** for the platform.
7. **Application:** File -> New Component -> **Application** -> name `afdm_test` -> select
   `zed_platform` -> domain **standalone_ps7_cortexa9_0** -> Finish.
8. **Add the code:** in the Explorer, right-click the application's `src` folder -> **Import** -> Files ->
   `hls/board/main.c` and `hls/board/test_vectors.h`.
   (If the template created its own `main.c`/`helloworld.c`, delete it.)
9. **Build** the application (Flow panel -> Build). If `XPAR_XAFDM_MOD_TOP_0_BASEADDR` is unknown,
   open `xparameters.h` in the platform (search for `AFDM`) and use the base-address name listed there.
10. **Serial terminal:** in Vitis open **Vitis -> Serial Monitor** (or PuTTY / Tera Term) on **COMx**,
    115200 baud, 8 data bits, no parity, 1 stop bit.
11. **Run:** Flow panel -> **Run** for `afdm_test`. Vitis programs the bitstream, initialises the ARM
    and DDR, and starts the program. Expected on the terminal:
    ```
    AFDM modulator on ZedBoard
    0 / 256 samples differ -> PASS (bit-exact with MATLAB)
    ```

**Done:** the modulator runs on the FPGA and matches MATLAB exactly.

---

## If something goes wrong

| Symptom | Fix |
|---|---|
| C simulation: `cannot open .../afdm_mod.txt` | the csim argument path (Part 1 step 7) is wrong - use forward slashes |
| C simulation: `rom_tables.h` not found | CFLAGS are missing the `-I.../generated/R16_LEOKa` part |
| Vivado: ZedBoard not in the Boards list | Boards tab -> Refresh -> install ZedBoard from the board store |
| Vivado: IP not found in the catalog | the repository in Part 2 step 3 must point to the `ip` folder that contains `component.xml` |
| Timing report WNS < 0 | tell Claude - the clock or the design needs adjusting |
| Vitis Run: "no targets found" | JTAG cable in J17, board powered, jumpers on GND, cable drivers installed |
| Terminal shows nothing | wrong COM port, or baud rate not 115200; press the PS-RST button and Run again |
| FAIL with differing samples | send Claude the printed lines |
