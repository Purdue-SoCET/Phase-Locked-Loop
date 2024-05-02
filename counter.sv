/* Counter Module

We want to count number of clk_out pulses that occur between two clk_ref pulses.
Clk_Ref = 1 MHz
Clk_Out = 50 - 100 MHz

so count should be 50 - 100

Internal count is getting updated on each posedge of faster clk_out clock. 
Then clk_ref goes high (suppose internal_count = 59), and on the next clk_out (internal_count = 60 now) we go to state where we will update the outputted count with the internal count.
The next_clk_out, we assign internal_count - 1 (60 - 1 = 59) to count and reset the internal_count to 2 since two clk_outs have occurred since clk_ref being high.


When does EPU see the count? Count will be determined between two clk_ref pulses and then that count will be used for the next clk_ref in the EPU. 

Clk_Ref
|--------|________|--------|________|--------|________|--------|________

                  Clk_ref Pulse      Clk_ref Pulse    (EPU sees 59 here)
|Count = x                             |Count = 59 





CDC Concern: if clk_ref violates setup time (or hold time) of clk_out what happens?
Clk_out is essentially polling clk_ref... 


*/

// This version is Implemented in Schematic (unsure about Potential Clock Domain Crossing Issues)
module counter(
    input logic VDD,VSS,
    input logic  clk_ref,
    input logic  clk_out,
    input logic   n_rst,
    input logic   enable,
    output logic [7:0] count
);


typedef enum logic [1:0] {
    IDLE = 2'b00,
    UPDATE_COUNT_AND_RESET_INTERNAL = 2'b01,
    WAIT_FOR_NEGEDGE = 2'b10
} state_t;


state_t state, next_state;
logic [7:0] internal_count, next_internal_count; // Internal counter for clk_out edges
logic [7:0] next_count;




always_ff @(posedge clk_out, negedge n_rst) begin
    if (!n_rst) begin
        state <= IDLE;
        count <= 0;
        internal_count <= 0;
    end

    else if (enable) begin
        state <= next_state;
        count <= next_count;
        internal_count <= next_internal_count; // update internal count on every clk_out
    end
end



always_comb begin
    next_state = state;

    casez (state)
        IDLE: next_state = (clk_ref)? UPDATE_COUNT_AND_RESET_INTERNAL: IDLE; // when clk_ref = 1, then set 

        UPDATE_COUNT_AND_RESET_INTERNAL: next_state = (clk_ref)? WAIT_FOR_NEGEDGE: IDLE;

        WAIT_FOR_NEGEDGE: if (!clk_ref) next_state = IDLE;
        default: next_state = IDLE;
    endcase


end



always_comb begin

    casez(state)

        IDLE: begin
            next_count = count;
            next_internal_count = internal_count + 1;
        end

        UPDATE_COUNT_AND_RESET_INTERNAL:  begin
            if (clk_ref) begin
                next_count = internal_count - 1; // count gets updated.
                next_internal_count = 2;
            end

            else begin
                next_count = count;
                next_internal_count = internal_count + 1;
            end
        end

        WAIT_FOR_NEGEDGE: begin
            next_count = count;
            next_internal_count = internal_count + 1;
        end

        default: begin
            next_count = count;
            next_internal_count = internal_count;
        end

    endcase

end




endmodule




/* 
Code below might be better for CDC since it registers clk_ref changes as a pulse signal. 

Concern is if clk_out goes high as the pulse signal is changing due to clk_ref going high at same time. 
Pulse signal is not ready yet and clk_out tries to read it.


*/ 




// module counter(
//     input logic VDD,VSS,
//     input logic  clk_ref,
//     input logic  clk_out,
//     input logic   n_rst,
//     input logic   enable,
//     output logic [7:0] count
// );


// typedef enum logic [1:0] {
//     IDLE = 2'b00,
//     UPDATE_COUNT_AND_RESET_INTERNAL = 2'b01,
//     WAIT_FOR_NEGEDGE = 2'b10
// } state_t;


// state_t state, next_state;
// logic [7:0] internal_count, next_internal_count; // Internal counter for clk_out edges
// logic [7:0] next_count;




// always_ff @(posedge clk_out, negedge n_rst) begin
//     if (!n_rst) begin
//         state <= IDLE;
//         count <= 0;
//         internal_count <= 0;
//     end

//     else if (enable) begin
//         state <= next_state;
//         count <= next_count;
//         internal_count <= next_internal_count; // update internal count on every clk_out
//     end
// end


// // Synchronous Reset on Clk, FF uses both posedge and negedge of clk_ref
// always_ff @(posedge clk_ref, negedge clk_ref) begin
//     if (!n_rst) begin
//         pulse <= 0;
//     end
//     else begin
//         pulse <= !pulse;
//     end
// end




// // Next State Logic
// always_comb begin
//     next_state = state;

//     casez (state)
//         IDLE: next_state = (pulse)? UPDATE_COUNT_AND_RESET_INTERNAL: IDLE; // when pulse is updated by clock_ref posedge, update the output count. 

//         UPDATE_COUNT_AND_RESET_INTERNAL: next_state = (pulse)? WAIT_FOR_NEGEDGE: IDLE; // pulse will be high for a while, so we need to wait for it to go to 0 upon a negedge of clk_ref to avoid looping through state machine and constantly updating count. 

//         WAIT_FOR_NEGEDGE: if (!pulse) next_state = IDLE; // when pulse is 0, return to IDLE and wait for pulse to go high again to update the count. 
//         default: next_state = IDLE;
//     endcase


// end



// // Output Logic
// always_comb begin

//     casez(state)

//         IDLE: begin
//             next_count = count;
//             next_internal_count = internal_count + 1;
//         end

//         UPDATE_COUNT_AND_RESET_INTERNAL:  begin
//             if (clk_ref) begin
//                 next_count = internal_count - 1; // count gets updated.
//                 next_internal_count = 2;
//             end

//             else begin
//                 next_count = count;
//                 next_internal_count = internal_count + 1;
//             end
//         end

//         WAIT_FOR_NEGEDGE: begin
//             next_count = count;
//             next_internal_count = internal_count + 1;
//         end

//         default: begin
//             next_count = count;
//             next_internal_count = internal_count;
//         end

//     endcase

// end




// endmodule










