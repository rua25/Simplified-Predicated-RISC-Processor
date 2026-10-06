module ID(
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire        RegWrite_WB,
    input  wire [4:0]  RW_WB,
    input  wire [31:0] BusW_WB,
    input  wire [31:0] PC_value_ID,
    
    output wire [31:0] BusA,
    output wire [31:0] BusB,
    output wire [31:0] BusRp,
    output reg  [3:0]  ALUop,
    output reg         RegWrite,
    output reg         MemRead,
    output reg         MemWrite,
    output reg         ALUSrc,
    output reg         Jump,
    output reg         JR,
    output reg         Call,
    output reg         SignExtend,
    output reg  [4:0]  Rd_out,
    output reg  [4:0]  Rs_out,
    output reg  [4:0]  Rt_out,
    output reg  [4:0]  Rp_out,
    output reg  [11:0] Immediate_out,
    output reg  [21:0] Offset_out,
    output wire        predicate_ok,
    output wire [31:0] Jump_target,
    output wire [31:0] JR_target
);

    // Instruction bit fields
    wire [4:0] opcode = instruction[31:27];
    wire [4:0] Rp     = instruction[26:22];
    wire [4:0] Rd     = instruction[20:16];
    wire [4:0] Rs     = instruction[15:11];
    wire [4:0] Rt_raw = instruction[10:6];
    wire [11:0] immediate = instruction[11:0];
    wire [21:0] offset    = instruction[21:0];
    
    // Instruction type detection
    wire is_rtype = (opcode == 5'b00000 || opcode == 5'b00001 || 
                     opcode == 5'b00010 || opcode == 5'b00011 || 
                     opcode == 5'b00100 || opcode == 5'b01110);
    wire is_itype = (opcode >= 5'b00101 && opcode <= 5'b01011);
    wire is_jtype = (opcode == 5'b01100 || opcode == 5'b01101);
    
    // Register read address selection
    wire [4:0] read_addr2 = (opcode == 5'b01011) ? Rd :  // SW: read from Rd
                           (is_rtype) ? Rt_raw :  // R-Type: read Rt
                           5'b0;                  // I-Type (non-SW): no Rt to read
    
    // Debug output
    always @(*) begin
        $display("ID DECODE: Inst=%h, Op=%b, Rp=R%0d, Rd=R%0d, Rs=R%0d, Rt_raw=R%0d, Imm=%h, Offset=%h",
                 instruction, opcode, Rp, Rd, Rs, Rt_raw, immediate, offset);
    end
    
    // Register file instantiation
    wire [31:0] reg_read_data1, reg_read_data2, reg_read_data3;
    
    RegisterFile RF(
        .clk(clk),
        .reset(reset),
        .read_addr1(Rs),
        .read_addr2(read_addr2),
        .read_addr3(Rp),
        .write_addr(RW_WB),
        .write_data(BusW_WB),
        .reg_write(RegWrite_WB),
        .pc_value(PC_value_ID),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2),
        .read_data3(reg_read_data3),
        .reg_R30(),
        .reg_R31()
    );
    
    assign BusA = reg_read_data1;
    assign BusB = reg_read_data2;
    assign BusRp = reg_read_data3;
    
    // Predicate logic
    assign predicate_ok = (Rp == 5'b0) || (BusRp != 32'b0);
    
    // Jump target calculation
    wire [31:0] offset_extended = {{10{offset[21]}}, offset}; 
    assign Jump_target = PC_value_ID + offset_extended;
    assign JR_target   = BusA;

    // Control signal generation
    always @(*) begin
        // Default values
        ALUop      = 4'b0000;
        RegWrite   = 1'b0;
        MemRead    = 1'b0;
        MemWrite   = 1'b0;
        ALUSrc     = 1'b0;
        Jump       = 1'b0;
        JR         = 1'b0;
        Call       = 1'b0;
        SignExtend = 1'b1;
        
        // Pass through decoded fields
        Rd_out     = Rd;
        Rs_out     = Rs;
        Rt_out     = Rt_raw;
        Rp_out     = Rp;
        Immediate_out = immediate;
        Offset_out    = offset;
        
        // Generate control signals based on opcode
        case (opcode)
            // R-Type
            5'b00000: begin // ADD
                ALUop = 4'b0000;
                RegWrite = 1'b1;
            end
            5'b00001: begin // SUB
                ALUop = 4'b0001;
                RegWrite = 1'b1;
            end
            5'b00010: begin // OR
                ALUop = 4'b0010;
                RegWrite = 1'b1;
            end
            5'b00011: begin // NOR
                ALUop = 4'b0011;
                RegWrite = 1'b1;
            end
            5'b00100: begin // AND
                ALUop = 4'b0100;
                RegWrite = 1'b1;
            end
            5'b01110: begin // JR
                JR = 1'b1;
            end
            
            // I-Type
            5'b00101: begin // ADDI
                ALUop = 4'b0000;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b1;
            end
            5'b00110: begin // ORI
                ALUop = 4'b0010;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b0;
            end
            5'b00111: begin // NORI
                ALUop = 4'b0011;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b0;
            end
            5'b01001: begin // ANDI
                ALUop = 4'b0100;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b0;
            end
            5'b01010: begin // LW
                ALUop = 4'b0000;
                RegWrite = 1'b1;
                MemRead = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b1;
            end
            5'b01011: begin // SW
                ALUop = 4'b0000;
                MemWrite = 1'b1;
                ALUSrc = 1'b1;
                SignExtend = 1'b1;
            end
            
            // J-Type
            5'b01100: begin // J
                Jump = 1'b1;
            end
            5'b01101: begin // CALL
                Call = 1'b1;
                Jump = 1'b1;
                RegWrite = 1'b1;
                Rd_out = 5'b11111; // Write to R31
            end
            
            default: begin
                // NOP (ADD R0, R0, R0, R0)
                ALUop = 4'b0000;
            end
        endcase
    end

endmodule