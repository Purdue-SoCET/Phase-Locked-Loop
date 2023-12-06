
`timescale 1ns/1ps
module pll#(

    // TDC parameters
    parameter TDC_SIZE = 255,
    parameter TDC_RESOLUTION = 50,

    // Loop Filter Parameters
    parameter ERR_SIZE = 8,
    parameter ACCUMULATOR_SIZE = 24,
    parameter K_INT_SIZE = 8,
    parameter K_FRAC_SIZE = 8,
    parameter LF_OUT_SIZE = 16,

    
    // DCO parameters
    parameter FREQ_MIN = 50000.0,
    parameter FREQ_MAXG = 50000.0,

    // Divider parameter
    parameter N_SIZE = 8
    
    )
    (input logic clk_ref, n_rst,
     input logic [N_SIZE - 1:0] n,
     input logic [15:0] kp, ki,
     input logic enable,
     output logic clk_out);


    //localparam LF_OUT_SIZE = (1 + (ERR_SIZE + K_INT_SIZE > ACCUMULATOR_SIZE + K_INT_SIZE ? ERR_SIZE + K_INT_SIZE : ACCUMULATOR_SIZE + K_INT_SIZE));
    

    logic clk_div; 

    logic [TDC_SIZE-1:0] tdc_therm; // TDC output thermometer code
    logic [ERR_SIZE -1 : 0] tdc_error; // binary conversion of TDC thermomemter
    logic [ERR_SIZE -1 : 0] lf_in;
    logic [LF_OUT_SIZE-1:0] lf_out; // loop filter output
    //logic [N_SIZE - 1: 0] n;
    logic dco_out; // dco output
    logic [7:0] count;

    

    // Time To Digital Converter
    tdc #(.TDC_SIZE(TDC_SIZE), .TDC_RESOLUTION(TDC_RESOLUTION)) 
    _tdc(.clk_div(clk_div), .clk_ref(clk_ref),  .n_rst(n_rst), .enable(enable), .error(tdc_therm));


    // Thermometer code to binary
    therm_to_bin #(.THERM_BITS(TDC_SIZE))
    _therm_to_bin(.thermometer_code(tdc_therm), .binary_representation(tdc_error));

    // Counter
    counter _counter(.clk_ref(clk_ref), .n_rst(n_rst), .enable(enable), .clk_out(dco_out), .count(count));


    // error input
    error#( .ERR_SIZE(ERR_SIZE), .N_SIZE(N_SIZE))
    _error(.clk_ref(clk_ref), .n_rst(n_rst),.n(n), .enable(enable), .count(count), .tdc_error(tdc_error), .lf_in(lf_in)
 ); 



    // Digital Loop Filter
  filter #(
    .ERR_SIZE(ERR_SIZE),
    .ACCUMULATOR_SIZE(ACCUMULATOR_SIZE),
    .K_INT_SIZE(K_INT_SIZE),
    .K_FRAC_SIZE(K_FRAC_SIZE),
    .LF_OUT_SIZE(LF_OUT_SIZE))
  _filter(.error(lf_in), .Kp(kp), .Ki(ki), .clk_ref(clk_ref), .n_rst(n_rst), .enable(enable), .lf_out(lf_out));

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

    dco #(.FREQ_MIN(FREQ_MIN),
          .FREQ_MAXG(FREQ_MAXG),
          .BITLEN(LF_OUT_SIZE))
    _dco(.d_in(lf_out), .enable(enable), .clk_out(dco_out));

    assign clk_out = dco_out;



    divider #(.N_SIZE(N_SIZE))
    _divider(.clk_in(dco_out), .n_rst(n_rst), .n(n), .enable(enable), .clk_div(clk_div));

    //assign n = 8'd72; // MHz freq goal 

endmodule