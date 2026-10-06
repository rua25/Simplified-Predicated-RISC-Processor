module DataMemory(
    input  wire        clk,
    input  wire        MemWr,
    input  wire        MemRd,
    input  wire [31:0] address,    // Word address
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    // Data memory module - 1024 words (4KB)
    reg [31:0] memory [0:1023];
    
    // Initialize memory from file
    initial begin
        // Initialize all to zero first
        for (integer i = 0; i < 1024; i = i + 1)
            memory[i] = 32'b0;
        
        // Load data from file
        $readmemb("data.mem.txt", memory);
        
        // Display first 16 memory locations for debugging
        $display("Data Memory Initialized from data.mem.txt");
        for (integer i = 0; i < 16; i = i + 1)
            $display("Data Memory[%0d] = %h", i, memory[i]);
    end
    
    // Read operation - combinational
    assign data_out = MemRd ? memory[address[9:0]] : 32'b0;
    
    // Write operation - sequential (on clock edge)
    always @(posedge clk) begin
        if (MemWr) begin
            memory[address[9:0]] <= data_in;
            $display("Data Memory Write: address=%0d, data=%h", address, data_in);
        end
    end
endmodule 
