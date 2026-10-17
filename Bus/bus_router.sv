module bus_router(
    input wire clk,
    input wire rst_n,
    input wire addr_valid,
    input wire master_tag,
    input wire data_valid,
    input wire return_tag,
    output reg route_to_A,
    output reg route_to_B,
    output reg [1:0] active_transactions 
);

    // 1. Transaction Counter (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_transactions <= 2'd0; // Must have reset logic
        end else begin
            if (addr_valid && data_valid) begin
                active_transactions <= active_transactions; // Both happen: do nothing
            end else if (addr_valid && !data_valid) begin
                if (active_transactions < 2'd2)
                    active_transactions <= active_transactions + 1'b1; // Clamp at 2
            end else if (!addr_valid && data_valid) begin
                if (active_transactions > 2'd0)
                    active_transactions <= active_transactions - 1'b1; // Clamp at 0
            end
        end
    end

    // 2. Routing Logic (Combinational)
    always @* begin
        // Default values to prevent latches
        route_to_A = 1'b0;
        route_to_B = 1'b0;

        // Only route if data is actually valid
        if (data_valid) begin
            if (return_tag == 1'b0) 
                route_to_A = 1'b1;
            else if (return_tag == 1'b1) 
                route_to_B = 1'b1;
        end
    end

endmodule
