`timescale 1ns/1ps

module RISCV_pipeline_tb;

    logic clock = 0;
    logic reset;
    logic [3:0]  MemWrite [1:0];
    logic [31:0] instructionAddress,
    logic [63:0] instruction,
    logic [31:0] dataAddress [1:0],
    logic [31:0] data_i [1:0],
    logic [31:0] data_o [1:0];
    logic [7:0]  mem[131072:0];
    integer i;
    integer f;

    localparam logic [31:0] INSTRUCTION_OFFSET = 32'h00000298;
    localparam logic [31:0] DATA_OFFSET        = 32'h00000000;

    //DUT (Device Under Test) - RISCV_PIPELINE (VHDL)
    RISCV_PIPELINE #( 
        .PC_START_ADDRESS($unsigned(INSTRUCTION_OFFSET))
    ) DUV (
        .clock(clock),
        .reset(reset),
        .instructionAddress(instructionAddress),
        .instruction(instruction),
        .dataAddress(dataAddress),
        .data_i(data_i),
        .data_o(data_o),
        .MemWrite(MemWrite)
    );

    always #5 clock = ~clock;

    /*initial begin
        reset = 1'b1;
        #7;
        reset = 1'b0;

        // Load TCM memory
        for (i=0;i<131072;i=i+1)
            mem[i] = 0;

        f = $fopenr("./build/tcm.bin");
        i = $fread(mem, f);
        for (i=0;i<131072;i=i+1)
            u_mem.write(i, mem[i]);
    end*/

    initial begin
        reset = 1'b1;
        #7;
        reset = 1'b0;

        for (i = 0; i < 131072; i = i + 1)
	    mem[i] = 0;

        f = $fopen("./build/tcm.bin", "rb");
        if (f == 0) begin
	    $display("Erro ao abrir o arquivo tcm.bin.");
	    $finish;
        end

    
        i = $fread(mem, f);
        $fclose(f); 

        for (i = 0; i < 131072; i = i + 1)
	    u_mem_data.write(i, mem[i]);      // ESCREVE NAS DUAS AO MESMKA VEZ, POIS ELAS COMPARTILHAM O MESMO ARMAZENAMENTO ???
    end


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

    logic [13:0] addr [1:0];

    assign addr[0] = dataAddress[15:2][0];
    assign addr[1] = dataAddress[15:2][1];

    Memory_2_ports#( 
        .DATA_START_ADDRESS($unsigned(DATA_OFFSET))
    )u_mem_data(
        // Inputs
        .clk_i(clock)
        ,.rst_i(reset)
        ,.data_i(data_o)
        ,.addr_i(addr)
        ,.wr_i(MemWrite)

        // Outputs
        ,.data_o(data_i)
    );

    Memory#( 
        .DATA_START_ADDRESS($unsigned(DATA_OFFSET))
    )u_mem_inst(
        // Inputs
        .clk_i(clock)
        ,.rst_i(reset)
        ,.data_i(data_o)
        ,.addr1_i(instructionAddress[15:2])
        ,.wr1_i(4'b0)

        // Outputs
        ,.data0_o(data_i)
        ,.data1_o(instruction)
    );


endmodule
