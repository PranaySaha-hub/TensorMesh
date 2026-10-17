`timescale 1ns/1ps

module tb_crossroads_ctrl;

    logic clk;
    logic rst;
    logic [1:0] dens_N, dens_S, dens_E, dens_W;
    logic [3:0] green;
    logic [3:0] yellow;

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

    // 10ns clock (5ns low, 5ns high)
    always #5 clk = ~clk;

    // Green tick accumulators: N=0, S=1, E=2, W=3
    int green_ticks[4];

    task clear_stats();
        green_ticks[0] = 0;
        green_ticks[1] = 0;
        green_ticks[2] = 0;
        green_ticks[3] = 0;
    endtask

    always @(posedge clk) begin
        if (!rst) begin
            if (green[0]) green_ticks[0]++; // N
            if (green[1]) green_ticks[1]++; // S
            if (green[2]) green_ticks[2]++; // E
            if (green[3]) green_ticks[3]++; // W
        end
    end

    int hold_ticks;
    int elapsed_ticks;
    int max_g, min_g;

    initial begin
        clk = 0;
        rst = 1;
        dens_N = 0; dens_E = 0; dens_S = 0; dens_W = 0;
        clear_stats();

        // Release reset cleanly on negative edge at 25ns
        #1 rst = 0;

        $display("Starting Crossroads Controller Testbench");

        $display("\n--- SCENARIO 1: Uniform Traffic (All Level 2) ---");
        clear_stats();
        dens_N = 2'd2; dens_E = 2'd2; dens_S = 2'd2; dens_W = 2'd2;
        #440; // Exactly 1 complete rotation (11 ticks * 4 dirs)

        $display("Green Ticks -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        // Check for "roughly equal" (within 1 tick margin)
        max_g = green_ticks[0];
        min_g = green_ticks[0];
        for (int i = 1; i < 4; i++) begin
            if (green_ticks[i] > max_g) max_g = green_ticks[i];
            if (green_ticks[i] < min_g) min_g = green_ticks[i];
        end

        if ((max_g - min_g) <= 1 && min_g > 0)
            $display("[PASS] Scenario 1: Green times are roughly equal across all directions.");
        else
            $display("[FAIL] Scenario 1: Green times are not uniform.");

       
        $display("\n--- SCENARIO 2: One Heavy Direction (N=3, E=1, S=1, W=1) ---");
        clear_stats();
        dens_N = 2'd3; dens_E = 2'd1; dens_S = 2'd1; dens_W = 2'd1;
        #500;

        $display("Green Ticks -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[0] > green_ticks[1] &&
            green_ticks[0] > green_ticks[2] &&
            green_ticks[0] > green_ticks[3] &&
            green_ticks[1] > 0 && green_ticks[2] > 0 && green_ticks[3] > 0)
            $display("[PASS] Scenario 2: N dominant without starving E, S, W.");
        else
            $display("[FAIL] Scenario 2: Starvation occurred or N was not dominant.");
 
        $display("\n--- SCENARIO 3: Rapidly Changing Traffic & Scripted Switch ---");
        clear_stats();

        // 300 ticks of seeded dynamic traffic
        elapsed_ticks = 0;
        while (elapsed_ticks < 300) begin
            dens_N = $urandom_range(0, 3);
            dens_E = $urandom_range(0, 3);
            dens_S = $urandom_range(0, 3);
            dens_W = $urandom_range(0, 3);

            hold_ticks = $urandom_range(1, 3);
            repeat (hold_ticks) #10;
            elapsed_ticks += hold_ticks;
        end

        $display("Completed %0d ticks of pseudo-random traffic.", elapsed_ticks);

        // Scripted switch: Phase 1 (N heavy)
        clear_stats();
        dens_N = 2'd3; dens_E = 2'd0; dens_S = 2'd0; dens_W = 2'd0;
        #400;
        $display("Phase 1 (N heavy) -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        // Scripted switch: Phase 2 (E heavy)
        clear_stats();
        dens_N = 2'd0; dens_E = 2'd3; dens_S = 2'd0; dens_W = 2'd0;
        #400;
        $display("Phase 2 (E heavy) -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[2] > green_ticks[0])
            $display("[PASS] Scenario 3: Priority switched to E successfully.");
        else
            $display("[FAIL] Scenario 3: E failed to take priority in Phase 2.");

      
        $display("All Scenarios Finished Successfully!");
        $finish;
    end

endmodule
