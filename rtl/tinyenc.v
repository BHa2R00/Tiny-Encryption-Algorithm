module tinyenc 
#(
  parameter [63:0] KEY   = 64'h816fc52b09e74da3, 
  parameter [15:0] DELTA = 16'h9E37 
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
reg [4:0] i;
assign ack = i == 5'd0;
wire [4:0] i_next = i - 5'd1;
wire ack_next = i_next == 5'd0;
reg [15:0] x, y, k0, k1, k2, k3, sum, delta;
always@(negedge rstb or posedge clk) begin
  if(~rstb) begin
    psel_d <= 2'b00;
    i <= 5'd0;
  end
  else begin
    psel_d <= {psel_d[0],psel};
    if(~psel_d[1]) begin
      if(ack) begin
        if(req) begin
          i <= 5'd16;
          sum = 16'd0;
          x = wdata[15: 0];
          y = wdata[31:16];
        end
      end
      else begin
        i <= i_next;
        sum = sum + delta;
        x = x + (((y<<4) + k0) ^ (y + sum) ^ ((y>>5) + k1));
        y = y + (((x<<4) + k2) ^ (x + sum) ^ ((x>>5) + k3));
      end
      if(ack_next) begin
        rdata[15: 0] <= x;
        rdata[31:16] <= y;
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
