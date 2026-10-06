module ForwardingUnit(
    input  wire [4:0] ID_EX_Rs,
    input  wire [4:0] ID_EX_Rt,
    input  wire [4:0] ID_EX_Rp,
    input  wire [4:0] EX_MEM_Rd,
    input  wire [4:0] MEM_WB_Rd,
    input  wire       EX_MEM_RegWrite,
    input  wire       MEM_WB_RegWrite,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB,
    output reg [1:0] ForwardRp
);

    always @(*) begin
        // Default: no forwarding
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        ForwardRp = 2'b00;

        // Forward from EX/MEM stage (priority 1)
        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0)) begin
            if (EX_MEM_Rd == ID_EX_Rs) ForwardA = 2'b10;
            if (EX_MEM_Rd == ID_EX_Rt) ForwardB = 2'b10;
            if (EX_MEM_Rd == ID_EX_Rp) ForwardRp = 2'b10;
        end

        // Forward from MEM/WB stage (priority 2)
        if (MEM_WB_RegWrite && (MEM_WB_Rd != 0)) begin
            if ((MEM_WB_Rd == ID_EX_Rs) && !(EX_MEM_RegWrite && EX_MEM_Rd == ID_EX_Rs)) ForwardA = 2'b01;
            if ((MEM_WB_Rd == ID_EX_Rt) && !(EX_MEM_RegWrite && EX_MEM_Rd == ID_EX_Rt)) ForwardB = 2'b01;
            if ((MEM_WB_Rd == ID_EX_Rp) && !(EX_MEM_RegWrite && EX_MEM_Rd == ID_EX_Rp)) ForwardRp = 2'b01;
        end
    end
endmodule