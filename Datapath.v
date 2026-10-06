module Datapath(
    input  wire clk,
    input  wire reset,
    
    output wire [31:0] PC_debug,
    output wire [31:0] instruction_debug,
    output wire [31:0] ALU_result_debug
);

    // ====================
    // PIPELINE STAGES
    // ====================
    
    // IF Stage signals
    wire [31:0] PC;
    wire [31:0] PC_next;
    wire [31:0] instruction;
    
    // ID Stage signals
    wire [31:0] BusA, BusB, BusRp;
    wire [3:0]  ALUop_ID;
    wire        RegWrite_ID, MemRead_ID, MemWrite_ID, ALUSrc_ID;
    wire        Jump_ID, JR_ID, Call_ID, SignExtend_ID;
    wire [4:0]  Rd_ID, Rs_ID, Rt_ID, Rp_ID;
    wire [11:0] Immediate_ID;
    wire [21:0] Offset_ID;
    wire        predicate_ok_ID;
    wire [31:0] Jump_target_ID, JR_target_ID;
    
    // EX Stage signals
    wire [31:0] ALU_result_EX;
    wire [31:0] Store_data_EX;
    wire [31:0] BusRp_fwd_EX;
    wire [31:0] Jump_target_EX;
    wire [31:0] JR_target_EX;
    wire [31:0] Return_addr_EX;
    wire        Zero_EX;
    
    // MEM Stage signals
    wire [31:0] Read_data_MEM;
    wire [31:0] ALU_result_MEM;
    wire        RegWrite_MEM;
    wire [4:0]  Rd_MEM;
    
    // WB Stage signals
    wire [31:0] Write_data_WB;
    wire        RegWrite_WB;
    
    // ====================
    // PIPELINE REGISTERS
    // ====================
    
    // IF/ID Register
    reg [31:0] IF_ID_PC;
    reg [31:0] IF_ID_instr;
    wire Flush_IF_ID;
    
    // ID/EX Register
    reg [31:0] ID_EX_BusA, ID_EX_BusB, ID_EX_BusRp;
    reg [11:0] ID_EX_Imm;
    reg [21:0] ID_EX_Offset;
    reg [3:0]  ID_EX_ALUop;
    reg        ID_EX_ALUSrc, ID_EX_SignExtend, ID_EX_Call;
    reg        ID_EX_RegWrite, ID_EX_MemRead, ID_EX_MemWrite;
    reg        ID_EX_Jump, ID_EX_JR;
    reg [4:0]  ID_EX_Rd, ID_EX_Rs, ID_EX_Rt, ID_EX_Rp;
    reg [31:0] ID_EX_PC;
    reg        ID_EX_predicate_ok;
    
    // EX/MEM Register
    reg [31:0] EX_MEM_ALU_result, EX_MEM_Store_data;
    reg [31:0] EX_MEM_Jump_target, EX_MEM_JR_target;
    reg [31:0] EX_MEM_Return_addr;
    reg [31:0] EX_MEM_BusRp_fwd;
    reg [4:0]  EX_MEM_Rd;
    reg        EX_MEM_RegWrite, EX_MEM_MemRead, EX_MEM_MemWrite;
    reg        EX_MEM_Jump, EX_MEM_JR;
    
    // MEM/WB Register
    reg [31:0] MEM_WB_Read_data, MEM_WB_ALU_result;
    reg [4:0]  MEM_WB_Rd;
    reg        MEM_WB_RegWrite, MEM_WB_MemRead;
    
    // ====================
    // HAZARD & CONTROL SIGNALS
    // ====================
    wire        stall;
    wire        PCWrite;
    wire        IF_ID_Write;
    wire [1:0]  ForwardA, ForwardB, ForwardRp;
    
    // Control hazard signals
    wire        jump_detected_ID;
    wire [31:0] jump_target_ID;
    
    // Extract opcode from IF/ID for HDU
    wire [4:0] IF_ID_opcode = IF_ID_instr[31:27];
    wire [4:0] IF_ID_Rs_raw = IF_ID_instr[15:11];
    wire [4:0] IF_ID_Rt_raw = IF_ID_instr[10:6];
    
    // ====================
    // MODULE INSTANTIATIONS
    // ====================
    
    // 1. IF STAGE
    IF if_stage(
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .PC_next(PC_next),
        .PCWrite(PCWrite), 
        .PC(PC),
        .instruction(instruction)
    );
    
    // Jump detection in ID stage
    assign jump_detected_ID = ((Jump_ID || JR_ID) && predicate_ok_ID) && !stall;
    assign jump_target_ID = JR_ID ? JR_target_ID : Jump_target_ID;
    
    // PC selection with proper priority
    assign PC_next = (jump_detected_ID) ? jump_target_ID :
                     (PCWrite) ? PC + 1 : PC;  // hold PC if Stall
    
    // IF/ID Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_ID_PC    <= 32'b0;
            IF_ID_instr <= 32'b0;
        end
        else if (Flush_IF_ID) begin
            IF_ID_PC    <= 32'b0;
            IF_ID_instr <= 32'b0;   // insert NOP
        end
        else if (IF_ID_Write) begin
            IF_ID_PC    <= PC;
            IF_ID_instr <= instruction;
        end
        // else: hold IF/ID registers during stall
    end
    
    // 2. ID STAGE
    ID id_stage(
        .clk(clk),
        .reset(reset),
        .instruction(IF_ID_instr),
        .RegWrite_WB(RegWrite_WB),
        .RW_WB(MEM_WB_Rd),
        .BusW_WB(Write_data_WB),
        .PC_value_ID(IF_ID_PC),
        .BusA(BusA),
        .BusB(BusB),
        .BusRp(BusRp),
        .ALUop(ALUop_ID),
        .RegWrite(RegWrite_ID),
        .MemRead(MemRead_ID),
        .MemWrite(MemWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .Jump(Jump_ID),
        .JR(JR_ID),
        .Call(Call_ID),
        .SignExtend(SignExtend_ID),
        .Rd_out(Rd_ID),
        .Rs_out(Rs_ID),
        .Rt_out(Rt_ID),
        .Rp_out(Rp_ID),
        .Immediate_out(Immediate_ID),
        .Offset_out(Offset_ID),
        .predicate_ok(predicate_ok_ID),
        .Jump_target(Jump_target_ID),
        .JR_target(JR_target_ID)
    );
    
    // 3. HAZARD DETECTION UNIT
    HazardDetectionUnit HDU(
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_Rt(ID_EX_Rt),
        .IF_ID_Rs(IF_ID_Rs_raw),
        .IF_ID_Rt_raw(IF_ID_Rt_raw),
        .IF_ID_opcode(IF_ID_opcode),
        .jump_detected(jump_detected_ID),
        .Stall(stall),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .Flush_IF_ID(Flush_IF_ID)
    );
    
    // 4. ID/EX Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_BusA        <= 32'b0;
            ID_EX_BusB        <= 32'b0;
            ID_EX_BusRp       <= 32'b0;
            ID_EX_Imm         <= 12'b0;
            ID_EX_Offset      <= 22'b0;
            ID_EX_ALUop       <= 4'b0;
            ID_EX_ALUSrc      <= 1'b0;
            ID_EX_SignExtend  <= 1'b0;
            ID_EX_Call        <= 1'b0;
            ID_EX_Jump        <= 1'b0;
            ID_EX_JR          <= 1'b0;
            ID_EX_RegWrite    <= 1'b0;
            ID_EX_MemRead     <= 1'b0;
            ID_EX_MemWrite    <= 1'b0;
            ID_EX_Rd          <= 5'b0;
            ID_EX_Rs          <= 5'b0;
            ID_EX_Rt          <= 5'b0;
            ID_EX_Rp          <= 5'b0;
            ID_EX_PC          <= 32'b0;
            ID_EX_predicate_ok<= 1'b0;
        end
        else if (stall) begin
            // Insert bubble: clear controls and data so EX sees NOP
            ID_EX_BusA        <= 32'b0;
            ID_EX_BusB        <= 32'b0;
            ID_EX_BusRp       <= 32'b0;
            ID_EX_Imm         <= 12'b0;
            ID_EX_Offset      <= 22'b0;
            ID_EX_ALUop       <= 4'b0;
            ID_EX_ALUSrc      <= 1'b0;
            ID_EX_SignExtend  <= 1'b0;
            ID_EX_Call        <= 1'b0;
            ID_EX_Jump        <= 1'b0;
            ID_EX_JR          <= 1'b0;
            ID_EX_RegWrite    <= 1'b0;
            ID_EX_MemRead     <= 1'b0;
            ID_EX_MemWrite    <= 1'b0;
            ID_EX_Rd          <= 5'b0;
            ID_EX_Rs          <= 5'b0;
            ID_EX_Rt          <= 5'b0;
            ID_EX_Rp          <= 5'b0;
            ID_EX_PC          <= 32'b0;
            ID_EX_predicate_ok<= 1'b0;
        end
        else begin
            // Normal capture from ID outputs
            ID_EX_BusA        <= BusA;
            ID_EX_BusB        <= BusB;
            ID_EX_BusRp       <= BusRp;
            ID_EX_Imm         <= Immediate_ID;
            ID_EX_Offset      <= Offset_ID;
            ID_EX_ALUop       <= ALUop_ID;
            ID_EX_ALUSrc      <= ALUSrc_ID;
            ID_EX_SignExtend  <= SignExtend_ID;
            ID_EX_Call        <= Call_ID;
            ID_EX_Jump        <= Jump_ID;
            ID_EX_JR          <= JR_ID;
            ID_EX_RegWrite    <= RegWrite_ID;
            ID_EX_MemRead     <= MemRead_ID;
            ID_EX_MemWrite    <= MemWrite_ID;
            ID_EX_Rd          <= Rd_ID;
            ID_EX_Rs          <= Rs_ID;
            ID_EX_Rt          <= Rt_ID;
            ID_EX_Rp          <= Rp_ID;
            ID_EX_PC          <= IF_ID_PC;
            ID_EX_predicate_ok<= predicate_ok_ID;
        end
    end
    
    // 5. FORWARDING UNIT
    ForwardingUnit FU(
        .ID_EX_Rs(ID_EX_Rs),
        .ID_EX_Rt(ID_EX_Rt),
        .ID_EX_Rp(ID_EX_Rp),
        .EX_MEM_Rd(EX_MEM_Rd),
        .MEM_WB_Rd(MEM_WB_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardRp(ForwardRp)
    );
    
    // 6. EX STAGE
    EX ex_stage(
        .BusA(ID_EX_BusA),
        .BusB(ID_EX_BusB),
        .BusRp(ID_EX_BusRp),
        .Imm(ID_EX_Imm),
        .ALUop(ID_EX_ALUop),
        .ALUSrc(ID_EX_ALUSrc),
        .SignExtend(ID_EX_SignExtend),
        .EX_MEM_ALUresult(EX_MEM_ALU_result),
        .MEM_WB_WriteData(Write_data_WB),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardRp(ForwardRp),
        .Offset(ID_EX_Offset),
        .Jump(ID_EX_Jump),
        .JR(ID_EX_JR),
        .Call(ID_EX_Call),
        .PC(ID_EX_PC),
        .ALU_result(ALU_result_EX),
        .Store_data(Store_data_EX),
        .BusRp_fwd(BusRp_fwd_EX),
        .Jump_target(Jump_target_EX),
        .JR_target(JR_target_EX),
        .Return_addr(Return_addr_EX),
        .Zero(Zero_EX)
    );
    
    // 7. EX/MEM Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_ALU_result <= 32'b0;
            EX_MEM_Store_data <= 32'b0;
            EX_MEM_Jump_target <= 32'b0;
            EX_MEM_JR_target <= 32'b0;
            EX_MEM_Return_addr <= 32'b0;
            EX_MEM_BusRp_fwd <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            EX_MEM_MemRead <= 1'b0;
            EX_MEM_MemWrite <= 1'b0;
            EX_MEM_Jump <= 1'b0;
            EX_MEM_JR <= 1'b0;
        end else begin
            EX_MEM_ALU_result <= ALU_result_EX;
            EX_MEM_Store_data <= Store_data_EX;
            EX_MEM_Jump_target <= Jump_target_EX;
            EX_MEM_JR_target <= JR_target_EX;
            EX_MEM_Return_addr <= (ID_EX_Call && ID_EX_predicate_ok) ? Return_addr_EX : 32'b0;
            EX_MEM_BusRp_fwd <= BusRp_fwd_EX;
            EX_MEM_Rd <= ID_EX_Rd;
            EX_MEM_RegWrite <= ID_EX_RegWrite && ID_EX_predicate_ok;
            EX_MEM_MemRead <= ID_EX_MemRead && ID_EX_predicate_ok;
            EX_MEM_MemWrite <= ID_EX_MemWrite && ID_EX_predicate_ok;
            EX_MEM_Jump <= ID_EX_Jump && ID_EX_predicate_ok;
            EX_MEM_JR <= ID_EX_JR && ID_EX_predicate_ok;
        end
    end
    
    // 8. MEM STAGE
    MEM mem_stage(
        .clk(clk),
        .ALU_result(EX_MEM_ALU_result),
        .Store_data(EX_MEM_Store_data),
        .MemRead(EX_MEM_MemRead),
        .MemWrite(EX_MEM_MemWrite),
        .RegWrite_in(EX_MEM_RegWrite),
        .Rd_in(EX_MEM_Rd),
        .Read_data(Read_data_MEM),
        .ALU_result_out(ALU_result_MEM),
        .RegWrite_out(RegWrite_MEM),
        .Rd_out(Rd_MEM)
    );
    
    // 9. MEM/WB Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_Read_data <= 32'b0;
            MEM_WB_ALU_result <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            MEM_WB_MemRead <= 1'b0;
        end else begin
            MEM_WB_Read_data <= Read_data_MEM;
            MEM_WB_ALU_result <= ALU_result_MEM;
            MEM_WB_Rd <= Rd_MEM;
            MEM_WB_RegWrite <= RegWrite_MEM;
            MEM_WB_MemRead <= EX_MEM_MemRead;
        end
    end
    
    // 10. WB STAGE
    WB wb_stage(
        .Read_data(MEM_WB_Read_data),
        .ALU_result(MEM_WB_ALU_result),
        .MemRead(MEM_WB_MemRead),
        .RegWrite_in(MEM_WB_RegWrite),
        .Write_data(Write_data_WB),
        .RegWrite_out(RegWrite_WB)
    );
    
    // Debug outputs
    assign PC_debug = PC;
    assign instruction_debug = instruction;
    assign ALU_result_debug = ALU_result_EX;
    
    // Debug prints for simulation
    integer cycle_count = 0;
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count <= cycle_count + 1;
            $display("\n=== Cycle %0d ===", cycle_count);
            $display("PC: %0d -> %0d (stall=%b, jump=%b)", 
                     PC, PC_next, stall, jump_detected_ID);
            
            if (jump_detected_ID)
                $display("JUMP at ID: target=%0d", jump_target_ID);
            
            if (ForwardA != 2'b00 || ForwardB != 2'b00 || ForwardRp != 2'b00)
                $display("ForwardA: %b, ForwardB: %b, ForwardRp: %b", ForwardA, ForwardB, ForwardRp);
            
            // Display pipeline stage info
            $display("IF: PC=%0d, Inst=%h", PC, instruction);
            $display("ID: PC=%0d, Inst=%h, Rs=R%0d, Rt=R%0d, Rd=R%0d, Pred=%b", 
                     IF_ID_PC, IF_ID_instr, Rs_ID, Rt_ID, Rd_ID, predicate_ok_ID);
            $display("EX: ALUop=%b, Rs=R%0d, Rt=R%0d, Rd=R%0d", 
                     ID_EX_ALUop, ID_EX_Rs, ID_EX_Rt, ID_EX_Rd);
            $display("MEM: Addr=%h, Data=%h, MemRead=%b, MemWrite=%b",
                     EX_MEM_ALU_result, EX_MEM_Store_data, 
                     EX_MEM_MemRead, EX_MEM_MemWrite);
            
            if (RegWrite_WB && MEM_WB_Rd != 0)
                $display("WB: Writing R%0d = %h", MEM_WB_Rd, Write_data_WB);
        end
    end

endmodule