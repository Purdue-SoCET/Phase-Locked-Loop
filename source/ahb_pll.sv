
module ahb_pll #(

) (
    ahb_if.subordinate ahb_if,
    bus_protocol_if.protocol bus_if,
    input logic clk_ref,
    output logic clk_out
);




logic [15:0] kp, ki; // 16-bit registers for kp and ki
logic [7:0] n;// 8-bit register for n
logic enable; // Enable signal for PLL



    ahb_subordinate _ahb_sub(
        .ahb_if(ahb_if),
        .bus_if(bus_if),
        .kp_reg(kp),
        .ki_reg(ki),
        .n_reg(n),
        .pll_enable(enable)
    );



pll _pll(.clk_ref(clk_ref), .n_rst(ahb_if.HRESETn), .enable(enable), .kp(kp), .ki(ki), .n(n), .clk_out(tb_clk_out));



endmodule


