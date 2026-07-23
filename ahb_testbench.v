`timescale 1ns/1ps
module ahb_slave_tb;
    reg hclk;
    reg hresetn;
    reg hsel;
    reg [31:0] haddr;
    reg [1:0] htrans;
    reg hwrite;
    reg [2:0] hsize;
    reg [31:0] hwdata;
    reg hready;
    wire [31:0] hrdata;
    wire hreadyout;
    wire hresp;
ahb_slave DUT(
  .hclk(hclk),
  .hresetn(hresetn),
  .hsel(hsel),
  .haddr(haddr),
  .htrans(htrans),
  .hwrite(hwrite),
  .hsize(hsize),
  .hwdata(hwdata),
  .hready(hready),
  .hrdata(hrdata),
  .hreadyout(hreadyout),
  .hresp(hresp)
);
initial
  hclk = 0;
always #5 hclk = ~hclk;
task ahb_write;
input [31:0] address;
input [31:0] data;
begin
    @(posedge hclk);
    hsel = 1;
    hready = 1;
    htrans = 2'b10;
    hwrite = 1;
    haddr = address;
    hwdata = data;
    @(posedge hclk);
    hsel = 0;
    hwrite = 0;
    end
    endtask
    task ahb_read;
    input [31:0] address;
    begin
    @(posedge hclk);
    hsel = 1;
    hready = 1;
    htrans = 2'b10;
    hwrite = 0;
    haddr = address;
    @(posedge hclk);
    $display("Time=%0t Address=%0d Data=%h Ready=%b Resp=%b",
    $time,haddr,hrdata,hreadyout,hresp);
    hsel = 0;
    end
    endtask
    initial
    begin
      $dumpfile("dump.vcd");
      $dumpvars(0,ahb_slave_tb);
    hresetn = 0;
    hsel = 0;
    haddr = 0;
    htrans = 2'b00;
    hwrite = 0;
    hsize = 3'b010;
    hwdata = 0;
    hready = 1;
    #20;
    hresetn = 1;
    ahb_write(0,32'h12345678);
    ahb_read(0);
    ahb_write(8,32'hABCDEF12);
    ahb_read(8);
    ahb_write(15,32'h55AA55AA);
    ahb_read(15);
    ahb_read(40);
    #20;
    $finish;
    end
endmodule