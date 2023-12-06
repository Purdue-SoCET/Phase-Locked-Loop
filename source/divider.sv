`timescale 1ns/1ps

module divider #(parameter N_SIZE = 8)(
    input logic clk_in, // Input clock
    input logic n_rst,
    input logic [N_SIZE - 1:0] n, // Divider value
    input logic enable,
    output logic clk_div // Divided clock output
);

    logic [N_SIZE - 1:0] counter;
    logic clk_div_int; // Internal divided clock signal

    always @(posedge clk_in or negedge n_rst) begin
        if (!n_rst)
            counter <= 0;
        else if (enable) begin
            if (counter == n - 1)
                counter <= 0;
            else
                counter <= counter + 1;
        end
    end

    // Toggle clk_div_int when counter is at halfway or full count
    always @(posedge clk_in or negedge n_rst) begin
        if (!n_rst)
            clk_div_int <= 0;
        else if (enable && (counter == (n >> 1) - 1 || counter == n - 1))
            clk_div_int <= ~clk_div_int;
    end

    assign clk_div = clk_div_int;

endmodule

