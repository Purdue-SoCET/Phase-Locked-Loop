module  tb_ahb_subordinate;

    logic h_clk;
    logic h_reset;

    parameter [31:0] BASE_ADDR='h8000_0000;
    bit [31:0] wdata;
    int latency;
    always #5 h_clk=!h_clk;

    ahb_if tb_ahb_if(h_clk,h_reset);
    bus_protocol_if tb_bus_if();

    // DUT instantiation
    ahb_subordinate ahb_sub(
        .ahb_if(tb_ahb_if),
        .bus_if(tb_bus_if)
    );


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

        // Additional existing test cases
        // ...

        #100000 $finish;
    end

    initial begin
        $vcdplusfile("ahb_sub.vpd");
        $vcdpluson(0, tb_ahb_subordinate);
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



endmodule