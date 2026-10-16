`timescale 1ns/1ps

module SmartCrossroadsController_tb;

    // 1. Declare signals
    logic clk;
    logic rst;
    logic [1:0] dens_N, dens_S, dens_E, dens_W;
    logic [3:0] green, yellow;

    // 2. Instantiate your design (DUT)
    crossroads_ctrl dut (
        .clk(clk),
        .rst(rst),
        .dens_N(dens_N),
        .dens_S(dens_S),
        .dens_E(dens_E),
        .dens_W(dens_W),
        .green(green),
        .yellow(yellow)
    );

    // 3. Generate a clock (toggles every 5 time units)
    always #5 clk = ~clk;

    // 4. Apply test stimulus
    initial begin
        // Print output whenever a signal changes
        $monitor("Time: %0t | N:%0d E:%0d S:%0d W:%0d | Green: %b | Yellow: %b", 
                 $time, dens_N, dens_E, dens_S, dens_W, green, yellow);

        // Start with everything at 0 and reset the system
        clk = 0;
        dens_N = 0; dens_E = 0; dens_S = 0; dens_W = 0;
        
        rst = 1;
        #15; 
        rst = 0; // Turn off reset

        // --- SCENARIO 1: All roads empty (Test basic N->E->S->W rotation) ---
        // Wait 100 time units. 
        #100;

        // --- SCENARIO 2: East is busiest (Test density rule) ---
        dens_N = 0; dens_E = 3; dens_S = 1; dens_W = 0;
        #150;

        // --- SCENARIO 3: Test Starvation ---
        dens_N = 1; dens_E = 3; dens_S = 1; dens_W = 1;
        #400;

        // End simulation
        $finish;
    end

endmodule
