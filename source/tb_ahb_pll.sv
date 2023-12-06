`timescale 1ns/1ps

module  tb_ahb_pll;



    localparam CLK_PERIOD = 1000;

    logic h_clk;
    logic h_reset;

    parameter [31:0] BASE_ADDR='h8000_0000;
    bit [31:0] wdata;
    int latency;
    always #5 h_clk=!h_clk;

   logic tb_clk_ref;
   logic tb_clk_out;

    ahb_if tb_ahb_if(h_clk,h_reset);
    bus_protocol_if tb_bus_if();

    // DUT instantiation
    ahb_pll dut_ahb_pll(
        .ahb_if(tb_ahb_if),
        .bus_if(tb_bus_if),
        .clk_ref(tb_clk_ref),
        .clk_out(tb_clk_out)
    );




always begin
  // Start with clock low to avoid false rising edge events at t=0
  tb_clk_ref= 1'b0;
  // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
  tb_clk_ref = 1'b1;
  // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
end




     initial begin
        // Initializing the various ports
        h_clk = 0;
        latency = 0;
        tb_ahb_if.HWSTRB = 4'b1111;
        tb_ahb_if.HSEL = 1'b1;
        tb_ahb_if.HWRITE = 1'b0;
        tb_ahb_if.HTRANS = 'd0;
        tb_ahb_if.HBURST = 'd0;
        tb_ahb_if.HWDATA = 'd0;
        tb_ahb_if.HADDR = 'h8000_0000;
        tb_ahb_if.HSIZE = 3'b000;
        tb_bus_if.request_stall = 0;

        // Performing the reset routine
        h_reset = 0;
        #10;
        h_reset = 1;

        // Test Case: Write to kp_reg
        @(posedge tb_ahb_if.HCLK);
        write(0, 16'h0100); // Write to kp_reg at offset 0 with data 0x1234
        write(1,16'h0008);
        write(2,8'd72);
        write(3,1'd1);

        idle();



    forever begin
        calculateAndDisplayFrequency();
    end

        // Additional existing test cases
        // ...

        #100000 $finish;
    end





  // Allowing write to happen multiple times because there is no output from
  // this operation
    task write(input int offset, input [31:0] data);
    begin
        tb_ahb_if.HWRITE = 1'b1;
        tb_ahb_if.HADDR = BASE_ADDR + offset * 4;
        tb_ahb_if.HTRANS = 2'b10; // NON-SEQ
        tb_ahb_if.HBURST = 3'b000;
        tb_ahb_if.HSIZE = 3'b010; // 32bit
        @(posedge tb_ahb_if.HCLK);
        tb_ahb_if.HWDATA = data;
        // Wait for one more clock cycle to complete the write
        @(posedge tb_ahb_if.HCLK);
    end
    endtask

    // Idle transaction
    task idle();
        begin
            //@(posedge tb_ahb_if.HCLK);
            tb_ahb_if.HTRANS = 2'b00;
            @(posedge tb_ahb_if.HCLK);
        end
    endtask



    // Allowing only one read transaction per task call because there is an output
    // from this operation.
    task read(input int addr_offset /*,output rdata*/);
        begin
            tb_ahb_if.HWRITE = 1'b0;
            tb_ahb_if.HADDR = BASE_ADDR + addr_offset;
            tb_ahb_if.HTRANS = 2'b10; //NON-SEQ
            tb_ahb_if.HBURST = 3'b000;
            tb_ahb_if.HSIZE = 3'b010;//32bit
        end
    endtask


    task burst_write();
        begin
            int i;
            bit [31:0] wdata;
            wdata=$urandom();
            tb_ahb_if.HWRITE = 1'b1;
            tb_ahb_if.HADDR = BASE_ADDR;
            tb_ahb_if.HTRANS = 2'b10; //NON-SEQ
            tb_ahb_if.HBURST = 3'b011; //Incrementing 4
            tb_ahb_if.HSIZE = 3'b010;//32bit
              //@(posedge tb_ahb_if.HCLK);
              //tb_ahb_if.HWDATA = wdata;
            for (i=0; i < 3; i++) begin
                wdata=$urandom();
                @(posedge tb_ahb_if.HCLK)
                tb_ahb_if.HWDATA = wdata;
                tb_ahb_if.HWRITE = 1'b1;
                tb_ahb_if.HADDR = BASE_ADDR + (i+1)*4;
                tb_ahb_if.HTRANS = 2'b11; //SEQ
                tb_ahb_if.HBURST = 3'b011;
                tb_ahb_if.HSIZE = 3'b010;//32bit
            end
            wdata=$urandom();
            @(posedge tb_ahb_if.HCLK);
            tb_ahb_if.HWDATA = wdata;
        end

    endtask

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


endmodule
















