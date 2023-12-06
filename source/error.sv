module error#(
    parameter ERR_SIZE = 8, 
    parameter N_SIZE = 8
)(
    input logic clk_ref, 
    input logic n_rst,
    input logic enable, 
    input logic [N_SIZE - 1: 0] n,
    input logic [7:0] count,
    input logic [ERR_SIZE - 1:0] tdc_error,
    output logic [ERR_SIZE - 1:0] lf_in
);

typedef enum logic [1:0] {RESET, F_LOCKED, F_SLOW, F_FAST} _mode;
_mode mode;

 always_ff @(posedge clk_ref, negedge n_rst) begin
    if (!n_rst) begin
        lf_in <= 0;
        mode <= RESET;
    end
    else if (enable) begin
        if (count >= (n - 2) && count <= (n + 2)) begin // frequency locked
            lf_in <=  tdc_error;
            mode <= F_LOCKED;
        end
        else if (count < n) begin // too slow, make faster
            lf_in <=  8'sd127;
            mode <= F_SLOW;
        end
        else begin // too fast, make slower
            lf_in <= -8'sd128;
            mode <= F_FAST;
        end
    end

end

endmodule
