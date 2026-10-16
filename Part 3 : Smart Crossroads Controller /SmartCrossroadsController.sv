module crossroads_ctrl (
    input  logic clk,
    input  logic rst,
    input  logic [1:0] dens_N, dens_S, dens_E, dens_W,
    output logic [3:0] green,
    output logic [3:0] yellow
);

    typedef enum logic [1:0] {SELECT, GREEN, YELLOW} state_t;
    state_t state, next_state;

    // 1. Array of Order: N, E, S, W (Indices 0, 1, 2, 3)
    logic [1:0] dens [0:3];
    assign dens[0] = dens_N;
    assign dens[1] = dens_E;
    assign dens[2] = dens_S;
    assign dens[3] = dens_W;

    // 2. Output Pin Mapping Array
    // Outputs are {W, E, S, N} (Bits 3, 2, 1, 0)
    // Internal rotation is N(0), E(1), S(2), W(3)
    // This array maps internal index -> output bit: N=0, E=2, S=1, W=3
    localparam logic [1:0] OUT_BIT [0:3] = '{2'd0, 2'd2, 2'd1, 2'd3};

    // Registers
    logic [3:0] timer, next_timer;
    logic [1:0] last_served, next_last_served;
    logic [1:0] active_dir, next_active_dir;
    logic [1:0] wait_ctr [0:3], next_wait_ctr [0:3];

    // Helper variables
    logic [1:0] max_dens;
    logic has_starving;
    integer check_idx;

    // state & counter register block
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= SELECT;
            timer       <= 0;
            active_dir  <= 0;
            last_served <= 3; // Start at W(3) so rotation naturally picks N(0) first
            for (int i = 0; i < 4; i++) wait_ctr[i] <= 0;
        end else begin
            state       <= next_state;
            timer       <= next_timer;
            active_dir  <= next_active_dir;
            last_served <= next_last_served;
            for (int i = 0; i < 4; i++) wait_ctr[i] <= next_wait_ctr[i];
        end
    end

    // decision block
    always_comb begin
        // Defaults
        next_state       = state;
        next_timer       = timer;
        next_active_dir  = active_dir;
        next_last_served = last_served;
        for (int i = 0; i < 4; i++) next_wait_ctr[i] = wait_ctr[i];

        green  = 4'b0000;
        yellow = 4'b0000;

        case (state)
            SELECT: begin
                has_starving = 1'b0;
                max_dens     = 2'b00;

                // Loop 1: Find if anyone is starving AND find max density simultaneously
                for (int i = 0; i < 4; i++) begin
                    if (wait_ctr[i] == 3) has_starving = 1'b1;
                    if (dens[i] > max_dens) max_dens = dens[i];
                end
                // Loop 2: Tie-breaker using strict N->E->S->W rotation array
                for (int i = 1; i <= 4; i++) begin
                    check_idx = (last_served + i) % 4; // Cycles 0,1,2,3...

                    if (has_starving) begin
                        if (wait_ctr[check_idx] == 3) begin
                            next_active_dir = check_idx;
                            break;
                        end
                    end else begin
                        if (dens[check_idx] == max_dens) begin
                            next_active_dir = check_idx;
                            break;
                        end
                    end
                end
                // Loop 3: Update Wait Counters
                for (int i = 0; i < 4; i++) begin
                    if (i == next_active_dir) begin
                        next_wait_ctr[i] = 0; // Reset winner
                    end else if (wait_ctr[i] < 3) begin
                        next_wait_ctr[i] = wait_ctr[i] + 1; // Increment losers
                    end
                end
                // Set up GREEN timer based on winner's density
                next_last_served = next_active_dir;
                next_timer = 4 + (2 * dens[next_active_dir]) - 1; 
                next_state = GREEN;
            end

            GREEN: begin
                // Directly set the correct output bit using the mapping array
                green[OUT_BIT[active_dir]] = 1'b1; 

                if (timer == 0) begin
                    next_timer = 1; // 2 ticks for yellow (1, 0)
                    next_state = YELLOW;
                end else begin
                    next_timer = timer - 1;
                end
            end

            YELLOW: begin
                // Directly set the correct output bit using the mapping array
                yellow[OUT_BIT[active_dir]] = 1'b1;
                if (timer == 0) begin
                    next_state = SELECT;
                end else begin
                    next_timer = timer - 1;
                end
            end
        endcase
    end
endmodule
