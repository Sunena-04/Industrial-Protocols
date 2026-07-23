module apb_ram (
    input               pclk,
    input               presetn,
    input               psel,
    input               penable,
    input               pwrite,
    input      [31:0]   paddr,
    input      [31:0]   pwdata,

    output reg [31:0]   prdata,
    output reg          pready,
    output reg          pslverr
);
    // Memory Declaration
    reg [31:0] memory [0:31];
    // State Declaration
    localparam IDLE   = 2'b00,
               SETUP  = 2'b01,
               ACCESS = 2'b10;
    reg [1:0] current_state;
    integer i;
    // APB State Machine
    always @(posedge pclk or negedge presetn)
    begin
        if (!presetn)
        begin
            current_state <= IDLE;
            prdata         <= 32'd0;
            pready         <= 1'b0;
            pslverr        <= 1'b0;
            for(i=0;i<32;i=i+1)
                memory[i] <= 32'd0;
        end
        else
        begin
            case(current_state)
            // IDLE STATE
            IDLE:
            begin
                pready  <= 1'b0;
                pslverr <= 1'b0;
                if(psel)
                    current_state <= SETUP;
            end
            // SETUP STATE
            SETUP:
            begin
                if(penable)
                    current_state <= ACCESS;
            end
            // ACCESS STATE
            ACCESS:
            begin
                pready <= 1'b1;
                if(paddr < 32)
                begin
                    if(pwrite)
                    begin
                        memory[paddr] <= pwdata;
                    end
                    else
                    begin
                        prdata <= memory[paddr];
                    end
                    pslverr <= 1'b0;
                end
                else
                begin
                    prdata  <= 32'd0;
                    pslverr <= 1'b1;
                end
                current_state <= IDLE;
            end
            // DEFAULT
            default:
            begin
                current_state <= IDLE;
            end
            endcase
        end
    end
endmodule