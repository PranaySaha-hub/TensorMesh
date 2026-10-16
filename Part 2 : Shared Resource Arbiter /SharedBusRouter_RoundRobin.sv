`timescale 1ns/1ps
module SharedBusRouter_RoundRobin(
    input clk,
    input rst,
    input req_A,
    input req_B,
    input reg [7:0] data_A,
    input reg [7:0] data_B,
    output reg grant_A,
    output reg grant_B,
    output reg [7:0] out_data,
    output reg out_valid
) ;
reg memory; // 0 for A , 1 for B
always_ff @(posedge clk) begin 
    if(rst)
    begin 
        grant_A <= 0;
        grant_B <= 0;
        out_data <= 8'b0;
        out_valid <= 0;
        memory <= 0;
    end
    else
    if(req_A && req_B) begin
        if(memory == 0) begin
            grant_A <= 0;
            grant_B <= 1;
            out_data <= data_B;
            out_valid <= 1;
            memory <= 1;
        end
        else begin
            grant_A <= 1;
            grant_B <= 0;
            out_data <= data_A;
            out_valid <= 1;
            memory <= 0;    
        end
    end
    else if(req_B) begin
        grant_A <= 0;
        grant_B <= 1;
        out_data <= data_B;
        out_valid <= 1;
        memory <= 1;
    end
    else if(req_A) begin
        grant_A <= 1;
        grant_B <= 0;
        out_data <= data_A;
        out_valid <= 1;
        memory <= 0;
    end
    else begin                  // neither requests: clear everything
            grant_A <= 0;
            grant_B <= 0;
            out_data <= 8'b0;
            out_valid <= 0;
        end
    end

endmodule
