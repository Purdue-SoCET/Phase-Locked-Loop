// module counter(
//     input logic clk_ref, n_rst, enable,
//     input logic clk_out,
//     output logic [7:0] count // This will output the count difference
// );

// logic [7:0] internal_count; // Internal counter for clk_out edges
// logic [7:0] count_at_last_ref; // Latch to store count at last clk_ref edge

// // Increment internal_count on every posedge of clk_out, reset on n_rst
// always_ff @(posedge clk_out or negedge n_rst) begin
//     if (!n_rst)
//         internal_count <= 0;
//     else if (enable)
//         internal_count <= internal_count + 1;

// end


// always_ff @(posedge clk_ref or negedge n_rst) begin
//     if (!n_rst) begin
//         count_at_last_ref <= 0;
//         count <= 0; 
//     end else if (enable) begin
//         count <= internal_count - count_at_last_ref; // Calculate and update the count difference
//         count_at_last_ref <= internal_count; // Latch the current internal count
//     end

// end

// endmodule



// module counter(
//     input logic clk_ref, n_rst, enable,
//     input logic clk_out,
//     output logic [7:0] count // This will output the count difference
// );

// logic [7:0] internal_count; // Internal counter for clk_out edges
// logic reset_internal_count; // Control signal to reset internal_count

// // Increment internal_count on every posedge of clk_out, reset on n_rst or reset_internal_count
// always_ff @(posedge clk_out or negedge n_rst) begin
//     if (!n_rst)
//         internal_count <= 0;
//     else if (reset_internal_count)
//         internal_count <= 0; // Reset internal_count when control signal is high
//     else if (enable)
//         internal_count <= internal_count + 1;
// end

// // Control logic for reset_internal_count and count output
// always_ff @(posedge clk_ref or negedge n_rst) begin
//     if (!n_rst) begin
//         reset_internal_count <= 0;
//         count <= 0; 
//     end else if (enable) begin
//         count <= internal_count; // Update the count with the current internal count
//         reset_internal_count <= 1; // Set the control signal to reset internal_count
//     end else
//         reset_internal_count <= 0; // Clear the reset control signal
// end

// endmodule


module counter(
    input logic clk_ref, n_rst, enable,
    input logic clk_out,
    output logic [7:0] count
);

logic [7:0] internal_count; // Internal counter for clk_out edges
logic reset_pulse; // One-cycle pulse to reset internal_count

// Generate a one-cycle pulse on posedge of clk_ref
always_ff @(posedge clk_out or negedge n_rst) begin
    if (!n_rst)
        reset_pulse <= 0;
    else if (count == internal_count) begin
        if (clk_ref)
            reset_pulse <= 1;
        else
            reset_pulse <= 0;
    end
    else
        reset_pulse <= 0;
end

// Increment internal_count on every posedge of clk_out, reset on the pulse
always_ff @(posedge clk_out or negedge n_rst) begin
    if (!n_rst)
        internal_count <= 0;
    else if (reset_pulse)
        internal_count <= 2; // Reset internal_count on the pulse
    else if (enable)
        internal_count <= internal_count + 1;
end

// Update count at posedge of clk_ref
always_ff @(posedge clk_ref or negedge n_rst) begin
    if (!n_rst) begin
        count <= 0; 
    end else if (enable) begin
        count <= internal_count; // Update the count with the current internal count
    end
end

endmodule
