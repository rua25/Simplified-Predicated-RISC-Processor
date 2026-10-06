module EX(
    input  wire [31:0] BusA,
    input  wire [31:0] BusB,
    input  wire [31:0] BusRp,
    input  wire [11:0] Imm,
    input  wire [3:0]  ALUop,
    input  wire        ALUSrc,
    input  wire        SignExtend,
    input  wire [31:0] EX_MEM_ALUresult,
    input  wire [31:0] MEM_WB_WriteData,
    input  wire [1:0]  ForwardA,
    input  wire [1:0]  ForwardB,
    input  wire [1:0]  ForwardRp,
    input  wire [21:0] Offset,
    input  wire        Jump,
    input  wire        JR,
    input  wire        Call,
    input  wire [31:0] PC,
    
    output wire [31:0] ALU_result,
    output wire [31:0] Store_data,
    output wire [31:0] BusRp_fwd,
    output wire [31:0] Jump_target,
    output wire [31:0] JR_target,
    output wire [31:0] Return_addr,
    output wire        Zero
);

    // Immediate extension
    wire [31:0] imm_ext = SignExtend ? {{20{Imm[11]}}, Imm} : {20'b0, Imm};

    // Forwarding multiplexers
    wire [31:0] ALU_in1 = (ForwardA == 2'b10) ? EX_MEM_ALUresult :
                          (ForwardA == 2'b01) ? MEM_WB_WriteData : BusA;

    wire [31:0] ALU_in2_pre = ALUSrc ? imm_ext : BusB;
    wire [31:0] ALU_in2 = (ForwardB == 2'b10) ? EX_MEM_ALUresult :
                          (ForwardB == 2'b01) ? MEM_WB_WriteData : ALU_in2_pre;

    assign Store_data = ALU_in2; // forwarded value for SW

    assign BusRp_fwd = (ForwardRp == 2'b10) ? EX_MEM_ALUresult :
                       (ForwardRp == 2'b01) ? MEM_WB_WriteData : BusRp;

    // ALU instantiation
    ALU alu_unit (
        .A(ALU_in1),
        .B(ALU_in2),
        .ALUop(ALUop),
        .Result(ALU_result),
        .Zero(Zero)
    );
    
    // Jump calculations
    wire [31:0] offset_extended = {{10{Offset[21]}}, Offset};
    assign Jump_target = PC + offset_extended;
    assign JR_target = ALU_in1;   // Use forwarded value for JR
    assign Return_addr = PC + 1;  // Return address for CALL
    
endmodule
