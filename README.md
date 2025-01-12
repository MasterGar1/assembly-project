# Encryption and Decryption Algorithms in Assembly

This project contains a set of encryption and decryption algorithms implemented in Assembly language using TASM (Turbo Assembler). The program reads a message from a file, applies a series of encryption or decryption algorithms, and writes the result to another file.

## Algorithms

### Algorithm 1: Mid Shuffle (Removed as is too simple)
- **Encryption**: Swaps characters in the message such that `ems(message[i]) = message[l >> 1 + l % 2 + i]`.
- **Decryption**: Same as encryption.

### Algorithm 2: Odd Caesar
- **Encryption**: Modifies each character based on its parity:
  - If even: `message[i] + 7`
  - If odd: `message[i] - 7`
- **Decryption**: Same as encryption.

### Algorithm 3: Key Difference
- **Encryption**: Uses a predefined key to modify each character: `ekd(message[i]) = (256 + key[i] - message[i]) % 256`.
- **Decryption**: Same as encryption.

### Algorithm 4: Symmetric Offset
- **Encryption**: Modifies characters symmetrically from both ends:
  - If `message[i] == message[j]`: `(message[i] - 99, message[j] - 99)`
  - Otherwise: `(message[i] + 99, message[j] + 99)`
- **Decryption**: Same as encryption but with reversed conditions.

## Files

- `init.txt`: Input file containing the message to be encrypted or decrypted. 
- `crypt.txt`: Output file where the encrypted or decrypted message is saved.

## Usage

1. **Compile the Assembly Code**:
   Use TASM to compile the `proj.asm` file:
   ```bash
   tasm proj
   tlink proj
   ```

2. **Run the Program**:
   Execute the compiled program:
   ```bash
   proj
   ```

3. **Input Commands**:
   - `1`: Encrypt the message.
   - `2`: Decrypt the message.
   - `0`: Exit the program.

## Notes

- Ensure the input file `init.txt` is present in the same directory as the executable.
- The maximum length of the message is 200 characters.
- The encryption key is hardcoded and should not be changed.

## License

This project is licensed under the MIT License.
