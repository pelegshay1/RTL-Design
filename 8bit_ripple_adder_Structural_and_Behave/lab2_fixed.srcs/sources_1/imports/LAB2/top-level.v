module top_level (
    // Input ports
    input [7:0] a,         // 8 switches for first input
    input [7:0] b,         // 8 switches for second input
    
    // Output ports
    output [7:0] sum,      // 8 LEDs for sum
    output cout            // Single LED for cout
);

    // Instance of 8-bit ripple adder
    ripple_adder_behave_8bit (
        .a(a),            // Connect to input a
        .b(b),            // Connect to input b
        .cin(1'b0),       // Hardwire cin to 0
        .sum(sum),        // Connect to sum LEDs
        .cout(cout)       // Connect to carry out LED
    );

endmodule