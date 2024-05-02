module filter#(
    // epu params
    parameter ERR_SIZE = 8, 
    parameter N_SIZE = 8,
    parameter TDC_SIZE = 255,
    // filter params
    parameter K_INT_SIZE = 8,
    parameter K_FRAC_SIZE = 8,
    parameter ACCUMULATOR_SIZE = 24,
    parameter LF_OUT_SIZE = 16,
    parameter FILTER_OUT_SIZE = 5,
    parameter DOUT_SIZE = 32
)(
    // Filter Inputs
    input wire VDD,
    input wire VSS,

    input logic clk_ref, 
    input logic n_rst,
    input logic enable,

    input logic [1 : 0] freq_lock_range,
    input logic [N_SIZE - 1: 0] n,                      // EPU inputs
    input logic [TDC_SIZE - 1:0] tdc_therm,
    input logic clk_out,
    
    input signed [(K_INT_SIZE + K_FRAC_SIZE) - 1:0] kp, // Loop Filter Inputs
    input signed [(K_INT_SIZE + K_FRAC_SIZE)- 1:0] ki,

    // Filter Outputs
    output logic [FILTER_OUT_SIZE - 1 : 0] filter_out,  // Main Filter Outputs
    output logic [DOUT_SIZE - 1: 0] dout,
    output logic [DOUT_SIZE - 1: 0] dout_neg,

    output logic [LF_OUT_SIZE - 1 : 0] lf_out,          // Debugging Signals
    output logic [ERR_SIZE - 1: 0] therm_to_bin_out,
    output logic freq_locked,
    output logic phase_locked
);

    logic signed [ERR_SIZE - 1:0] lf_in;
    logic [LF_OUT_SIZE - 1 : 0] int_lf_out;



    // Error Processing Unit
    epu #(  .ERR_SIZE(ERR_SIZE), .N_SIZE(N_SIZE), .TDC_SIZE(TDC_SIZE))                                                                                                      // parameters
    epu0 (                                  
            .VDD(VDD), .VSS(VSS), .clk_ref(clk_ref), .n_rst(n_rst), .n(n), .enable(enable),.freq_lock_range(freq_lock_range), .tdc_therm(tdc_therm), .clk_out(clk_out),     // inputs
            .epu_out(lf_in), .therm_to_bin_out(therm_to_bin_out), .freq_locked(freq_locked), .phase_locked(phase_locked));                                                  // outputs

    
    // Loop Filter
    lf #(   .ERR_SIZE(ERR_SIZE), .ACCUMULATOR_SIZE(ACCUMULATOR_SIZE), .K_INT_SIZE(K_INT_SIZE), .K_FRAC_SIZE(K_FRAC_SIZE), .LF_OUT_SIZE(LF_OUT_SIZE))    // parameters      
    lf0 (   
            .VDD(VDD), .VSS(VSS), .lf_in(lf_in), .Kp(kp), .Ki(ki), .clk_ref(clk_ref), .n_rst(n_rst), .enable(enable),                                   // inputs
            .lf_out(int_lf_out));                                                                                                                       // outputs
    assign lf_out = int_lf_out;

    
    // Delta Sigma DAC Modulation
    dsdac_mod dsdac_mod0(
            .VDD(VDD), .VSS(VSS), .clk_ref(clk_ref), .n_rst(n_rst), .enable(enable), .din(int_lf_out), .out_set({FILTER_OUT_SIZE{1'b0}}),               // inputs
            .mod_out(filter_out), .mod_err(), .dout(dout), .dout_neg(dout_neg));                                                                        // outputs



endmodule