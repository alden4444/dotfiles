- A signed integer is one that can hold negative, positive and zero values rather than just positive and zero
- Two's complement is the standard method used by computers to represent signed integers in binary
- Used to represent negative numbers
- Example: 100111 is negative as it starts with 1 and 011010 is positive as it starts with 0 so there's no negative weight in the binary string

1. Calculate hexadecimal number corresponding to 10010101 00110011

Split into 4 nibbles:
1001 = 9
0101 = 5
0011 = 3
0011 = 3
= 9533

2. One example of when hexadecimal representation is used

IPv6 addresses

3. Give two advantages of representing signed integers in two's complement form rather than using a sign and magnitude representation

- Only one representation of zero rather than +0 (00000000) and -0 (10000000) which wastes a bit pattern rather than just (00000000) in two's complement form
- Addition and subtraction can use the exact same binary adder circuit in two's complement without needing dedicated subtraction hardware or logic

4. Give three different examples of options for the the types of information that could be represented by two bytes. For each, state whether a representation requires two bits at a time, just one byte or only part of a byte each time.

- Text which requires 2 bytes at a time (16 bits) in UTF-16 (unicode)
- Binary Coded Decimal (BCD) which encodes decimal numbers where each digit from 0 to 9 is stored as a 4-bit nibble. Only half of a byte required (4 bits)
- Boolean only requires part of a byte (1 bit)

5. Describe a use of Binary Coded Decimal (BCD) representation 

Electronic systems that display exact decimal numbers such as digital clocks
