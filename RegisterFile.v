module RegisterFile(
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  read_addr1,
    input  wire [4:0]  read_addr2,
    input  wire [4:0]  read_addr3,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,
    input  wire        reg_write,
    input  wire [31:0] pc_value,
    
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,
    output wire [31:0] read_data3,
    output wire [31:0] reg_R30,
    output wire [31:0] reg_R31
);
    // 32-bit x 32 register file
    reg [31:0] registers [0:31];
    
    // Initialize/reset registers
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
    end
    
    // Write operation - on clock edge
    always @(posedge clk) begin
        if (reg_write && (write_addr != 5'b0)) begin
            registers[write_addr] <= write_data;
        end
    end
    
    // Read operations with special handling for R0, R30, R31
    // R0 is always zero, R30 reads PC value
    assign read_data1 = (read_addr1 == 5'b0) ? 32'b0 : 
                       (read_addr1 == 5'b11110) ? pc_value : 
                       registers[read_addr1];
    
    assign read_data2 = (read_addr2 == 5'b0) ? 32'b0 : 
                       (read_addr2 == 5'b11110) ? pc_value : 
                       registers[read_addr2];
    
    assign read_data3 = (read_addr3 == 5'b0) ? 32'b0 : 
                       (read_addr3 == 5'b11110) ? pc_value : 
                       registers[read_addr3];
    
    // Special register outputs
    assign reg_R30 = pc_value;      // R30 always shows PC
    assign reg_R31 = registers[31]; // R31 value (used for return address)
endmodule
