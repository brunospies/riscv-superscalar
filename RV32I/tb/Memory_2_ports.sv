`timescale 1ns/1ps

module Memory
#(
    parameter DATA_START_ADDRESS = 32'h00000000
)
(
    input           clk_i,
    input           rst_i,
    input  [ 13:0]  addr_i [1:0],
    input  [ 31:0]  data_i [1:0],
    input  [  3:0]  wr_i   [1:0],

    output [ 64:0]  data_o [1:0]
);



//-----------------------------------------------------------------
// Dual Port RAM 128KB
// Mode: Read First
//-----------------------------------------------------------------
/* verilator lint_off MULTIDRIVEN */
reg [31:0]   ram [16383:0] /*verilator public*/;
/* verilator lint_on MULTIDRIVEN */

reg [31:0] ram_read_q [1:0];

logic [13:0] addr [1:0];

assign addr[0] = DATA_START_ADDRESS/4 + addr_i[0];
assign addr[1] = DATA_START_ADDRESS/4 + addr_i[1];


// Synchronous write
always @ (posedge clk_i)
begin
    if (wr0_i[0])
        ram[addr[0]][7:0] <= data0_i[7:0];
    if (wr0_i[1])
        ram[addr[0]][15:8] <= data0_i[15:8];
    if (wr0_i[2])
        ram[addr[0]][23:16] <= data0_i[23:16];
    if (wr0_i[3])
        ram[addr[0]][31:24] <= data0_i[31:24];
end

always @ (addr[0]) ram_read_q[0] <= ram[addr[0]];


always @ (posedge clk_i)
begin
    if (wr1_i[0])
        ram[addr[1]][7:0] <= data1_i[7:0];
    if (wr1_i[1])
        ram[addr[1]][15:8] <= data1_i[15:8];
    if (wr1_i[2])
        ram[addr[1]][23:16] <= data1_i[23:16];
    if (wr1_i[3])
        ram[addr[1]][31:24] <= data1_i[31:24];
end

always @ (addr[1]) ram_read_q[1] <= ram[addr[1]];

assign data_o[0] = ram_read_q[0];
assign data_o[1] = ram_read_q[1];

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
