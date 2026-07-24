`timescale 1ns / 1ps

module tb_dma_axi_top;

    reg clk = 0;
    reg rst_n = 0;
    always #5 clk = ~clk;

    reg         dma_start;
    reg  [31:0] src_addr;
    reg  [31:0] dst_addr;
    reg  [31:0] transfer_size;
    wire        dma_done;
    wire        dma_error;

    dma_axi_top u_dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .dma_start    (dma_start),
        .src_addr     (src_addr),
        .dst_addr     (dst_addr),
        .transfer_size(transfer_size),
        .dma_done     (dma_done),
        .dma_error    (dma_error)
    );

    initial begin
        rst_n = 0;
        dma_start = 0;
        src_addr  = 32'd0;
        dst_addr  = 32'd128;
        transfer_size = 32'd64;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        $display("Starting DMA transfer: src=0, dst=128, size=64 bytes");
        dma_start = 1;
        @(posedge clk);
        dma_start = 0;

        wait (dma_done == 1);
        $display("[%t] DMA transfer completed. Error = %b", $time, 
                 dma_error);

        #100;
        $finish;
    end

    initial begin
        $monitor("Time=%t | start=%b | done=%b | error=%b | src=%h 
                 | dst=%h | size=%d",
                 $time, dma_start, dma_done, dma_error, src_addr, 
                 dst_addr, transfer_size);
    end

    initial begin
      $dumpfile("dump.vcd");
        $dumpvars(0, tb_dma_axi_top);
    end

endmodule