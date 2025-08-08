`ifdef SIM
`timescale 1ns/1ps
module tea_tb;

parameter        SHL   =  4;
parameter        SHR   =  5;

reg     [15:0] delta;
reg     [ 2:0] round;
reg     [63:0] key;
wire           plain_valid;
wire    [31:0] plain;
wire           cipher_valid;
wire    [31:0] cipher;
reg     [31:0] text;
reg            text_write;
reg            clk, rstb;

reg     [31:0] pwdata;
reg            pwrite;
reg     [31:0] paddr;
reg            psel, penable;
reg            prstb, pclk;

tinyenc #(
  .SHL(SHL),
  .SHR(SHR)
)
u_cipher (
  .delta(delta),
  .round(round),
  .key(key),
  .valid(cipher_valid),
  .rdata(cipher), 
  .wdata(text), 
  .write(text_write),
  .clk(clk), .rstb(rstb) 
);

tinydec #(
  .SHL(SHL),
  .SHR(SHR)
)
u_plain (
  .delta(delta),
  .round(round),
  .key(key),
  .valid(plain_valid),
  .rdata(plain), 
  .wdata(cipher), 
  .write(text_write),
  .clk(clk), .rstb(rstb) 
);

initial clk = 0;
always #1 clk = ~clk;

initial text_write = 0;
always@(posedge clk) text_write = plain_valid;
always@(posedge &{~text_write,plain_valid}) begin
  text[ 7: 0] <= $urandom_range("A","z");
  text[15: 8] <= $urandom_range("A","z");
  text[23:16] <= $urandom_range("A","z");
  text[31:24] <= $urandom_range("A","z");
end

reg pass;
reg [31:0] text_d, plain_d;
initial begin
`ifdef FST
$dumpfile("tea_tb.fst");
$dumpvars(0,tea_tb);
`endif
`ifdef FSDB
$fsdbDumpfile("tea_tb.fsdb");
$fsdbDumpvars(0,tea_tb);
`endif
rstb = 0;
pass = 1;
repeat(33) begin
  round = $urandom_range(0,7);
  key[31:00] = $urandom_range(0,'hffffffff);
  key[63:32] = $urandom_range(0,'hffffffff);
  delta = $urandom_range(0,'hffff);
  repeat(3) @(posedge clk); rstb = 1;
  repeat(33) begin
    @(posedge text_write) 
    text_d = text;
    @(posedge cipher_valid);
    @(posedge plain_valid);
    plain_d = plain;
    if(text_d != plain_d && rstb) begin
      pass = 0;
      $write("%s != %s\n", text_d, plain_d);
    end
  end
  repeat(3) @(posedge clk); rstb = 0;
end
if(pass) $write("PASS\n");
$finish;
end

endmodule
`endif
