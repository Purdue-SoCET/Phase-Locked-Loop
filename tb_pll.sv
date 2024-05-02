/* THIS FILE HAS TWO TESTBENCHES 
1. Basic PLL testing
2. PLL Sweep for 
*/ 


// 1. 
`timescale 1ns/1ps
module tb_pll;

    localparam CLK_PERIOD = 1000;

    // Signals
    logic tb_clk_ref, tb_n_rst;
    logic tb_enable;
    logic [15:0] tb_kp, tb_ki;
    logic [7:0] tb_n;

    logic tb_clk_out;

    // Instantiate PLL
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

    @(posedge tb_clk_out); 
    t_start = $realtime();

    for (count = 0; count < 20; count = count + 1) begin
        @(posedge tb_clk_out);
    end

    t_end = $realtime();

    diff = t_end - t_start;

    avg_period = diff / 20.0 * 1e-9;
    //frequency = 1.0 / avg_period; // Frequency in Hz
    frequency = 1.0 / avg_period / 1e6; // Frequency in MHz

    // Display the results
    //$display("Average Period: %.10f seconds", avg_period);
    $display("Frequency: %.10f MHz", frequency);
endtask



    initial begin
         // Initialize signals
        tb_n = 8'd85;
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



  real tlastdiv = 0;
  real fdiv = 1;
  real tlastclk = 0;
  real div2clk = 0;
  real clk2div = 0;
  real pherr = 0;


 
  always @ (posedge dut.clk_div) begin
    fdiv = 1000.0 / (($realtime() - tlastdiv));
    clk2div = ($realtime - tlastclk);
    tlastdiv = $realtime();
  end
  always @ (posedge tb_clk_ref) begin
    div2clk = ($realtime - tlastdiv);
    tlastclk = $realtime();
  end

  always @ (clk2div, div2clk) begin
    if(clk2div < (CLK_PERIOD/2.0)) begin
      pherr = clk2div;
    end else if (div2clk < CLK_PERIOD/2.0) begin
      pherr = -div2clk;
    end
  end

endmodule





// // SWEEP FOR OPTIMAL KP AND KI VALUES TESTBENCH
// // 2. 
// `timescale 1ns/1ps
// module tb_pll;

//     localparam CLK_PERIOD = 1000;
//     localparam SAMPLE_SIZE = 100;


//     // localparam KP_START = 16'h00FF;
//     // localparam KP_END = 16'h0101;
//     // localparam KP_STEP = 16'h0001;


//     // localparam KI_START = 16'h0004;
//     // localparam KI_END = 16'h0100;
//     // localparam KI_STEP = 16'h0001;


//     localparam KP_START = 16'h00FF;
//     localparam KP_END = 16'h0101;
//     localparam KP_STEP = 16'h0001;


//     localparam KI_START = 16'h0026;
//     localparam KI_END = 16'h0100;
//     localparam KI_STEP = 16'h0001;



//     // Signals
//     logic tb_clk_ref, tb_n_rst;
//     logic tb_enable;
//     logic [15:0] tb_kp, tb_ki;
//     logic [7:0] tb_n;
//     logic [1:0] tb_freq_lock_range;

//     logic tb_clk_out;
//     logic tb_freq_locked;
//     logic tb_phase_locked;

//     // Instantiate PLL
//     pll dut(.clk_ref(tb_clk_ref), .n_rst(tb_n_rst), .enable(tb_enable), .freq_lock_range(tb_freq_lock_range), .kp(tb_kp), .ki(tb_ki), .n(tb_n), .clk_out(tb_clk_out), .freq_locked(tb_freq_locked), .phase_locked(tb_phase_locked));


// // clock definition
// always begin
//   tb_clk_ref= 1'b0;
//   #(CLK_PERIOD/2.0);
//   tb_clk_ref = 1'b1;
//   #(CLK_PERIOD/2.0);
// end


// // display frequency to console
// task calculateAndDisplayFrequency;
//     integer count;
//     realtime t_start, t_end, diff;
//     real avg_period, frequency;

//     @(posedge tb_clk_out); 
//     t_start = $realtime();

//     for (count = 0; count < 20; count = count + 1) begin
//         @(posedge tb_clk_out);
//     end

//     t_end = $realtime();

//     diff = t_end - t_start;

//     avg_period = diff / 20.0 * 1e-9;
//     //frequency = 1.0 / avg_period; // Frequency in Hz
//     frequency = 1.0 / avg_period / 1e6; // Frequency in MHz

