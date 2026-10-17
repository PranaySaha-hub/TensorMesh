`timescale 1ns/1ps

module bus_router_tb;

    reg clk;
    reg rst_n;
    reg addr_valid;
    reg master_tag;
    reg data_valid;
    reg return_tag;

    wire route_to_A;
    wire route_to_B;
    wire [1:0] active_transactions;

    // Instantiate DUT
    bus_router dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr_valid(addr_valid),
        .master_tag(master_tag),
        .data_valid(data_valid),
        .return_tag(return_tag),
        .route_to_A(route_to_A),
        .route_to_B(route_to_B),
        .active_transactions(active_transactions)
    );

    // 10ns clock (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Simple checker task
    task check(input [1:0] exp_count, input exp_A, input exp_B, input [127:0] tag);
        begin
            #1; 
            if (active_transactions !== exp_count || route_to_A !== exp_A || route_to_B !== exp_B) begin
                $display("[FAIL] %0s | count=%0d (exp %0d), route_A=%b, route_B=%b", 
                         tag, active_transactions, exp_count, route_to_A, route_to_B);
                $fatal(1);
            end else begin
                $display("[PASS] %0s", tag);
            end
            #9; 
        end
    endtask

    initial begin
        
        clk = 0;
        rst_n = 0;
        addr_valid = 0;
        master_tag = 0;
        data_valid = 0;
        return_tag = 0;

        // Release reset aligned to negedge (at 15ns)
        #15 rst_n = 1;
        check(2'd0, 1'b0, 1'b0, "Init State");

        
        addr_valid = 1; master_tag = 0;
        check(2'd1, 1'b0, 1'b0, "TC1: Req sent (count -> 1)");
        // request followed by its response
        addr_valid = 0;
        data_valid = 1; return_tag = 0;
        check(2'd0, 1'b0, 1'b0, "TC1: Resp received (count -> 0)");
        data_valid = 0;

        // 2. Two overlapping requests, out-of-order responses
        
        addr_valid = 1; master_tag = 0; #10;
        master_tag = 1;
        check(2'd2, 1'b0, 1'b0, "TC2: Two requests queued (count -> 2)");
        addr_valid = 0;

        // Resp 2 first (Tag 1 -> route B)
        data_valid = 1; return_tag = 1;
        check(2'd1, 1'b1, 1'b0, "TC2: Resp 2 retired (count -> 1)");

        // Resp 1 second (Tag 0 -> route A)
        return_tag = 0;
        check(2'd0, 1'b1, 1'b0, "TC2: Resp 1 retired (count -> 0)");
        data_valid = 0;

        // 3. Simultaneous addr_valid and data_valid
        
        addr_valid = 1; master_tag = 0;
        check(2'd1, 1'b0, 1'b0, "TC3: Setup count to 1");

        // Fire both at the same time: counter holds steady
        data_valid = 1; return_tag = 0;
        check(2'd1, 1'b1, 1'b0, "TC3: Simultaneous req & resp (count held at 1)");
        addr_valid = 0;

        // Flush remaining transaction
        check(2'd0, 1'b0, 1'b0, "TC3: Cleared to 0");
        data_valid = 0;
      
       // 4. Response at count 0 (Underflow check)
        data_valid = 1; return_tag = 0;
        check(2'd0, 1'b1, 1'b0, "TC4: Clamped at 0 on underflow");
        data_valid = 0;

        // 5. Request at count 2 (Overflow check)
        addr_valid = 1; master_tag = 0; #20; // 2 requests push count to 2
        #10;                                  // 3rd request attempted
        check(2'd2, 1'b0, 1'b0, "TC5: Clamped at 2 on overflow");
        addr_valid = 0;

        // 6. Asynchronous reset during active transactions
        #3 rst_n = 0; // Drop reset mid-cycle
        #2;
        if (active_transactions !== 2'd0) $fatal(1, "[FAIL] Async reset failed!");
        $display("[PASS] TC6: Asynchronous reset immediately cleared counter");

        #10 rst_n = 1;
        check(2'd0, 1'b0, 1'b0, "TC6: Restored to idle");

        $display("\nAll 6 tests passed!");
        $finish;
    end

endmodule
