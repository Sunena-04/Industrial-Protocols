`timescale 1ns/1ps
module apb_ram_tb;
    // Testbench Signals
    reg         pclk;
    reg         presetn;
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg [31:0]  paddr;
    reg [31:0]  pwdata;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;
    // Instantiate DUT
    apb_ram DUT (
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)
    );
    // Clock Generation
    initial
        pclk = 0;
    always #5 pclk = ~pclk;
    // Write Task
    task apb_write;
        input [31:0] address;
        input [31:0] data;
    begin
        @(posedge pclk);
        psel    = 1;
        penable = 0;
        pwrite  = 1;
        paddr   = address;
        pwdata  = data;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        psel    = 0;
        penable = 0;
        pwrite  = 0;
    end
    endtask
    // Read Task
    task apb_read;
        input [31:0] address;
    begin
        @(posedge pclk);
        psel    = 1;
        penable = 0;
        pwrite  = 0;
        paddr   = address;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        $display("Time=%0t  Address=%0d  Data=%h  Ready=%b  Error=%b",
                  $time, address, prdata, pready, pslverr);
        psel    = 0;
        penable = 0;
    end
    endtask
    initial
    begin
			$dumpfile("dump.vcd");
      $dumpvars(0, apb_ram_tb);
        presetn = 0;
        psel    = 0;
        penable = 0;
        pwrite  = 0;
        paddr   = 0;
        pwdata  = 0;
        // Reset
        #20;
        presetn = 1;
        // Test Case 1
        // Write Register 0
        apb_write(0, 32'h12345678);
        // Test Case 2
        // Read Register 0
        apb_read(0);
        // Test Case 3
        // Write Register 5
        apb_write(5, 32'hABCDEF12);
        // Test Case 4
        // Read Register 5
        apb_read(5);
        // Test Case 5
        // Write Register 15
        apb_write(15, 32'h55AA55AA);
        // Test Case 6
        // Read Register 15
        apb_read(15);
        // Test Case 7
        // Invalid Address
        apb_read(40);
        #30;
        $finish;
    end
endmodule