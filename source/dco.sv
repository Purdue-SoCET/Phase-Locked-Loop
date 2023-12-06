`timescale 1ns/1ps
module dco #(parameter FREQ_MIN = 50000.0,
             parameter FREQ_MAXG = 50000.0,
             parameter BITLEN = 16)
(
    input logic [BITLEN - 1: 0] d_in,
    input logic enable,
    output logic clk_out
);

real gain, freq_new, pd_new;
logic vco = 1'b0;

always_comb begin
    gain = (real'(d_in) * FREQ_MAXG) / ((2 ** BITLEN) - 1);
    freq_new = FREQ_MIN + gain;
    pd_new = 1.0 / (freq_new * 1e3) * 1e9;
end

always begin
    if (enable) begin
        #(pd_new / 2.0) vco = ~vco;
    end
    else begin
        vco = 1'b0;
        wait (enable == 1'b1);  // Wait for enable to go high
    end
end

assign clk_out = vco;

endmodule