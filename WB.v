module WB(
    input  wire [31:0] Read_data,
    input  wire [31:0] ALU_result,
    input  wire        MemRead,
    input  wire        RegWrite_in,
    
    output wire [31:0] Write_data,
    output wire        RegWrite_out
);
    // Write Back stage - selects data to write to register file
    // Choose between memory read data or ALU result
    assign Write_data = MemRead ? Read_data : ALU_result;
    assign RegWrite_out = RegWrite_in;  // Pass through write enable
endmodule