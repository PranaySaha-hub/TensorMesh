`timescale 1ns / 1ps

module primeCounter (
    input clk,
    input rst,
    input start,
    input stop,
    output [1:0] state,
    output reg [3:0] count
);

    
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        ACTIVE = 2'b01,
        DONE   = 2'b10
    } state_t;

    state_t current_state, next_state;
    logic [3:0] next_count;

    // Drive output port
    assign state = current_state;

    // 1. Counter & State register
    always_ff @(posedge clk) begin
        if (rst)  begin current_state <= IDLE;
                count<=4'd0; end
        else begin current_state <= next_state;
            case (current_state)
                IDLE:    if (start) count <= 4'd2;
                ACTIVE:  if (!stop) count <= next_count;
                default: count <= count;
            endcase
        end
    end

    // 2. Next-state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:    if (start) next_state = ACTIVE;
            ACTIVE:  if (stop)  next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 3. Counter block 
    always_comb begin
        case (count)
            4'd2:    next_count = 4'd3;
            4'd3:    next_count = 4'd5;
            4'd5:    next_count = 4'd7;
            4'd7:    next_count = 4'd11;
            4'd11:   next_count = 4'd13;
            default: next_count = 4'd2; // 13 wraps to 2; recovers invalid states to 2
        endcase
    end

    

endmodule
