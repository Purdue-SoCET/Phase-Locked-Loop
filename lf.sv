/* 

Loop Filter Module takes in 

- Kp, Ki from the AHB,which will be in signed Q8.8 form.
- 8 bit lf_in from output of EPU, based on freq_locked (lf_in = TDC Val) or f_slow (lf_in =  +127) or f_fast (lf_in = -128).


and outputs 16 bits lf_out, sent to DSDAC_MOD

*/

`timescale 1ns/1ps
module lf #(
    parameter ERR_SIZE = 8,
    parameter ACCUMULATOR_SIZE = 24,
    parameter K_INT_SIZE = 8,
    parameter K_FRAC_SIZE = 8,
    parameter LF_OUT_SIZE = 16
) (
    // Inputs
    input wire VDD,
    input wire VSS,
    
    input wire clk_ref,
    input wire n_rst,

    input logic enable,
    input signed [ERR_SIZE - 1:0] lf_in,                // Input Error from TDC/EPU
    input signed [(K_INT_SIZE + K_FRAC_SIZE) - 1:0] Kp, // Proportional Gain 
    input signed [(K_INT_SIZE + K_FRAC_SIZE)- 1:0] Ki,  //  Integral Gain 

    // Outputs
    output logic [LF_OUT_SIZE - 1:0] lf_out             // Output gets sent to DSDAC_MOD/DCO
);

// Accumulator (integral component) Register and Next State Signals
logic signed [ACCUMULATOR_SIZE - 1 : 0] accumulator;
logic signed [ACCUMULATOR_SIZE - 1 : 0] temp_next_accumulator;
logic signed [ACCUMULATOR_SIZE - 1 : 0] next_accumulator;

// Loop Filter Next State Signals
logic signed [LF_OUT_SIZE - 1:0] intermediate_lf_out;
logic [LF_OUT_SIZE - 1:0] next_lf_out;


// Accumulator and Output Flip Flops
always_ff @ (posedge clk_ref,negedge n_rst) begin
    if (!n_rst) begin
        accumulator <= 0;
        lf_out <= 0;
    end
    else if (enable) begin
        accumulator <= next_accumulator;
        lf_out <= next_lf_out;
    end
end


always_comb begin

    // Positive and negative overflow checks, saturation logic
    temp_next_accumulator = accumulator + lf_in;
    if (!accumulator[ACCUMULATOR_SIZE-1] && !lf_in[ERR_SIZE-1] && (temp_next_accumulator) < 0)
        next_accumulator = {1'b0, {ACCUMULATOR_SIZE-1{1'b1}}}; // Max positive value
    else if (accumulator[ACCUMULATOR_SIZE-1] && lf_in[ERR_SIZE-1] && (temp_next_accumulator) >= 0)
        next_accumulator = {1'b1, {ACCUMULATOR_SIZE-1{1'b0}}}; // Max negative value
    else
        next_accumulator = accumulator + lf_in;

    // Compute (kp * error) + (ki * sigma(error)), truncate fractional component
    intermediate_lf_out = ((lf_in * Kp) >> K_FRAC_SIZE) + ((accumulator * Ki) >> K_FRAC_SIZE);

    // convert lf_out to an unsigned value 
    next_lf_out = $unsigned(intermediate_lf_out) + (1 << (LF_OUT_SIZE - 1));
end




endmodule

