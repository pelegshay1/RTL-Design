`timescale 1ns / 1ps

/**
 * Module: PWM_generator
 * Description: Generates PWM signal for RGB LED based on duty cycle command
 * PWM Resolution: Parametrized (512/1024/2048 slots)
 * Process: Counter counts 0 to (PWM_SLOTS-1), output HIGH when counter < duty_cycle
 */

module PWM_generator #(
    parameter PWM_SLOTS = 1024  // PWM resolution: 512, 1024, or 2048
) (
    input  logic         clk,
    input  logic         reset,
    input  logic [10:0]  duty_cycle,  // PWM duty cycle value (0 to PWM_SLOTS-1)
    input  logic [1:0]   led_select,  // LED selector: 01=LED16, 10=LED17
    output logic         pwm_out_16,  // PWM output for LED16 (active when led_select = 01)
    output logic         pwm_out_17   // PWM output for LED17 (active when led_select = 10)
);
    
    // Determine counter width based on PWM_SLOTS
    localparam int COUNTER_WIDTH = (PWM_SLOTS == 512) ? 9 :
                                    (PWM_SLOTS == 1024) ? 10 :
                                    11;  // 2048 slots
    
    // PWM counter: counts from 0 to (PWM_SLOTS - 1)
    logic [COUNTER_WIDTH-1:0] pwm_counter;
    
    // PWM maximum value (PWM_SLOTS - 1)
    localparam logic [10:0] PWM_MAX = PWM_SLOTS - 1;
    
    // Internal PWM signal (before routing to LED outputs)
    logic pwm_signal;
    
    // Counter logic: increment from 0 to PWM_MAX, then wrap around
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            pwm_counter <= {COUNTER_WIDTH{1'b0}};
            pwm_signal  <= 1'b0;
            pwm_out_16  <= 1'b0;
            pwm_out_17  <= 1'b0;
        end else begin
            // Increment counter, wrap around at PWM_MAX
            if (pwm_counter >= PWM_MAX) begin
                pwm_counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                pwm_counter <= pwm_counter + 1;
            end
            
            // PWM signal: HIGH when counter < duty_cycle, LOW otherwise
            // Clamp duty_cycle to PWM_MAX to prevent overflow
            if (duty_cycle > PWM_MAX) begin
                pwm_signal <= 1'b1;  // If value exceeds max, always HIGH (100% duty cycle)
            end else if (duty_cycle == 0) begin
                pwm_signal <= 1'b0;  // If value is 0, always LOW (0% duty cycle)
            end else begin
                // Compare counter with duty_cycle (using appropriate bit width)
                pwm_signal <= (pwm_counter < duty_cycle[COUNTER_WIDTH-1:0]);
            end
            
            // Route PWM signal to appropriate LED output based on led_select
            // led_select = 01: LED16, led_select = 10: LED17
            case (led_select)
                2'b01: begin
                    pwm_out_16 <= pwm_signal;
                    pwm_out_17 <= 1'b0;
                end
                2'b10: begin
                    pwm_out_16 <= 1'b0;
                    pwm_out_17 <= pwm_signal;
                end
                default: begin
                    pwm_out_16 <= 1'b0;
                    pwm_out_17 <= 1'b0;
                end
            endcase
        end
    end

endmodule