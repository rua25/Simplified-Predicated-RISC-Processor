module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUop,
    output reg  [31:0] Result,
    output wire        Zero
);
    // ALU performs arithmetic and logical operations
    always @(*) begin
        case (ALUop)
            4'b0000: Result = A + B;          // ADD
            4'b0001: Result = A - B;          // SUB
            4'b0010: Result = A | B;          // OR
            4'b0011: Result = ~(A | B);       // NOR
            4'b0100: Result = A & B;          // AND
            default: Result = 32'h0;          // Default to zero
        endcase
    end
    
    // Zero flag is set when result equals zero
    assign Zero = (Result == 32'b0);
endmodule