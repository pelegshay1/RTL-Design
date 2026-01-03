#!/usr/bin/env python3
"""
RGB LED Command Automation Script
Sends RGB and LED commands via serial port to the FPGA UART receiver
Baud Rate: 57600
Port: COM5
Message Format: {Rddd,Gddd,Bddd} for RGB, {L016} or {L017} for LED selection
"""

import serial
import time
import sys

# Serial port configuration
COM_PORT = 'COM5'
BAUDRATE = 57600
TIMEOUT = 1.0

def send_rgb_command(ser, red, green, blue, led_num=16):
    """
    Send RGB command: {Rddd,Gddd,Bddd}
    
    Args:
        ser: Serial port object
        red: Red value (0-255)
        green: Green value (0-255)
        blue: Blue value (0-255)
        led_num: LED number (16 or 17) - optional, sends LED command first
    """
    # Validate inputs
    red = max(0, min(255, int(red)))
    green = max(0, min(255, int(green)))
    blue = max(0, min(255, int(blue)))
    
    # First send LED selection command if specified
    if led_num in [16, 17]:
        led_msg = f"{{L0{led_num}}}"
        ser.write(led_msg.encode('ascii'))
        print(f"  Sent LED command: {led_msg}")
        time.sleep(0.1)  # Small delay between commands
    
    # Format RGB message: {Rddd,Gddd,Bddd}
    rgb_msg = f"{{R{red:03d},G{green:03d},B{blue:03d}}}"
    
    # Send message
    ser.write(rgb_msg.encode('ascii'))
    print(f"  Sent RGB: {rgb_msg} (R={red}, G={green}, B={blue})")
    
    # Wait for transmission to complete (16 bytes at 57600 baud ≈ 2.8ms)
    time.sleep(0.01)

def send_led_command(ser, led_num):
    """
    Send LED selection command: {L016} or {L017}
    
    Args:
        ser: Serial port object
        led_num: LED number (16 or 17)
    """
    if led_num not in [16, 17]:
        print(f"Error: LED number must be 16 or 17, got {led_num}")
        return
    
    led_msg = f"{{L0{led_num}}}"
    ser.write(led_msg.encode('ascii'))
    print(f"  Sent LED command: {led_msg}")

def main():
    """Main function to send RGB commands"""
    
    print("=" * 60)
    print("RGB LED Command Automation Script")
    print(f"Port: {COM_PORT}, Baud Rate: {BAUDRATE}")
    print("=" * 60)
    
    try:
        # Open serial port
        ser = serial.Serial(COM_PORT, BAUDRATE, timeout=TIMEOUT)
        print(f"\nConnected to {COM_PORT} at {BAUDRATE} baud\n")
        time.sleep(0.5)  # Wait for connection to stabilize
        
        # Select LED 16
        print("Selecting LED 16...")
        send_led_command(ser, 16)
        time.sleep(0.2)
        
        # Test sequence 1: Pure colors
        print("\n--- Test Sequence 1: Pure Colors ---")
        send_rgb_command(ser, 255, 0, 0, 16)    # Pure Red
        time.sleep(0.5)
        send_rgb_command(ser, 0, 255, 0, 16)    # Pure Green
        time.sleep(0.5)
        send_rgb_command(ser, 0, 0, 255, 16)    # Pure Blue
        time.sleep(0.5)
        send_rgb_command(ser, 255, 255, 255, 16)  # White
        time.sleep(0.5)
        send_rgb_command(ser, 0, 0, 0, 16)      # Black
        time.sleep(0.5)
        
        # Test sequence 2: Color transitions
        print("\n--- Test Sequence 2: Color Transitions ---")
        for i in range(0, 256, 16):
            send_rgb_command(ser, i, 0, 0, 16)  # Red ramp
            time.sleep(0.2)
        
        for i in range(0, 256, 16):
            send_rgb_command(ser, 0, i, 0, 16)  # Green ramp
            time.sleep(0.2)
        
        for i in range(0, 256, 16):
            send_rgb_command(ser, 0, 0, i, 16)  # Blue ramp
            time.sleep(0.2)
        
        # Test sequence 3: Mixed colors
        print("\n--- Test Sequence 3: Mixed Colors ---")
        send_rgb_command(ser, 255, 128, 0, 16)    # Orange
        time.sleep(0.5)
        send_rgb_command(ser, 128, 0, 255, 16)    # Purple
        time.sleep(0.5)
        send_rgb_command(ser, 0, 255, 128, 16)    # Cyan
        time.sleep(0.5)
        send_rgb_command(ser, 255, 255, 0, 16)    # Yellow
        time.sleep(0.5)
        send_rgb_command(ser, 255, 0, 255, 16)    # Magenta
        time.sleep(0.5)
        
        # Switch to LED 17
        print("\n--- Switching to LED 17 ---")
        send_led_command(ser, 17)
        time.sleep(0.2)
        
        # Test sequence 4: LED 17 colors
        print("\n--- Test Sequence 4: LED 17 Colors ---")
        send_rgb_command(ser, 100, 50, 200, 17)   # Custom color 1
        time.sleep(0.5)
        send_rgb_command(ser, 200, 100, 50, 17)   # Custom color 2
        time.sleep(0.5)
        send_rgb_command(ser, 50, 200, 100, 17)   # Custom color 3
        time.sleep(0.5)
        send_rgb_command(ser, 128, 128, 128, 17)  # Gray
        time.sleep(0.5)
        
        # Return to LED 16
        print("\n--- Returning to LED 16 ---")
        send_led_command(ser, 16)
        time.sleep(0.2)
        send_rgb_command(ser, 255, 255, 255, 16)  # White
        time.sleep(0.5)
        
        print("\n" + "=" * 60)
        print("All commands sent successfully!")
        print("=" * 60)
        
    except serial.SerialException as e:
        print(f"Error: Could not open serial port {COM_PORT}")
        print(f"Details: {e}")
        print("\nMake sure:")
        print("  1. The port COM5 is available")
        print("  2. No other program is using the port")
        print("  3. The device is connected and powered on")
        sys.exit(1)
        
    except KeyboardInterrupt:
        print("\n\nScript interrupted by user")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
        
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("\nSerial port closed")

if __name__ == "__main__":
    main()

