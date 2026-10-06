module ControlUnit(
    input  wire [4:0]  opcode,
    
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         alu_src,
    output reg         jump,
    output reg         jr,
    output reg         call,
    output reg         sign_extend,
    output reg [3:0]   alu_op
);

    always @(*) begin
        // Default values
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        jump        = 1'b0;
        jr          = 1'b0;
        call        = 1'b0;
        sign_extend = 1'b1;  // Default sign extend
        alu_op      = 4'b0000;
        
        case (opcode)
            // R-Type instructions
            5'b00000: begin  // ADD
                reg_write = 1'b1;
                alu_op = 4'b0000;
            end
            5'b00001: begin  // SUB
                reg_write = 1'b1;
                alu_op = 4'b0001;
            end
            5'b00010: begin  // OR
                reg_write = 1'b1;
                alu_op = 4'b0010;
            end
            5'b00011: begin  // NOR
                reg_write = 1'b1;
                alu_op = 4'b0011;
            end
            5'b00100: begin  // AND
                reg_write = 1'b1;
                alu_op = 4'b0100;
            end
            5'b01110: begin  // JR
                jr = 1'b1;
            end
            
            // I-Type instructions
            5'b00101: begin  // ADDI
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0000;
            end
            5'b00110: begin  // ORI
                reg_write = 1'b1;
                alu_src = 1'b1;
                sign_extend = 1'b0;  // Zero extend for logical
                alu_op = 4'b0010;
            end
            5'b00111: begin  // NORI
                reg_write = 1'b1;
                alu_src = 1'b1;
                sign_extend = 1'b0;  // Zero extend
                alu_op = 4'b0011;
            end
            5'b01001: begin  // ANDI
                reg_write = 1'b1;
                alu_src = 1'b1;
                sign_extend = 1'b0;  // Zero extend
                alu_op = 4'b0100;
            end
            5'b01010: begin  // LW
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0000;  // ADD for address calculation
            end
            5'b01011: begin  // SW
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 4'b0000;  // ADD for address calculation
            end
            
            // J-Type instructions
            5'b01100: begin  // J
                jump = 1'b1;
            end
            5'b01101: begin  // CALL
                call = 1'b1;
                jump = 1'b1;
            end
            
            default: begin
                // NOP or undefined
            end
        endcase
    end

endmodule