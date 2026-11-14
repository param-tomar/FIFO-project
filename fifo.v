module fifo #(
  parameter DW = 8,
  parameter DEPTH = 16
)(
  input wire clk,
  input wire rst,
  input wire wr_en,
  input wire r_en,
  input wire [DW- 1:0] din,
  output reg [DW-1:0] dout,
  output wire full,
  output wire empty
);
  localparam AW  = $clog2(DEPTH);    //ceiling of the base-2 logarithm
  reg [DW-1:0]  mem [0:DEPTH-1];     // This creates a 2D memory array of 16 
                                     //slots (depth), where each individual slot is 8 bits wide (data width).
  reg [AW-1:0]  wr_ptr, r_ptr;
  reg [AW:0]     count;
  
  assign full = (count==DEPTH);
  assign empty = (count==0);
  
  wire do_wr = wr_en && !full;
  wire do_r = r_en && !empty;

always @(posedge clk or posedge rst ) begin
  if (rst) begin
    wr_ptr <= 0;
    r_ptr <= 0;
    count <= 0;
    dout <= 0;
  end else begin
    if (do_wr) begin
      mem [wr_ptr] <= din;
      wr_ptr <= wr_ptr + 1'b1;
    end
    if (do_r) begin
      dout <= mem [r_ptr];
      r_ptr <= r_ptr + 1'b1;
    end
    //count will be updated when both events are together
    case({do_wr,do_r})
      2'b10:  count <= count + 1'b1;
      2'b01:  count <= count - 1'b1;
      default: count <= count;
    endcase
  end
 end
endmodule
