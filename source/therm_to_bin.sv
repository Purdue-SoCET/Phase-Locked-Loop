`timescale 1ns/1ps

module therm_to_bin #(
    parameter THERM_BITS = 255
)
(
    input logic [THERM_BITS-1:0] thermometer_code,
    output logic [$clog2(THERM_BITS + 1)-1 : 0] binary_representation
);

    always_comb begin
        integer i;
        //binary_representation = -8'sd128;
        binary_representation = 8'sd127;

        for (i = 0; i < THERM_BITS; i = i + 1) begin
            if (i == 0 && thermometer_code[i] == 0 && thermometer_code > 1) begin
                binary_representation = {($clog2(THERM_BITS + 1)-1){1'b1}};
            end

            if(thermometer_code[i])
                binary_representation = binary_representation - 1;
            else begin
                binary_representation = binary_representation;
                break;
            end
        end
    end
endmodule
