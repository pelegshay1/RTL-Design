//This moudle will convert binary input number into a binary coded decimal number -
//Where - every decimal digit will be represented by 4 bits

/*
* ============================================================================
* Module:  binary_to_bcd
*
* Description:
* This module implements the "Double Dabble" (also known as the
* "Shift-and-Add-3") algorithm to convert an N-bit binary number
* into its Binary Coded Decimal (BCD) equivalent.
*
* The algorithm works by iterating N times (once for each input bit).
* In each iteration, it performs two main operations:
*
* 1. CHECK & CORRECT (The "Add-3" part):
* Before shifting, the logic checks *each* 4-bit BCD nibble (ones,
* tens, hundreds, etc.) independently. If any nibble's current
* value is 5 or greater (>= 5), 3 is added to that specific nibble.
*
* Why? A left shift is a "multiply by 2". If a BCD nibble is 5,
* a shift would make it 10 ('b1010), which is an invalid BCD digit.
* By adding 3 *before* the shift (5 + 3 = 8), the subsequent
* shift results in 16 ('b10000). The '1' bit correctly
* "carries over" into the next BCD nibble (next deciaml digit), and the current
* nibble becomes '0' ('b0000), correctly representing '10' in BCD.
*
* 2. SHIFT (The "Shift" part):
* After the correction step, the entire combined register (the
* BCD digits and the remaining binary input) is shifted left by
* one position. The Most Significant Bit (MSB) of the binary
* input is shifted into the Least Significant Bit (LSB) of the
* BCD "ones" digit.
*
* After N full iterations, all binary bits have been shifted through
* the BCD registers, and the BCD registers hold the final, correct
* decimal representation of the original binary input.
* ============================================================================
*/
module binary_to_bcd_16_bit (
  input  [15:0] binary_in,
  output [3:0] bcd_tens_thousands,
  output [3:0] bcd_thousands,
  output [3:0] bcd_hundreds,
  output [3:0] bcd_tens,
  output [3:0] bcd_ones
);


  reg [19:0] bcd_stage; //

  // binary_stage י
  reg [15:0]  binary_stage;
  reg [15:0]


  integer i;

  always @(*) begin

    bcd_stage    = 20'd0;
    binary_stage = binary_in;


    for (i = 0; i < 16; i = i + 1) begin

      //ones digit
      if (bcd_stage[3:0] >= 5) begin
        bcd_stage[3:0] = bcd_stage[3:0] + 3;
      end

      // tens digit
      if (bcd_stage[7:4] >= 5) begin
        bcd_stage[7:4] = bcd_stage[7:4] + 3;
      end

      // hundrends digit
      if (bcd_stage[11:8] >= 5) begin
        bcd_stage[11:8] = bcd_stage[11:8] + 3;
      end

      // thousands digit
      if (bcd_stage[15:12] >= 5) begin
        bcd_stage[15:12] = bcd_stage[15:12] + 3;
      end

      // tens -thousands digit
      if (bcd_stage[19:16] >= 5) begin
        bcd_stage[19:16] = bcd_stage[19:16] + 3;
      end


      bcd_stage = {bcd_stage[18:0], binary_stage[15]};


      binary_stage = {binary_stage[14:0], 1'b0};
    end
  end

  // Assign the output - every decimal digit gets 4 bits representation
  assign bcd_tens_thousands = bcd_stage [19:16];
  assign bcd_thousands      = bcd_stage [15:12];
  assign bcd_hundreds       = bcd_stage[11:8];
  assign bcd_tens           = bcd_stage[7:4];
  assign bcd_ones           = bcd_stage[3:0];

endmodule