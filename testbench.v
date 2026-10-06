`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;

    Datapath DUT (
        .clk(clk), 
        .reset(rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
            
        #10;
        rst = 0;
        
        #300; 
        
        $finish;
    end
     initial begin
      $dumpfile("dump.vcd");       
       $dumpvars(0, testbench);           
  end
    initial begin
        forever @(posedge clk) begin
            #1; 
            
            if (!rst) begin
                // %t: Time, %d: Decimal, %h: Hex, %b: Binary
              $display("PC = %0d, inst = %b", DUT.PC_debug, DUT.instruction);
            end
        end
    end

endmodule