//     // Display the results
//     //$display("Average Period: %.10f seconds", avg_period);
//     $display("Frequency: %.10f MHz", frequency);
// endtask



// // perform rolling variance calculation upon a new phase error data entry
// task calculate_variance(input real pherr_new, output real variance);


// real pherr_values[SAMPLE_SIZE];
// static integer count = 0;
// real mean;
// real s;
// real mean_new, s_new;
// real oldest_val;

// // filling up the array
// if (count < SAMPLE_SIZE) begin

//     if (count == SAMPLE_SIZE - 1) begin
//         mean = 0;
//         s = 0;
//         for (int i = 0; i < SAMPLE_SIZE; i = i + 1) begin
//             mean = mean + pherr_values[i];
//         end
//         mean = mean / SAMPLE_SIZE;
//         for (int i = 0; i < SAMPLE_SIZE; i = i + 1) begin
//             s = s + (pherr_values[i] - mean) ** 2;
//         end
//         variance = s / SAMPLE_SIZE;

//         count = count + 1;
//     end

//     else begin
//         pherr_values[count] = pherr_new;
//         mean = 0;
//         s = 0;
//         variance = 0;
//         count = count + 1;
//     end
// end

// // remove oldest value in the array,insert newest value, and calculate new variance
// else begin
//     pherr_values[0] = oldest_val;
//     mean = 0;
//     s = 0;

//     for (int i = 0; i < SAMPLE_SIZE - 1; i = i + 1) begin
//         pherr_values[i] = pherr_values[i + 1];
//         mean = mean + pherr_values[i];
//       end

//     pherr_values[SAMPLE_SIZE - 1] = pherr_new;
//     mean_new = mean_new + pherr_new;


//     // calculate S
//     for (int i = 0; i < SAMPLE_SIZE; i = i  + 1) begin
//       s = s + (pherr_values[i] - mean) ** 2;
//     end

//     variance = s / SAMPLE_SIZE;


// end


// endtask


// task reset_pll();
//     // reset
//     #50;
//     tb_enable = 1'b0;
//     tb_clk_ref = 1'b0;
//     tb_n_rst = 1'b1; 
//     #50;
//     tb_n_rst = 1'b0;
//     // Apply reset
//     #50;
//     tb_n_rst = 1'b1;
//     // Wait for enable
//     #100;
//     tb_enable = 1'b1;
//     tb_freq_lock_range = 2'd1;
    

// endtask



//   real tlastdiv = 0;
//   real fdiv = 1;
//   real tlastclk = 0;
//   real div2clk = 0;
//   real clk2div = 0;
//   real pherr = 0;
//   real variance = 0;



// // clk2div gets updated here
//    always @ (posedge dut.clk_div) begin
//     fdiv = 1000.0 / (($realtime() - tlastdiv));
//     clk2div = ($realtime - tlastclk);
//     tlastdiv = $realtime();
//   end

// // div2clk gets updated here
//   always @ (posedge tb_clk_ref) begin
//     div2clk = ($realtime - tlastdiv);
//     tlastclk = $realtime();
//   end


// // Phase error gets updated here
//   always @ (clk2div, div2clk) begin
//     if(clk2div < (CLK_PERIOD/2.0)) begin
//       pherr = clk2div;
//       calculate_variance(pherr, variance);
//     end else if (div2clk < CLK_PERIOD/2.0) begin
//       pherr = -div2clk;
//       calculate_variance(pherr, variance);
//     end
//   end





// // Sweep through kp and ki (mess around with coarse grain, fine grain, etc.)
// initial begin
//     logic [15:0] kp, ki, best_kp, best_ki;
//     real min_phase_error_variance;
//     min_phase_error_variance = 1e9; // A large initial value
//     best_kp = 0;
//     best_ki = 0;

//     tb_n = 8'd90;
//     for (kp = KP_START; kp < KP_END; kp = kp + KP_STEP) begin

//             for (ki = KI_START; ki < KI_END; ki = ki + KI_STEP) begin
//                 tb_kp = kp;
//                 tb_ki = ki;
//                 reset_pll();
//                 #(CLK_PERIOD * 10000); // 20 ms
//                 if (variance < min_phase_error_variance) begin
//                     best_kp = kp;
//                     best_ki = ki;
//                     min_phase_error_variance = variance;
//                 end

//                 $display("Kp: %f, Ki: %f, Phase Error Variance: %f", kp, ki, variance);
//                 if (tb_phase_locked) begin
//                   $display("Phase Locked Successful.");
//                 end
//             end
//     end

//   $stop;
// end




// endmodule
