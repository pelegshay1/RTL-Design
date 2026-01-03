`timescale 1ns / 1ps

/**
 * Module: CIE_scaling_unit
 * Description: Applies gamma correction and CIE scaling to RGB values
 * Process: Input RGB (0-255) -> Gamma LUT (sRGB to Linear) -> CIE Scaling -> PWM Output
 * CIE Scaling Constants: Red=1.0, Green=0.51, Blue=2.62
 * PWM Resolution: Parametrized (512/1024/2048 slots) - supports 9/10/11-bit outputs
 */

`include "gamma_lut_table.sv"

module CIE_scaling_unit #(
    parameter PWM_SLOTS = 1024  // PWM resolution: 512, 1024, or 2048
)(
    input  logic         clk,
    input  logic         reset,
    input  logic [7:0]   red_value,      // Red input (0-255)
    input  logic [7:0]   green_value,    // Green input (0-255)
    input  logic [7:0]   blue_value,     // Blue input (0-255)
    output logic [10:0]  red_pwm_out,    // Red PWM output (11-bit max for 2048 slots)
    output logic [10:0]  green_pwm_out,  // Green PWM output (11-bit max for 2048 slots)
    output logic [10:0]  blue_pwm_out    // Blue PWM output (11-bit max for 2048 slots)
);

    // Gamma-corrected values (10-bit from LUT, 0-1023)
    logic [9:0] gamma_red, gamma_green, gamma_blue;

    // Intermediate multiplication results (after division by 256 for fixed-point)
    // Using shifts and additions for multiplication by constants
    // Results can exceed 10-bit for Blue, so use 11-bit to support 2048 PWM slots
    logic [10:0] red_scaled;    // Red: gamma * 1.0 = gamma (max 1023, fits in 11-bit)
    logic [10:0] green_scaled;  // Green: gamma * 0.51 (max ~522, fits in 11-bit)
    logic [10:0] blue_scaled;   // Blue: gamma * 2.62 (max ~2682, needs 11-bit)
    
    // PWM maximum value based on parameter
    localparam logic [10:0] PWM_MAX = (PWM_SLOTS == 512) ? 11'd511 :
                                      (PWM_SLOTS == 1024) ? 11'd1023 :
                                      11'd2047;  // 2048 slots

    // Gamma lookup - combinational
    always_comb begin
        gamma_red   = gamma_table[red_value];
        gamma_green = gamma_table[green_value];
        gamma_blue  = gamma_table[blue_value];
    end

    // CIE Scaling multiplication and PWM output generation
    // The scaling preserves the relative brightness relationship while fitting into 8-bit PWM
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            red_pwm_out   <= 11'd0;
            green_pwm_out <= 11'd0;
            blue_pwm_out  <= 11'd0;
            red_scaled    <= 11'd0;
            green_scaled  <= 11'd0;
            blue_scaled   <= 11'd0;
        end else begin
            // Step 1: Gamma Correction (sRGB to LED Linear)
            // gamma_table converts sRGB values (0-255) to linear LED values (0-1023)
            // This is already done in the combinational block above
            
            // Step 2: CIE Scaling to avoid LED intensity differences
            // Red: gamma * 1.0 (no scaling, just use gamma value directly)
            red_scaled <= {1'b0, gamma_red};  // gamma * 1.0 = gamma (0-1023, extend to 11-bit)

            // Green: gamma * 0.51
            // Using fixed-point: 0.51 ≈ 131/256
            // gamma * 0.51 = (gamma * 131) / 256
            // 131 = 128 + 2 + 1 = (1 << 7) + (1 << 1) + 1
            // Compute: (gamma << 7) + (gamma << 1) + gamma, then divide by 256 (>> 8)
            green_scaled <= (gamma_green << 7) + (gamma_green << 1) + gamma_green;

            // Blue: gamma * 2.62
            // Using fixed-point: 2.62 * 256 = 670.72 ≈ 671
            // gamma * 2.62 = (gamma * 671) / 256
            // 671 = 512 + 128 + 16 + 8 + 4 + 2 + 1 = (1 << 9) + (1 << 7) + (1 << 4) + (1 << 3) + (1 << 2) + (1 << 1) + 1
            // Compute: (gamma << 9) + (gamma << 7) + (gamma << 4) + (gamma << 3) + (gamma << 2) + (gamma << 1) + gamma, then divide by 256 (>> 8)
            blue_scaled <= (gamma_blue << 9) + (gamma_blue << 7) + (gamma_blue << 4) + (gamma_blue << 3) + (gamma_blue << 2) + (gamma_blue << 1) + gamma_blue;

            // Step 3: Output PWM values clamped to PWM_MAX (supports 512/1024/2048 slots)
            red_pwm_out   <= (red_scaled   > PWM_MAX) ? PWM_MAX : red_scaled;
            green_pwm_out <= (green_scaled > PWM_MAX) ? PWM_MAX : green_scaled;
            blue_pwm_out  <= (blue_scaled  > PWM_MAX) ? PWM_MAX : blue_scaled;
        end
    end

endmodule