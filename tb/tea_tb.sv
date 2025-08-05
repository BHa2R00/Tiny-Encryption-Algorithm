`ifdef SIM
`timescale 1ns/1ps
module tea_tb;

wire           plain_ack;
wire    [31:0] plain;
wire           cipher_ack;
wire    [31:0] cipher;
reg     [31:0] text;
reg            text_req;
reg            clk;

reg     [31:0] pwdata;
reg            pwrite;
reg     [31:0] paddr;
reg            psel, penable;
reg            prstb, pclk;

tinyenc u_cipher (
  .ack(cipher_ack),
  .rdata(cipher), 
  .wdata(text), 
  .req(text_req),
  .clk(clk),
  .pwdata(pwdata), 
  .pwrite(pwrite), 
  .paddr(paddr), 
  .psel(psel), .penable(penable), 
  .prstb(prstb), .pclk(pclk)
);

tinydec u_plain (
  .ack(plain_ack),
  .rdata(plain), 
  .wdata(cipher), 
  .req(text_req),
  .clk(clk),
  .pwdata(pwdata), 
  .pwrite(pwrite), 
  .paddr(paddr), 
  .psel(psel), .penable(penable), 
  .prstb(prstb), .pclk(pclk)
);

initial pclk = 0;
always #10 pclk = ~pclk;

initial clk = 0;
always #1 clk = ~clk;

always@(negedge prstb or posedge pclk) begin
  if(~prstb) begin
    text_req <= 1'b0;
  end
  else begin
    text_req <= cipher_ack;
    if(&{~text_req,cipher_ack}) begin
      text[ 7: 0] <= $urandom_range("A","z");
      text[15: 8] <= $urandom_range("A","z");
      text[23:16] <= $urandom_range("A","z");
      text[31:24] <= $urandom_range("A","z");
    end
  end
end

reg pass;
reg [31:0] text_d, plain_d;
always@(posedge text_req) 
begin
@(posedge pclk);
text_d = text;
@(posedge cipher_ack);
@(posedge plain_ack);
@(posedge pclk);
plain_d = plain;
if(text_d != plain_d) begin
  pass = 0;
  $write("%s != %s\n", text_d, plain_d);
end
end

initial begin
`ifdef FST
$dumpfile("tea_tb.fst");
$dumpvars(0,tea_tb);
`endif
`ifdef FSDB
$fsdbDumpfile("tea_tb.fsdb");
$fsdbDumpvars(0,tea_tb);
`endif
prstb = 0;
pwrite = 0;
psel = 0;
penable = 0;
pass = 1;
repeat(3) begin
  repeat(3) @(posedge pclk); prstb = 1;
  repeat(333) @(posedge clk);
  repeat(3) @(posedge pclk); prstb = 0;
end
if(pass) $write("PASS\n");
$finish;
end

endmodule
`endif
