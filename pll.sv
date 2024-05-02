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
    parameter FILTER_OUT_SIZE = 5,
    parameter DOUT_SIZE = 32,

    
    // DCO parameters
    parameter FREQ_MIN = 50000.0,
    parameter FREQ_MAXG = 50000.0,

    // Divider parameter
    parameter N_SIZE = 8
    
    )
    (input logic clk_ref, n_rst,
     input logic [N_SIZE - 1:0] n,
     input logic [(K_INT_SIZE + K_FRAC_SIZE - 1):0] kp, ki,
     input logic enable,
     input logic [1:0] freq_lock_range,
     output logic clk_out,
     output logic freq_locked,
     output logic phase_locked
     );


    logic clk_div; 


    // TDC 
    logic [TDC_SIZE-1:0] tdc_therm; // TDC output thermometer code


    // Filter
    logic [FILTER_OUT_SIZE - 1:0] filter_out;
    logic [LF_OUT_SIZE - 1:0] lf_out;
    logic [ERR_SIZE -  1: 0] therm_to_bin_out;


    logic [DOUT_SIZE - 1: 0] dout;
    logic [DOUT_SIZE - 1: 0] dout_neg;

    // Divider
    logic osc_out; 

    // TIME TO DIGITAL CONVERTER MODULE
    tdc #(.TDC_SIZE(TDC_SIZE), .TDC_RESOLUTION(TDC_RESOLUTION))                             // Parameters
    tdc0(
        .clk_div(clk_div), .clk_ref(clk_ref),  .n_rst(n_rst), .enable(enable),              // Inputs
        .error(tdc_therm));                                                                 // Outputs



    // FILTER MODULE
    filter filter0(
        .clk_ref(clk_ref), .n_rst(n_rst), .enable(enable), .freq_lock_range(freq_lock_range), .n(n), .tdc_therm(tdc_therm), .clk_out(clk_out), .kp(kp), .ki(ki),                    // Inputs
        .filter_out(filter_out), .dout(dout), .dout_neg(dout_neg), .lf_out(lf_out), .freq_locked(freq_locked), .phase_locked(phase_locked) , .therm_to_bin_out(therm_to_bin_out));  // Outputs     


    // DCO MODULE
    osc osc0(.DFINE(filter_out), .OSC(osc_out)); // ideal oscillator

    // dco #(.FREQ_MIN(FREQ_MIN), .FREQ_MAXG(FREQ_MAXG), .BITLEN(LF_OUT_SIZE))     // old oscillator                                            
    // dco0(.d_in(lf_out), .enable(enable), .clk_out(osc_out));



    assign clk_out = osc_out;

    // DIVIDER MODULE
    divider #(.N_SIZE(N_SIZE))                                               // Parameters
    divider0(.clk_in(osc_out), .n_rst(n_rst), .n(n), .enable(enable),        // Inputs
             .clk_div(clk_div));                                             // Outputs




endmodule