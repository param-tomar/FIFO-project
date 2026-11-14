`timescale 1ns/1ps
//this will act as a self testing testbench 
module fifo_tb;
    parameter DW = 8;
    parameter DEPTH = 16;
    
    reg wr_en = 0 , r_en = 0;  //inputs are registered as reg so testbench can use and modify their value
    reg rst = 1,clk = 0;
    reg [DW-1:0] din=0;
    wire [DW-1:0] dout; 
    wire full,empty;
//instantiation starts
fifo #(                            
  .DW(DW),.DEPTH(DEPTH)) dut(                 //device under test(dut)
  .clk(clk),.rst(rst),.wr_en(wr_en)
  ,.r_en(r_en),.din(din),.dout(dout)
  ,.full(full),.empty(empty) 
  );

always #5 clk = ~clk; //the loop continues and the clock keeps changing its value, every 5 sec

//------------REFERENCE MODEL---------
reg [DW-1:0] model [0:DEPTH-1];
integer m_wr = 0, m_rd = 0, m_cnt = 0;
reg do_wr, do_r;
reg [DW-1:0] exp_dout;
integer errors = 0, checks = 0;

always @(posedge clk) begin
  if(!rst)  begin
    do_wr = wr_en && (m_cnt < DEPTH);
    do_r = r_en && (m_cnt > 0);
    if (do_r) begin
      exp_dout = model[m_rd];
      m_rd = (m_rd + 1) % DEPTH; //wrapping the pointer back to 0 when it reaches the end of the memory.
    end
    if (do_wr) begin
       model[m_wr] = din;
       m_wr = (m_wr + 1) % DEPTH;
    end
    m_cnt = m_cnt + do_wr - do_r; //manages he fifo as if [(read only)->decrease by 1 : (write only) -> increase by 1]

    #2; //lets the dut nonblocking updates to settle and compare checks = checks + 1;
    if (full !== (m_cnt == DEPTH)) begin
      errors = errors + 1;
      $display("FAIL @%0t: full=%b expected %b (model count=%0d)",
$time, empty, (m_cnt == 0), m_cnt);
    end
    if (empty !== (m_cnt == 0)) begin
      errors  =  errors + 1;
      $display("FAIL @%0t: empty=%b expected %b (model count=%0d)",
$time, empty, (m_cnt == 0), m_cnt);
    end
    if (do_r && (dout !== exp_dout)) begin
      errors =  errors + 1;
      $display("FAIL @%0t: dout=%d expected %0d", $time, dout, exp_dout);
    end
 end
end

//---------stimulus helpers-----------
task cycle; begin @(posedge clk); #1; end endtask

task write_n(input integer n, input integer start);
  integer k;
  begin
    for(k=0; k<n ; k=k+1) begin
      wr_en = 1; r_en = 0; din = start + k; cycle;
    end
    wr_en = 0;
  end
endtask

task read_n(input integer n);
  integer k;
  begin
    for (k=0; k<n ; k=k+1) begin
      r_en = 1; wr_en = 0; cycle;
    end
    r_en = 0; cycle; //ideal cycle, so that last reads daat is checked
  end
endtask

integer i;
initial begin
  $dumpfile("fifo.vcd");
  $dumpvars(0, fifo_tb);
  
  //1. reset
  rst = 1; #22; rst = 0; cycle;
  if(!empty || full) 
  begin 
    errors =  errors + 1;
    $display("FAIL: FLAGs wrong after reset");
  end
  
  //2. fill to full and then try to overflow it
  write_n(DEPTH, 1);
  write_n(4, 100); //wil be ignored
  
  //3. drain to empty and then underflow 
  read_n(DEPTH);
  read_n(3); // will not be read
  
  //4. simultaneous read+write, FIFO empty ( only the write may happen)
  wr_en = 1; r_en = 1; din = 55; cycle; wr_en = 0; r_en = 0; cycle;
  read_n(1);
  
  //5. simultaneous read+write at midlevel, sustained 
  write_n(DEPTH/2, 10);
  for ( i = 0; i < 100; i = i+1) begin
    wr_en = 1; r_en = 1; din = 200 + i; cycle;
  end
  wr_en = 0; r_en = 0; cycle;
  
  //6. simultaneous read+write at full (only the read happens)
  write_n(DEPTH, 1); //fill it up to full
  wr_en = 1; r_en = 1; din = 77; cycle; wr_en = 0; r_en = 0; cycle;
  read_n(DEPTH + 2);
  
  //7. random traffic
  for(i = 0; i<20000; i=i+1) begin
    wr_en = $random; r_en = $random; din = $random; cycle;
  end
  wr_en = 0; r_en = 0; cycle; cycle;
  
  
  $display("------------------------------");
  $display("checks=%0d errors=%0d", checks, errors);
  if(errors == 0) $display ("PASS");
  else $display ("FAIL");
  $finish;
 end
endmodule
  