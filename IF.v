module IF(
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,
    input  wire        PCWrite,
    input  wire [31:0] PC_next,
    
    output reg  [31:0] PC,
    output wire [31:0] instruction
);

    // Instruction memory instantiation
    InstructionMemory IM(
        .address(PC),
        .instruction(instruction)
    );
    
    // Program counter update
    always @(posedge clk or posedge reset) begin
        if (reset) PC <= 0;
        else if (PCWrite) PC <= PC_next;
        // else hold PC (stall)
    end
endmodule

// Hazard Detection Unit module
module HazardDetectionUnit(
    input  wire       ID_EX_MemRead,
    input  wire [4:0] ID_EX_Rt,       // Destination register for LW
    input  wire [4:0] IF_ID_Rs,       // Rs field from IF/ID instruction
    input  wire [4:0] IF_ID_Rt_raw,   // Rt_raw field from IF/ID instruction
    input  wire [4:0] IF_ID_opcode,   // Opcode to determine instruction type
    input  wire       jump_detected,
    
    output reg        Stall,
    output reg        PCWrite,
    output reg        IF_ID_Write,
    output reg        Flush_IF_ID
);

    // Determine if instruction is R-Type (has Rt field)
    wire is_rtype_if_id = (IF_ID_opcode == 5'b00000 || IF_ID_opcode == 5'b00001 || 
                          IF_ID_opcode == 5'b00010 || IF_ID_opcode == 5'b00011 || 
                          IF_ID_opcode == 5'b00100 || IF_ID_opcode == 5'b01110);
    
    // For R-Type instructions, check Rt_raw; for others, no Rt check
    wire [4:0] IF_ID_Rt_actual = is_rtype_if_id ? IF_ID_Rt_raw : 5'b0;

    // Load-use hazard detection
    wire load_use_hazard = ID_EX_MemRead && 
                          ((ID_EX_Rt == IF_ID_Rs) || 
                           (is_rtype_if_id && (ID_EX_Rt == IF_ID_Rt_actual)));

    always @(*) begin
        if (load_use_hazard) begin
            // Stall pipeline for load-use hazard
            Stall = 1'b1;
            PCWrite = 1'b0;
            IF_ID_Write = 1'b0;
            Flush_IF_ID = 1'b0;
        end
        else if (jump_detected) begin
            // Flush on jump
            Stall = 1'b0;
            PCWrite = 1'b1;
            IF_ID_Write = 1'b0;
            Flush_IF_ID = 1'b1;
        end
        else begin
            // Normal operation
            Stall = 1'b0;
            PCWrite = 1'b1;
            IF_ID_Write = 1'b1;
            Flush_IF_ID = 1'b0;
        end
    end
endmodule
