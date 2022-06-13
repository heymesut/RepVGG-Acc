
`ifndef SIM
module sram_top
#(
  parameter DW = 64,
  parameter MW = 8,
  parameter AW = 12   
  ) (
  input   clk,
  input   cs,
  input   we,
  input  [MW-1:0]   wem,
  input  [AW-1:0]   addr,
  input  [DW-1:0]   din,
  output [DW-1:0]   dout  
  );
  wire ceny;
  wire weny;
  wire [1:0] so;
  wire [AW-1:0] ay;
  wire  wen;

  assign wen = (cs & we);  
   
  sram_4kx64 sram_4kx64_u1(
   .CENY(ceny), 
   .WENY(weny), 
   .AY(ay), 
   .Q(dout), 
   .SO(so), 
   .CLK(clk), 
   .CEN(~cs), 
   .WEN(wen), 
   .A(addr), 
   .D(din), 
   .EMA(3'b010), 
   .EMAW(2'b00), 
   .TEN(1'b1),
   .TCEN(1'b1), 
   .TWEN(1'b1), 
   .TA(addr), 
   .TD(din),  
   .RET1N(1'b1), 
   .SI(2'b00), 
   .SE(1'b0), 
   .DFTRAMBYP(1'b0)  
   );
 
endmodule  


`endif

