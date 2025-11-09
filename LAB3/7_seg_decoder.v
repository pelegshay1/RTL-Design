module seg_decoder (
	input [3:0] digit_in,
	output reg [6:0] segments
);
	always @(*) begin
		case (digit_in) //the mapping is as follow: 7'bABCDEFG -->cathodes set-up
			4'd0:    segments = 7'b1111110; //0 
			4'd1:    segments = 7'b0110000; //1
			4'd2:    segments = 7'b1101101; //2 
			4'd3:    segments = 7'b1111001; //3
			4'd4:    segments = 7'b0110011; //4 
			4'd5:    segments = 7'b1011010; //5 
			4'd6:    segments = 7'b1011111; //6 
			4'd7:    segments = 7'b1110000; //7 
			4'd8:    segments = 7'b1111111; //8 
			4'd9:    segments = 7'b1111011; //9
			4'hA:    segments = 7'b1110111; //A
			4'hB:    segments = 7'b0011111; //B
			4'hC:    segments = 7'b1001110; //C
			4'hD:    segments = 7'b0111101; //D
			4'hE:    segments = 7'b1001111; //E
			4'hF:    segments = 7'b1000111; //F
			default :segments = 7'b0000000; //default = 0
		endcase
	end

endmodule