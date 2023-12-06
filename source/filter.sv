`timescale 1ns/1ps

module filter #(
    parameter ERR_SIZE = 16,
    parameter ACCUMULATOR_SIZE = 24,
    parameter K_INT_SIZE = 8,
    parameter K_FRAC_SIZE = 8,
    parameter LF_OUT_SIZE = 16
) (
    input wire clk_ref,
    input wire n_rst,
    input logic enable,
    input signed [ERR_SIZE - 1:0] error,
    input signed [(K_INT_SIZE + K_FRAC_SIZE) - 1:0] Kp,
    input signed [(K_INT_SIZE + K_FRAC_SIZE)- 1:0] Ki,
    output logic [LF_OUT_SIZE - 1:0] lf_out
);

// Register for accumulator (integral)
reg signed [ACCUMULATOR_SIZE - 1 : 0] accumulator;
reg signed [ACCUMULATOR_SIZE - 1 : 0] next_accumulator;

logic [LF_OUT_SIZE - 1:0] next_lf_out;

always @ (posedge clk_ref or negedge n_rst) begin
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
    if (enable) begin
        next_accumulator = error + accumulator;
        next_lf_out = ((error * Kp) >> K_FRAC_SIZE) + ((accumulator * Ki) >> K_FRAC_SIZE);

        // if loop filter output will be negative, make it zero.
        if (((error * Kp) + (accumulator * Ki)) < 0)
            next_lf_out = 0;
    end

end
endmodule


