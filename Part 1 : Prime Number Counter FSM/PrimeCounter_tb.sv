`timescale 1ns / 1ps
module PrimeCounter_tb;
    typedef enum logic [1:0] {IDLE = 2'd0, ACTIVE = 2'd1, DONE = 2'd2} state_t;

    reg clk, rst, start, stop;
    wire [1:0] state;
    wire [3:0] count;
    integer errors = 0;

    primeCounter uut (.clk(clk), .rst(rst), .start(start), .stop(stop),
                      .state(state), .count(count));

    initial clk = 0;
    always #5 clk = ~clk;

    // set inputs, wait one clock, then compare with expected state and count
    task step(input s, input p, input state_t exp_state, input [3:0] exp_count);
        state_t cur;
        begin
            start = s; stop = p;
            @(negedge clk);
            cur = state_t'(state);
            $display("t=%0t start=%b stop=%b | state=%s count=%0d",
                     $time, s, p, cur.name(), count);
            if (state !== exp_state || count !== exp_count) begin
                $display("  FAIL: expected state=%s count=%0d", exp_state.name(), exp_count);
                errors = errors + 1;
            end
        end
    endtask

    // Q1 requirement: count is always a prime from the list while ACTIVE
    always @(negedge clk)
        if (!rst && state == ACTIVE &&
            !(count==2 || count==3 || count==5 || count==7 || count==11 || count==13)) begin
            $display("FAIL: non-prime count %0d in ACTIVE", count);
            errors = errors + 1;
        end

    initial begin
        // 1. reset: IDLE and count = 0
        rst = 1; start = 0; stop = 0;
        @(negedge clk);
        step(0,0, IDLE, 0);
        rst = 0;

        // 2. IDLE holds, and stop is ignored in IDLE
        step(0,0, IDLE, 0);
        step(0,1, IDLE, 0);

        // 3. start -> ACTIVE, count = 2
        step(1,0, ACTIVE, 2);

        // 4. full sequence with wrap 13 -> 2
        step(0,0, ACTIVE, 3);
        step(0,0, ACTIVE, 5);
        step(0,0, ACTIVE, 7);
        step(0,0, ACTIVE, 11);
        step(0,0, ACTIVE, 13);
        step(0,0, ACTIVE, 2);
        step(0,0, ACTIVE, 3);

        // 5. stop -> DONE (one cycle) -> IDLE, count held
        step(0,1, DONE, 3);
        step(0,0, IDLE, 3);

        // 6. hold in IDLE
        step(0,0, IDLE, 3);
        step(0,0, IDLE, 3);

        // 7. restart reloads 2
        step(1,0, ACTIVE, 2);
        step(0,0, ACTIVE, 3);

        // 8. start and stop together in ACTIVE: stop wins
        step(1,1, DONE, 3);
        step(0,0, IDLE, 3);

        // 9. reset while ACTIVE
        step(1,0, ACTIVE, 2);
        step(0,0, ACTIVE, 3);
        rst = 1;
        step(0,0, IDLE, 0);
        rst = 0;
        step(0,0, IDLE, 0);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
