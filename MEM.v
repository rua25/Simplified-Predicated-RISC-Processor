module MEM(
    input  wire        clk,
    input  wire [31:0] ALU_result,
    input  wire [31:0] Store_data,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire        RegWrite_in,
    input  wire [4:0]  Rd_in,
    
    output wire [31:0] Read_data,
    output wire [31:0] ALU_result_out,
    output wire        RegWrite_out,
    output wire [4:0]  Rd_out
);

    // Data memory instantiation
    DataMemory DM(
        .clk(clk),
        .MemWr(MemWrite),
        .MemRd(MemRead),
        .address(ALU_result),
        .data_in(Store_data),
        .data_out(Read_data)
    );

    // Pass through signals
    assign ALU_result_out = ALU_result;
    assign RegWrite_out = RegWrite_in;
    assign Rd_out = Rd_in;
endmodule

