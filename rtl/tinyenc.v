module tinyenc 
#(
  parameter        SHL   =  4, 
  parameter        SHR   =  5 
)
(
   input     [15:0] delta, 
   input     [ 2:0] round, 
   input     [63:0] key, 
  output            valid,
  output reg [31:0] rdata, 
   input     [31:0] wdata, 
   input            write,
   input            clk, rstb 
);

reg [7:0] i;
assign valid = i == 8'd0;
wire [7:0] i_next = i - 8'd1;
wire valid_next = i_next == 8'd0;
wire [15:0] k0, k1, k2, k3;
reg [15:0] x, y, sum;
wire [ 7:0] ROUND = 1<<round; 
always@(negedge rstb or posedge clk) begin
  if(~rstb) begin
    i <= 8'd0;
  end
  else begin
    if(valid) begin
      if(write) begin
        i <= ROUND;
        sum = 16'd0;
        x = wdata[15: 0];
        y = wdata[31:16];
      end
    end
    else begin
      i <= i_next;
      sum = sum + delta;
      x = x + (((y<<SHL) + k0) ^ (y + sum) ^ ((y>>SHR) + k1));
      y = y + (((x<<SHL) + k2) ^ (x + sum) ^ ((x>>SHR) + k3));
    end
    if(valid_next) begin
      rdata[15: 0] <= x;
      rdata[31:16] <= y;
    end
  end
end
assign {k3,k2,k1,k0} = key;

endmodule
