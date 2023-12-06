`timescale 1ps/1ps
module tdc 
#(parameter TDC_SIZE = 6, parameter TDC_RESOLUTION = 50)
 (
    input logic clk_ref, clk_div, n_rst,
    input logic enable, 
    output logic [TDC_SIZE - 1:0] error
);

logic [TDC_SIZE - 1:0] tdc_int;

always @(*) begin
    if (enable) begin
        tdc_int[0] = clk_div;
        for (int x = 1; x <= TDC_SIZE - 1; x = x + 1) begin
            tdc_int[x] = #(TDC_RESOLUTION) tdc_int[x - 1];
        end
    end

end

always @ (posedge clk_ref or negedge n_rst) begin
    if (!n_rst) begin
        tdc_int <= 0;
        error <= 0;
    end
    else if (enable) begin
        error <= tdc_int;
    end

end

endmodule