module InstructionMemory(
    input  wire [31:0] address,    // Word address (PC)
    output wire [31:0] instruction
);
    // Instruction memory - 1024 words (4KB)
    reg [31:0] memory [0:1023];
    
    // Initialize memory from file
    initial begin
        // Initialize all to NOP
        for (integer i = 0; i < 1024; i = i + 1)
            memory[i] = 32'b0;
        
        // Load instructions from file
        $readmemb("instructions.mem.txt", memory);
        
        // Display first 16 instructions for debugging
        $display("Instruction Memory Initialized from instructions.mem.txt");
        for (integer i = 0; i < 16; i = i + 1)
            $display("Instruction[%0d] = %b", i, memory[i]);
    end
    
    // Read operation - combinational
    assign instruction = memory[address[9:0]];
endmodule
