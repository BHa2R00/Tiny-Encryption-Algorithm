module tinydec 
#(
  parameter [63:0] KEY   = 64'h816fc52b09e74da3, 
  parameter [15:0] DELTA = 16'h1, 
  parameter        SHL   =  4, 
  parameter        SHR   =  5, 
  parameter [ 7:0] ROUND =  8'd1 
)
(
  output            ack,
  output reg [31:0] rdata, 
   input     [31:0] wdata, 
   input            req,
   input            clk,
  // configure 
  output            pready, 
  output reg [31:0] prdata, 
   input     [31:0] pwdata, 
   input            pwrite, 
   input     [31:0] paddr, 
   input            psel, penable, 
   input            prstb, pclk
);

reg rstb;
always@(negedge prstb or posedge clk) if(~prstb) rstb <= 1'b0; else rstb <= 1'b1;
reg [1:0] psel_d;
reg [7:0] i;
assign ack = i == 8'd0;
wire [7:0] i_next = i - 8'd1;
wire ack_next = i_next == 8'd0;
reg [15:0] x, y, k0, k1, k2, k3, sum, delta;
always@(negedge rstb or posedge clk) begin
  if(~rstb) begin
    psel_d <= 2'b00;
    i <= 8'd0;
  end
  else begin
    psel_d <= {psel_d[0],psel};
    if(~psel_d[1]) begin
      if(ack) begin
        if(req) begin
          i <= ROUND;
          y = wdata[31:16];
          x = wdata[15: 0];
          sum = delta * ROUND;
        end
      end
      else begin
        i <= i_next;
        y = y - (((x<<SHL) + k2) ^ (x + sum) ^ ((x>>SHR) + k3));
        x = x - (((y<<SHL) + k0) ^ (y + sum) ^ ((y>>SHR) + k1));
        sum = sum - delta;
      end
      if(ack_next) begin
        rdata[31:16] <= y;
        rdata[15: 0] <= x;
      end
    end
  end
end
wire paddr_key10 = paddr == 'h0;
wire paddr_key32 = paddr == 'h4;
wire paddr_delta = paddr == 'h8;
always@(negedge prstb or posedge pclk) begin
  if(~prstb) begin
    {k3,k2,k1,k0} <= KEY;
    delta <= DELTA;
  end
  else if(psel) begin
    case(1'b1)
      paddr_key10 : begin
          prdata[15: 0] <= k0;
          prdata[31:16] <= k1;
        if(pwrite && penable) begin
          k0 <= pwdata[15: 0];
          k1 <= pwdata[31:16];
        end
      end
      paddr_key32 : begin
          prdata[15: 0] <= k2;
          prdata[31:16] <= k3;
        if(pwrite && penable) begin
          k2 <= pwdata[15: 0];
          k3 <= pwdata[31:16];
        end
      end
      paddr_delta : begin
          prdata[15: 0] <= delta;
        if(pwrite && penable) begin
          delta <= pwdata[15: 0];
        end
      end
    endcase
  end
end
assign pready = 1'b1;

endmodule
