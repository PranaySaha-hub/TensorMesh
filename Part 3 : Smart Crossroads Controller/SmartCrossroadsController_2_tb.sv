`timescale 1ns/1ps

module tb_crossroads_ctrl;

    logic clk;
    logic rst;
    logic [1:0] dens_N, dens_S, dens_E, dens_W;
    logic [3:0] green;
    logic [3:0] yellow;

    // Instantiate DUT
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

    // 10ns clock period (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Output index mapping: N=0, S=1, E=2, W=3
    int green_ticks[4];

    task clear_stats();
        green_ticks[0] = 0;
        green_ticks[1] = 0;
        green_ticks[2] = 0;
        green_ticks[3] = 0;
    endtask

    // Sample outputs every clock cycle on posedge
    always @(posedge clk) begin
        if (!rst) begin
            if (green[0]) green_ticks[0]++; // N
            if (green[1]) green_ticks[1]++; // S
            if (green[2]) green_ticks[2]++; // E
            if (green[3]) green_ticks[3]++; // W
        end
    end

    // Seed for pseudo-random number generator
    int unsigned seed = 32'hDEAD_BEEF;

    // Fast 32-bit PRNG function (Xorshift32)
    function automatic int get_random(input int min_val, input int max_val);
        seed = seed ^ (seed << 13);
        seed = seed ^ (seed >> 17);
        seed = seed ^ (seed << 5);
        return min_val + (seed % (max_val - min_val + 1));
    endfunction

    int elapsed;
    int hold_ticks;

    initial begin
        clk = 0;
        rst = 1;
        dens_N = 0;
        dens_E = 0;
        dens_S = 0;
        dens_W = 0;
        clear_stats();
        #15 rst = 0;
        $display("Starting Crossroads Controller Testbench");
        // Scenario 1: Uniform Traffic (all four at level 2)
        // Run for 160 ticks (#1600)
        $display("\n--- SCENARIO 1: Uniform Traffic (All Level 2) ---");
        clear_stats();
        dens_N = 2'd2;
        dens_E = 2'd2;
        dens_S = 2'd2;
        dens_W = 2'd2;#1600; // 160 clock cycles

        $display("Green Ticks -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[0] == green_ticks[1] &&
            green_ticks[1] == green_ticks[2] &&
            green_ticks[2] == green_ticks[3] &&
            green_ticks[0] > 0) begin
            $display("[PASS] Scenario 1: Green times are equal across all directions.");
        end else begin
            $display("[FAIL] Scenario 1: Green times are not uniform.");
        end
        // Scenario 2: One Heavy Direction (N=3, others=1)
        // Run for 200 ticks (#2000)
        $display("\n--- SCENARIO 2: One Heavy Direction (N=3, E=1, S=1, W=1) ---");
        clear_stats();
        dens_N = 2'd3;
        dens_E = 2'd1;
        dens_S = 2'd1;
        dens_W = 2'd1;#2000; // 200 clock cycles

        $display("Green Ticks -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[0] > green_ticks[1] &&
            green_ticks[0] > green_ticks[2] &&
            green_ticks[0] > green_ticks[3] &&
            green_ticks[1] > 0 && green_ticks[2] > 0 && green_ticks[3] > 0) begin
            $display("[PASS] Scenario 2: N dominant without starving E, S, W.");
        end else begin
            $display("[FAIL] Scenario 2: Starvation occurred or N was not dominant.");
        end

        
        // Scenario 3: Rapidly Changing Traffic & Scripted Switch
        // Part A: 350 ticks with random density changes every 1 to 3 ticks
        // Part B: Scripted case where busy direction switches N -> E
        
        $display("\n--- SCENARIO 3: Rapidly Changing Traffic & Scripted Switch ---");
        clear_stats();

        // Part A: Seeded random traffic over 350 ticks
        elapsed = 0;
        while (elapsed < 350) begin
            dens_N = get_random(0, 3);
            dens_E = get_random(0, 3);
            dens_S = get_random(0, 3);
            dens_W = get_random(0, 3);

            hold_ticks = get_random(1, 3);
            #(hold_ticks * 10); // Hold for 1, 2, or 3 clock periods
            elapsed += hold_ticks;
        end

        $display("Completed %0d ticks of pseudo-random traffic.", elapsed);
        $display("Interim Green Ticks -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        // Part B: Scripted switch from N heavy to E heavy
        $display("Starting Scripted Transition: Busy N -> Busy E");

        // Sub-phase 1: N is busy for 100 ticks (#1000)
        clear_stats();
        dens_N = 2'd3; dens_E = 2'd0; dens_S = 2'd0; dens_W = 2'd0;#1000;
        $display("Phase 1 (N heavy) -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[0] <= green_ticks[2])
            $display("[FAIL] Scenario 3: N should have had majority green in Phase 1.");

        // Sub-phase 2: Switch busy direction to E for 100 ticks (#1000)
        clear_stats();
        dens_N = 2'd0; dens_E = 2'd3; dens_S = 2'd0; dens_W = 2'd0;#1000;
        $display("Phase 2 (E heavy) -> N: %0d, E: %0d, S: %0d, W: %0d", 
                 green_ticks[0], green_ticks[2], green_ticks[1], green_ticks[3]);

        if (green_ticks[2] > green_ticks[0]) begin
            $display("[PASS] Scenario 3: Priority switched to E successfully.");
        end else begin
            $display("[FAIL] Scenario 3: E failed to take priority in Phase 2.");
        end
        $display("All Scenarios Finished!");
        $finish;
    end

endmodule