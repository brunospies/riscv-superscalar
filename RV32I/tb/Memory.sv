`timescale 1ns/1ps

module Memory
#(
    parameter DATA_START_ADDRESS = 32'h00000000
)
(
    input           clk_i,
    input           rst_i,
    input  [ 13:0]  addr_i,
    input  [ 31:0]  data_i,
    input  [  3:0]  wr_i,

    output [ 63:0]  data_o,
);

//-----------------------------------------------------------------
// Dual Port RAM 128KB
// Mode: Read First
//-----------------------------------------------------------------
/* verilator lint_off MULTIDRIVEN */
reg [31:0]   ram [16383:0] /*verilator public*/;
/* verilator lint_on MULTIDRIVEN */

reg [31:0] ram_read_q [1:0];


always @ (posedge clk_i)
begin
    if (wr_i[0])
        ram[addr_i][7:0] <= data_i[7:0];
    if (wr_i[1])
        ram[addr_i][15:8] <= data_i[15:8];
    if (wr_i[2])
        ram[addr_i][23:16] <= data_i[23:16];
    if (wr_i[3])
        ram[addr_i][31:24] <= data_i[31:24];
end

always @ (addr_i) 
begin
    ram_read_q[0] <= ram[addr_i];
    ram_read_q[1] <= ram[addr_i+4];
end

assign data_o[31:0] = ram_read_q[0];
assign data_o[63:32] = ram_read_q[1];

task write; 
    input [31:0] addr;
    input [7:0]  data;
begin
    case (addr[1:0])
    2'd0: ram[addr/4][7:0]   = data;
    2'd1: ram[addr/4][15:8]  = data;
    2'd2: ram[addr/4][23:16] = data;
    2'd3: ram[addr/4][31:24] = data;
    endcase
end
endtask

endmodule
