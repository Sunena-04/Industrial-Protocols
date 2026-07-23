module ahb_slave(
    input hclk,
    input hresetn,
    input hsel,
    input [31:0] haddr,
    input [1:0] htrans,
    input hwrite,
    input [2:0] hsize,
    input [31:0] hwdata,
    input hready,
    output reg [31:0] hrdata,
    output reg hreadyout,
    output reg hresp
);
reg [31:0] memory [0:31];
integer i;
always @(posedge hclk or negedge hresetn)
begin
    if(!hresetn)
    begin
        hreadyout <= 1'b1;
        hresp <= 1'b0;
        hrdata <= 32'd0;
        for(i=0;i<32;i=i+1)
            memory[i] <= 32'd0;
    end
    else
    begin
        hreadyout <= 1'b1;
        hresp <= 1'b0;
        if(hsel && hready && htrans[1])
        begin
            if(haddr < 32)
            begin
                if(hwrite)
                begin
                    memory[haddr] <= hwdata;
                end
                else
                begin
                    hrdata <= memory[haddr];
                end
            end
            else
            begin
                hrdata <= 32'd0;
                hresp <= 1'b1;
            end
        end
    end
end
endmodule