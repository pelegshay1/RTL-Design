# 🚀 8-Bit Ripple-Carry Adder Implementation and Comparison

## 📝 Objective

This repository contains the implementation and comparison of an 8-bit ripple-carry adder using two distinct Verilog design methodologies: **Behavioral** and **Structural**. The goal of this lab is to verify the functional equivalence and understand the different abstraction levels in hardware description languages.

The adder performs the operation: $\text{Sum}[7:0], \text{Cout} = \text{a}[7:0] + \text{b}[7:0] + \text{Cin}$.

---

## 📁 Project Structure

The project is organized into the following essential files:

| File Name | Description |
| :--- | :--- |
| `top-level.v` | The top-level module instantiating the adder and connecting it to I/O ports. [cite_start]Hardwires $\text{Cin}$ to 0[cite: 44]. |

| `ripple_adder_8bit_behave.v` | [cite_start]**Behavioral Implementation:** Defines the full adder using a high-level addition operator (`assign {cout, sum} = a + b + {1'b0, cin};`) and cascades them to form the 8-bit adder[cite: 48, 49]. |

| `reipple_adder_8bit_struct.v` | [cite_start]**Structural Implementation:** Defines the full adder using combinational logic equations (`a ^ b ^ cin`, etc.) and instantiates eight instances, explicitly wiring the intermediate carries ($c_1$ to $c_7$)[cite: 27, 29]. |

| `tb.v` | The **Testbench** module used for verification. [cite_start]It instantiates both the Behavioral and Structural adders and applies a set of five mandatory test vectors[cite: 34, 35]. |

| `constraints.xdc` | [cite_start]Xilinx Design Constraints file mapping the 8-bit inputs ($\text{a}, \text{b}$) to physical switches and the 8-bit output ($\text{sum}$) and $\text{cout}$ to physical LEDs[cite: 1, 9, 17, 25]. |

---

## 🧪 Testbench Verification (tb.v)

The testbench is designed to simulate both implementations concurrently and compare their results. [cite_start]The following test cases are included[cite: 37, 39, 40, 41, 42]:


| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. No carry-out** | Simple addition, no flags set. | `01` | `02` | `0` | $03 / 0$ |
| **2. With carry-out** | Signed overflow (Pos. $\to$ Neg.) $\text{Cout}=0$, $\text{C}_{in}(MSB)=1$ | `7F` | `01` | `0` | $80 / 0$ |
| **3. Max value** | Max 8-bit unsigned value, no $\text{Cout}$. | `FF` | `00` | `0` | $FF / 0$ |
| **4. Max overflow** | Unsigned Overflow $\text{Cout}=1$. | `FF` | `01` | `0` | $00 / 1$ |
| **5. Zero** | Trivial case. | `00` | `00` | `0` | $00 / 0$ |

### 🔍 Note on Carry and Overflow (Based on provided Testbench):

* The test case labeled **"With carry-out"** (`7F` + `01` = `80`) results in $\text{Cout}=0$. When interpreting the numbers as **signed** (Two's Complement), this specific case results in a **Positive Overflow** ($+127 + 1 = -128$).
* The test case labeled **"Max overflow"** (`FF` + `01` = `00`) results in $\text{Cout}=1$. When interpreting the numbers as **unsigned**, this specific case results in an **Unsigned Overflow** (carry-out).
