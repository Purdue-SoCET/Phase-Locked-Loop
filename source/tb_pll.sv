
`timescale 1ns/1ps
module tb_pll;

    // Parameters

    /*
    localparam TDC_SIZE = 6;
    localparam TDC_RESOLUTION = 50;
    localparam LF_OUT_SIZE = 8;
    localparam FREQ_MIN = 50000.0;
    localparam FREQ_MAXG = 50000.0;
    localparam N_SIZE = 8;
    */

    localparam CLK_PERIOD = 1000;

    // Signals
    logic tb_clk_ref, tb_n_rst;
    logic tb_enable;
    logic [15:0] tb_kp, tb_ki;
    logic [7:0] tb_n;

    logic tb_clk_out;

    // Instantiate PLL
    //#(TDC_SIZE, TDC_RESOLUTION, LF_OUT_SIZE, FREQ_MIN, FREQ_MAXG, N_SIZE)
    pll dut(.clk_ref(tb_clk_ref), .n_rst(tb_n_rst), .enable(tb_enable), .kp(tb_kp), .ki(tb_ki), .n(tb_n), .clk_out(tb_clk_out));


always begin
  // Start with clock low to avoid false rising edge events at t=0
  tb_clk_ref= 1'b0;
  // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
  tb_clk_ref = 1'b1;
  // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
end

task calculateAndDisplayFrequency;
    integer count;
    realtime t_start, t_end, diff;
    real avg_period, frequency;

    @(posedge tb_clk_out); // Wait for the first rising edge
    t_start = $realtime(); // Start time

    // Wait for 20 rising edges of the clock
    for (count = 0; count < 20; count = count + 1) begin
        @(posedge tb_clk_out);
    end

    t_end = $realtime(); // End time after 20 periods

    diff = t_end - t_start; // Total time for 20 periods

    avg_period = diff / 20.0 * 1e-9; // Average period in seconds for one cycle
    //frequency = 1.0 / avg_period; // Frequency in Hz
    frequency = 1.0 / avg_period / 1e6; // Frequency in MHz

    // Display the results
    //$display("Average Period: %.10f seconds", avg_period);
    $display("Frequency: %.10f Hz", frequency);
endtask




    initial begin
         // Initialize signals
        tb_n = 8'd75;
        tb_kp = 16'h0100;
        tb_ki = 16'h0008;
        tb_enable = 1'b0;
        tb_clk_ref = 1'b0;
        tb_n_rst = 1'b1;
        #50;
        tb_n_rst = 1'b0;
        // Apply reset
        #50;
        tb_n_rst = 1'b1;

        // Wait for enable
        #100;
        tb_enable = 1'b1;

    forever begin
        calculateAndDisplayFrequency();
    end

    end

endmodule
