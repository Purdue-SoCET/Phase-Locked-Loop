// Model of Ideal oscillator

`timescale 1ns / 1fs
module osc
    #(
        //parameter gainFine = 0.041, // gigahertz per Volt
        parameter gainFine = 0.027778, 
        parameter centerFreq = 0.075, // Frequency in gigahertz
        parameter VMAX = 1.8,
        parameter filtTs = 10,
        parameter numBits = 5
    )
    (
        output reg OSC,
        input [4:0] DFINE
    );

    real AFINE [2:0];

    int i;
    
    always @ (DFINE) begin
        AFINE[0] = VMAX * real'(DFINE)/32.0;
    end

    real B0, B1, B2;
    real A0, A1, A2;

    //Filter Model
    real AFILTER [2:0];
    initial begin
        AFILTER[0] = 0.9;
        AFILTER[1] = 0.9;
        AFILTER[2] = 0.9;
        AFINE[1] = 0.9;
        AFINE[2] = 0.9;
        B0 = 0.0000098259168204820;
        B1 = 0.0000196518336409640;
        B2 = 0.0000098259168204820;
        A0 = 1.0;
        A1 = -1.991114292201654;
        A2 = 0.991153595868935;
    end

    always begin
        AFINE[2] = AFINE[1];
        AFINE[1] = AFINE[0];
        AFILTER[2] = AFILTER[1];
        AFILTER[1] = AFILTER[0];
        AFILTER[0] = B0 * AFINE[0] + B1 * AFINE[1] + B2 * AFINE[2] - A1 * AFILTER[1] - A2 * AFILTER[2];
        #(filtTs);
    end




    real controlMax = 2**numBits - 1;
    real controlZero = (2 ** numBits) / 2;


    real fosc;

    always begin
        OSC = 1'b0;
        fosc = centerFreq + gainFine * (AFILTER[0] - VMAX / 2.0);
        #(1/(2*fosc));
        OSC = 1'b1;
        fosc = centerFreq + gainFine * (AFILTER[0] - VMAX / 2.0);
        #(1/(2*fosc));
    end


endmodule