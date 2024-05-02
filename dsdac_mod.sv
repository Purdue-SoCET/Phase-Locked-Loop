// Courtesy of Sutton Hathorn 
module dsdac_mod
	#(
		parameter DIN_W = 16,
		parameter DOUT_BITS = 5,
		parameter DOUT_W = 2**DOUT_BITS
	)
	(
		input logic VDD,
		input logic VSS,
		input logic clk_ref,
		input logic n_rst,
		input logic enable,
		input logic [DIN_W-1:0] din,
		input logic [DOUT_BITS-1:0] out_set,
		
		output logic [DOUT_BITS-1:0] mod_out,
		output logic signed [DIN_W-DOUT_BITS:0] mod_err,
		output logic [DOUT_W-1:0] dout,
		output logic [DOUT_W-1:0] dout_neg
	);

	localparam DOUT_RESET = {{(DOUT_W/2){1'b0}} , 1'b1, {(DOUT_W/2 -1){1'b0}}};
	localparam W_QUANT = DIN_W-DOUT_BITS+1; //Add sign bit
	localparam QUANT_THRESH = 2**(W_QUANT-1);


	logic signed [W_QUANT-1:0] accum;
	logic [DOUT_W-1:0] dout_next;
	logic signed [W_QUANT-1:0] accum_next;
	logic signed [W_QUANT:0] quant_in;
	logic quant_out;
	logic [DOUT_BITS-1:0] tw;
	logic [DOUT_BITS-1:0] din_int;
	logic signed [W_QUANT-1:0] din_frac;

	assign din_int = din[DIN_W-1:W_QUANT-1];
	assign din_frac = $signed({1'b0,din[W_QUANT-2:0]});

	integer i;

	always_comb begin
		if(enable == 1'b1) begin
			quant_in = din_frac + accum;
			quant_out = (quant_in >= QUANT_THRESH) ? 1'b1 : 1'b0;
			accum_next = {1'b0, quant_in[(DIN_W - DOUT_BITS-1):0]};
			tw = (&din_int) ? (DOUT_W-1) : din_int + quant_out;
		end else begin
			quant_in = 0;
			quant_out = 0;
			accum_next = accum;
			tw = out_set;
		end
		for(i=0; i< DOUT_W; i=i+1) begin
			if(tw == i) begin
				dout_next[i] = 1'b1;
			end else begin
				dout_next[i] = 1'b0;
			end
		end
	end

	always_ff @ (posedge clk_ref, negedge n_rst) begin
		if(n_rst == 1'b0) begin
			dout <= DOUT_RESET;
			dout_neg <= ~DOUT_RESET;
			accum <= 0;
		end else begin
			dout <= dout_next;
			dout_neg <= ~dout_next;
			accum <= accum_next;
		end
	end

	assign mod_out = tw;
	assign mod_err = $signed({quant_out, din[W_QUANT-2:0]});

endmodule