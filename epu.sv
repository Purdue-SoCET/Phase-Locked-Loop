module epu#(
    parameter ERR_SIZE = 8, 
    parameter N_SIZE = 8,
    parameter TDC_SIZE = 255
)(
    input wire VDD,
    input wire VSS,
    
    input logic clk_ref, 
    input logic n_rst,
    input logic enable,

    // Inputs
    input logic [1 : 0] freq_lock_range,
    input logic [N_SIZE - 1: 0] n,
    input logic [TDC_SIZE - 1:0] tdc_therm,
    input logic clk_out,

    // Outputs
    output logic [ERR_SIZE - 1:0] epu_out,
    output logic [ERR_SIZE - 1:0] therm_to_bin_out,
    output logic freq_locked,               // Lock Detection Signals
    output logic phase_locked
);


    logic signed [ERR_SIZE - 1:0] tdc_error; // output of Therm_To_Bin
    logic [7:0] freq;                 // output of Counter
    
    // Convert TDC output into binary   
    therm_to_bin #(.THERM_BITS(TDC_SIZE))
    THERM_TO_BIN(.thermometer_code(tdc_therm), .binary_representation(tdc_error));
    assign therm_to_bin_out = tdc_error;

    // Frequency counter
    counter COUNTER(.clk_ref(clk_ref), .n_rst(n_rst), .enable(enable), .clk_out(clk_out), .count(freq));


    // Frequency Locking States
    typedef enum logic [1:0] {RESET, F_LOCKED, F_SLOW, F_FAST} freq_mode;
    freq_mode f_mode, next_f_mode;


    // Count to 1000 max
    logic [9:0] freq_locked_count, next_freq_locked_count;
    logic [9:0] phase_locked_count, next_phase_locked_count;

    logic signed [ERR_SIZE - 1:0] next_epu_out;


    always_comb begin

        next_f_mode = f_mode;
        next_epu_out = epu_out;

        // Current Frequency is within +/- 1 MHz from Desired Frequency (n)
        if (freq >= (n - freq_lock_range) && freq <= (n + freq_lock_range)) begin
            next_f_mode = F_LOCKED;
            next_epu_out = tdc_error;
        end
        // Current Frequency is below Desired Frequency (n)
        else if (freq < n) begin
            next_f_mode = F_SLOW;
            next_epu_out =  8'sd127;
        end

        // Current Frequency is above Desired Frequency (n)
        else begin
            next_f_mode = F_FAST;
            next_epu_out = -8'sd128;
        end


        // freq_locked = 1 when last 1000 cycles are Frequency Locked.
        // phase_locked = 1 when last 1000 cycles are Frequency Locked AND abs(TDC Error) <= 50.
        if (next_f_mode == F_LOCKED && f_mode == F_LOCKED) begin

            // Frequency Locking
            if (freq_locked_count == 1000) begin
                next_freq_locked_count = 1000;
            end
            else begin
                next_freq_locked_count = freq_locked_count + 1;
            end


            // Phase Locking
            if (tdc_error >= -10 && tdc_error <= 10) begin
                if (phase_locked_count == 1000) begin
                    next_phase_locked_count = 1000;
                end

                else begin
                next_phase_locked_count = phase_locked_count + 1;
                end
            end
            // NOT PHASE LOCKED, SO RESET COUNT
            else begin
                next_phase_locked_count = 0;
            end


        end

        // NOT FREQUENCY LOCKED, SO RESET BOTH COUNTS
        else begin 
            next_freq_locked_count = 0;
            next_phase_locked_count = 0;
        end

    end


    always_ff @ (posedge clk_ref, negedge n_rst) begin
        if (!n_rst) begin
            f_mode <= RESET;
            epu_out <= 0;
            freq_locked_count <= 0;
            phase_locked_count <= 0;
        end
        else begin
            f_mode <= next_f_mode;
            epu_out <= next_epu_out;
            freq_locked_count <= next_freq_locked_count;
            phase_locked_count <= next_phase_locked_count;
        end
    end


    assign freq_locked = freq_locked_count == 1000? 1: 0;
    assign phase_locked = phase_locked_count == 1000? 1: 0;


endmodule
