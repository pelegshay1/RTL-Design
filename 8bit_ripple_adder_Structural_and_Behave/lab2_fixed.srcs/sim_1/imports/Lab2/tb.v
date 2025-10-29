// Minimal testbench
`timescale 1ns/1ps
module tb_ripple_adder;
    reg [7:0] A, B;
    reg Cin;
    wire [7:0] Sum_struct;
    wire [7:0] Sum_behave;
    wire Cout_struct;
    wire Cout_behave;

    ripple_adder_behave_8bit uut_b(.a(A), .b(B), .cin(Cin), .sum(Sum_behave), .cout(Cout_struct));

    ripple_adder_struct_8bit uut_s(.a(A), .b(B), .cin(Cin), .sum(Sum_struct), .cout(Cout_behave));

  initial begin
        $display("time\tA\tB\tCin\t| Sum_struct\tCout_struct\tSum_behave\tCout_behave");
        
        // Test case 1: No carry-out
        A = 8'h01; B = 8'h02; Cin = 0; #5;
        $display("%0t\t%h\t%h\t%b\t| %h\t\t\t%b\t\t\t%h\t\t\t\t%b",$time,A,B,Cin,Sum_struct,Cout_struct,Sum_behave,Cout_behave);
        
        // Test case 2: With carry-out
        A = 8'h7F; B = 8'h01; Cin = 0; #5;
         $display("%0t\t%h\t%h\t%b\t| %h\t\t\t%b\t\t\t%h\t\t\t\t%b",$time,A,B,Cin,Sum_struct,Cout_struct,Sum_behave,Cout_behave);
        
        // Test case 3: No carry-out, max value
        A = 8'hFF; B = 8'h00; Cin = 0; #5;
         $display("%0t\t%h\t%h\t%b\t| %h\t\t\t%b\t\t\t%h\t\t\t\t%b",$time,A,B,Cin,Sum_struct,Cout_struct,Sum_behave,Cout_behave);
        
        // Test case 4: Max overflow
        A = 8'hFF; B = 8'h01; Cin = 0; #5;
         $display("%0t\t%h\t%h\t%b\t| %h\t\t\t%b\t\t\t%h\t\t\t\t%b",$time,A,B,Cin,Sum_struct,Cout_struct,Sum_behave,Cout_behave);
        
        // Test case 5: No carry-out, zero
        A = 8'h00; B = 8'h00; Cin = 0; #5;
         $display("%0t\t%h\t%h\t%b\t| %h\t\t\t%b\t\t\t%h\t\t\t\t%b",$time,A,B,Cin,Sum_struct,Cout_struct,Sum_behave,Cout_behave);
        
        $finish;
    end
endmodule