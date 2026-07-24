//======================================================================
// Testbench for AXI DMA Controller
// Compatible with Verisim (and any Verilog simulator)
//======================================================================
`timescale 1ns / 1ps

module tb_dma_axi_top;

    //============================================
    // Parameters
    //============================================
    parameter CLK_PERIOD = 10;  // 100 MHz

    // AXI parameters (match your design)
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 64;
    parameter ID_WIDTH   = 4;

    //============================================
    // Clock & Reset
    //============================================
    reg clk = 0;
    always # (CLK_PERIOD/2) clk = ~clk;

    reg rst_n;
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
    end

    //============================================
    // DUT Signals (adjust names to match your top)
    //============================================
    // Control / status
    reg                  start;
    reg  [ADDR_WIDTH-1:0] src_addr;
    reg  [ADDR_WIDTH-1:0] dst_addr;
    reg  [15:0]          transfer_len;   // number of bytes or beats?
    wire                 done;
    wire                 error;

    // AXI Master interface (DMA -> external memory)
    // Write Address Channel
    wire [ID_WIDTH-1:0]   m_axi_awid;
    wire [ADDR_WIDTH-1:0] m_axi_awaddr;
    wire [7:0]            m_axi_awlen;
    wire [2:0]            m_axi_awsize;
    wire [1:0]            m_axi_awburst;
    wire                  m_axi_awvalid;
    wire                  m_axi_awready;

    // Write Data Channel
    wire [DATA_WIDTH-1:0] m_axi_wdata;
    wire [DATA_WIDTH/8-1:0] m_axi_wstrb;
    wire                  m_axi_wlast;
    wire                  m_axi_wvalid;
    wire                  m_axi_wready;

    // Write Response Channel
    wire [ID_WIDTH-1:0]   m_axi_bid;
    wire [1:0]            m_axi_bresp;
    wire                  m_axi_bvalid;
    wire                  m_axi_bready;

    // Read Address Channel
    wire [ID_WIDTH-1:0]   m_axi_arid;
    wire [ADDR_WIDTH-1:0] m_axi_araddr;
    wire [7:0]            m_axi_arlen;
    wire [2:0]            m_axi_arsize;
    wire [1:0]            m_axi_arburst;
    wire                  m_axi_arvalid;
    wire                  m_axi_arready;

    // Read Data Channel
    wire [ID_WIDTH-1:0]   m_axi_rid;
    wire [DATA_WIDTH-1:0] m_axi_rdata;
    wire [1:0]            m_axi_rresp;
    wire                  m_axi_rlast;
    wire                  m_axi_rvalid;
    wire                  m_axi_rready;

    //============================================
    // Instantiate the DUT
    //============================================
    // <-- ADJUST the module name and port connections
    //     to match your actual top module.
    dma_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH  (ID_WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),

        // Control inputs
        .start          (start),
        .src_addr       (src_addr),
        .dst_addr       (dst_addr),
        .transfer_len   (transfer_len),   // name may differ
        .done           (done),
        .error          (error),

        // AXI Master Write Address
        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awsize   (m_axi_awsize),
        .m_axi_awburst  (m_axi_awburst),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),

        // AXI Master Write Data
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),

        // AXI Master Write Response
        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),

        // AXI Master Read Address
        .m_axi_arid     (m_axi_arid),
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arlen    (m_axi_arlen),
        .m_axi_arsize   (m_axi_arsize),
        .m_axi_arburst  (m_axi_arburst),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),

        // AXI Master Read Data
        .m_axi_rid      (m_axi_rid),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rlast    (m_axi_rlast),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready)
    );

    //============================================
    // Simple AXI Slave Memory Model
    // (responds to reads/writes from the DMA)
    //============================================
    reg [DATA_WIDTH-1:0] mem [0:65535];   // 64KB memory

    // Write transaction handling
    reg [ID_WIDTH-1:0] awid_q;
    reg [ADDR_WIDTH-1:0] awaddr_q;
    reg [7:0] awlen_q;
    reg awvalid_q;
    reg [DATA_WIDTH-1:0] wdata_q;
    reg [DATA_WIDTH/8-1:0] wstrb_q;
    reg wlast_q;
    reg wvalid_q;
    integer wcnt;

    // Simple write FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awvalid_q <= 0;
            wvalid_q  <= 0;
            wcnt      <= 0;
            m_axi_awready <= 0;
            m_axi_wready  <= 0;
            m_axi_bvalid  <= 0;
            m_axi_bresp   <= 2'b00;
            m_axi_bid     <= 0;
        end else begin
            // Defaults
            m_axi_awready <= 0;
            m_axi_wready  <= 0;
            m_axi_bvalid  <= 0;

            // Accept write address
            if (m_axi_awvalid && !awvalid_q) begin
                awvalid_q <= 1;
                awaddr_q  <= m_axi_awaddr;
                awlen_q   <= m_axi_awlen;
                awid_q    <= m_axi_awid;
                m_axi_awready <= 1;
                wcnt <= 0;
            end

            // Accept write data
            if (m_axi_wvalid && m_axi_wready) begin
                // Store data
                mem[awaddr_q + (wcnt * (DATA_WIDTH/8))] <= m_axi_wdata;
                wcnt <= wcnt + 1;
                if (m_axi_wlast) begin
                    // Complete write burst
                    m_axi_bvalid <= 1;
                    m_axi_bresp  <= 2'b00;
                    m_axi_bid    <= awid_q;
                    awvalid_q <= 0;
                end
            end

            // Accept write response ready
            if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bvalid <= 0;
            end
        end
    end

    // Read transaction handling
    reg [ID_WIDTH-1:0] arid_q;
    reg [ADDR_WIDTH-1:0] araddr_q;
    reg [7:0] arlen_q;
    reg arvalid_q;
    integer rcnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arvalid_q <= 0;
            rcnt      <= 0;
            m_axi_arready <= 0;
            m_axi_rvalid  <= 0;
            m_axi_rlast   <= 0;
            m_axi_rdata   <= 0;
            m_axi_rresp   <= 2'b00;
            m_axi_rid     <= 0;
        end else begin
            m_axi_arready <= 0;
            m_axi_rvalid  <= 0;
            m_axi_rlast   <= 0;

            // Accept read address
            if (m_axi_arvalid && !arvalid_q) begin
                arvalid_q <= 1;
                araddr_q  <= m_axi_araddr;
                arlen_q   <= m_axi_arlen;
                arid_q    <= m_axi_arid;
                m_axi_arready <= 1;
                rcnt <= 0;
            end

            // Send read data
            if (arvalid_q) begin
                m_axi_rvalid <= 1;
                m_axi_rdata  <= mem[araddr_q + (rcnt * (DATA_WIDTH/8))];
                m_axi_rresp  <= 2'b00;
                m_axi_rid    <= arid_q;
                if (rcnt == arlen_q) begin
                    m_axi_rlast <= 1;
                    arvalid_q <= 0;
                end else begin
                    m_axi_rlast <= 0;
                end
                rcnt <= rcnt + 1;
            end

            // Wait for rready
            if (m_axi_rvalid && m_axi_rready) begin
                // data accepted, continue
            end
        end
    end

    //============================================
    // Test Sequence
    //============================================
    initial begin
        // Initialize control signals
        start        = 0;
        src_addr     = 32'h00000000;
        dst_addr     = 32'h00000100;
        transfer_len = 16'd16;   // 16 beats (adjust to match your design)

        // Wait for reset to finish
        @(negedge rst_n);
        @(posedge rst_n);
        repeat (5) @(posedge clk);

        // Write some initial data into source memory area
        for (int i = 0; i < 16; i++) begin
            mem[32'h00000000 + i*8] = i * 16'h0101;  // pattern
        end

        // Start the DMA transfer
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for completion
        wait (done == 1);
        $display("[%t] DMA transfer completed successfully!", $time);

        // Optional: verify destination memory
        $display("Verifying destination memory...");
        for (int i = 0; i < 16; i++) begin
            if (mem[32'h00000100 + i*8] !== i * 16'h0101) begin
                $display("Mismatch at address %h: expected %h, got %h",
                         32'h00000100 + i*8, i*16'h0101, mem[32'h00000100 + i*8]);
            end
        end
        $display("Verification done.");

        // End simulation
        #100;
        $finish;
    end

    //============================================
    // Monitor
    //============================================
    initial begin
        $monitor("[%t] done=%b, error=%b, src=%h, dst=%h, len=%d",
                 $time, done, error, src_addr, dst_addr, transfer_len);
    end

    // Dump waves (if supported by Verisim)
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_dma_axi_top);
    end

endmodule