`timescale 1ns / 1ps
module tb_crossroads_simple;
    reg clk = 0, rst = 1;
    reg [1:0] dens_N = 0, dens_E = 0, dens_S = 0, dens_W = 0;
    wire [3:0] green, yellow;       // {W,E,S,N}
    integer errors = 0, seed = 2024, t, hold, j, d;
    integer gt [0:3], ph [0:3], wp [0:3], longest;
    reg [3:0] prev_green, last_green;
    reg saw_red;
    localparam BOUND = 5;           // max phases a direction may wait

    SmartCrossRoadsContoller dut (.clk(clk), .rst(rst),
        .dens_N(dens_N), .dens_S(dens_S), .dens_E(dens_E), .dens_W(dens_W),
        .green(green), .yellow(yellow));

    always #5 clk = ~clk;

    // ---- checkers and statistics, sampled every clock ----
    always @(negedge clk) if (!rst) begin
        if ((green & (green - 1)) != 0)
            begin $display("FAIL @%0t: more than one green (%b)", $time, green); errors = errors + 1; end
        if (green != 0 && yellow != 0)
            begin $display("FAIL @%0t: green and yellow together", $time); errors = errors + 1; end
        if (green == 0 && yellow == 0) saw_red = 1;
        if (green != 0) begin
            if (last_green != 0 && green != last_green && !saw_red)
                begin $display("FAIL @%0t: two greens with no SELECT tick", $time); errors = errors + 1; end
            last_green = green;
            saw_red = 0;
            d = (green == 4'b0001) ? 0 : (green == 4'b0100) ? 1 : (green == 4'b0010) ? 2 : 3;   // N,E,S,W
            gt[d] = gt[d] + 1;
            if (prev_green == 0) begin                 // a new green phase starts
                ph[d] = ph[d] + 1;
                if (wp[d] > longest) longest = wp[d];
                wp[d] = 0;
                for (j = 0; j < 4; j = j + 1)
                    if (j != d) begin
                        wp[j] = wp[j] + 1;
                        if (wp[j] > BOUND)
                            begin $display("FAIL @%0t: a direction waited more than %0d phases", $time, BOUND); errors = errors + 1; end
                    end
            end
        end
        prev_green = green;
    end

    // reset the controller and the counters, then set the densities for a scenario
    task start(input [1:0] n, input [1:0] e, input [1:0] s, input [1:0] w);
        begin
            rst = 1; @(negedge clk); rst = 0;
            for (j = 0; j < 4; j = j + 1) begin gt[j] = 0; ph[j] = 0; wp[j] = 0; end
            longest = 0; prev_green = 0; last_green = 0; saw_red = 0;
            dens_N = n; dens_E = e; dens_S = s; dens_W = w;
        end
    endtask

    task report(input [8*20-1:0] name);
        begin
            $display("%0s | green ticks N/E/S/W = %0d/%0d/%0d/%0d | phases = %0d/%0d/%0d/%0d | longest wait = %0d",
                     name, gt[0], gt[1], gt[2], gt[3], ph[0], ph[1], ph[2], ph[3], longest);
        end
    endtask

    initial begin

        // Scenario 1: uniform, all four at level 2
        start(2,2,2,2);
        repeat (44) @(negedge clk);
        report("1 uniform");

        // Scenario 2: one heavy direction, N = 3, the others = 1
        start(3,1,1,1);
        repeat (66) @(negedge clk);
        report("2 N heavy");

        // Scenario 3a: random densities, change every 1 to 3 ticks, 300 ticks
        start(0,0,0,0);
        t = 0;
        while (t < 300) begin
            dens_N = $random(seed); dens_E = $random(seed);
            dens_S = $random(seed); dens_W = $random(seed);
            hold = 1 + ({$random(seed)} % 3);
            repeat (hold) @(negedge clk);
            t = t + hold;
        end
        report("3a random");

        // Scenario 3b: scripted, busy direction switches from N to E halfway
        start(3,0,0,0);
        repeat (60) @(negedge clk);
        dens_N = 0; dens_E = 3;
        repeat (60) @(negedge clk);
        report("3b N to E");

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
