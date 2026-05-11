import serial
import struct
import time
import os

# ================= Configs =================
PORT = 'COM11'  
BAUD_RATE = 115200

INSTRUCTIONS_FILE = '../../software/Bubble_11_elements_CSR/BubbleSort_code.txt'
DATA_FILE = '../../software/Bubble_11_elements_CSR/BubbleSort_data.txt'
# =================================================

def parse_and_send(file_path, serial_connection):
    """ Read file txt, get the address and data, send via UARt with the bootloader protocol (ACK) """

    if not os.path.exists(file_path):
        print(f"[WARNING] File '{file_path}' not found...")
        return True

    print(f"\n--- Processing File: {file_path} ---")
    
    with open(file_path, 'r') as f:
        lines = f.readlines()

    sent_lines = 0

    for line_number, line in enumerate(lines, 1):
        line = line.strip()
        
        # Ignore empty lines and header
        if not line or not line.startswith("0x"):
            continue

        parts = line.split()
        address_str = parts[0]
        data_str = parts[1]

        try:
            address_int = int(address_str, 16)
            data_int = int(data_str, 16)
            
            # STEP 1: Pack for 32 bits binary (Little-Endian)
            address_pack = struct.pack('<I', address_int)
            address_data = struct.pack('<I', data_int)
            
            # STEP 2: Send to FPGA
            serial_connection.write(address_pack)
            serial_connection.write(address_data)
            serial_connection.flush()
            
            # STEP 3: Wait for ACK ('0x01')
            ack = serial_connection.read(1)
            
            if ack == b'\x01':
                print(f"[OK] Address: {address_str} | Written: {data_str}")
                sent_lines += 1
            elif ack == b'':
                print(f"[ERROR] Timeout at address {address_str}! The FPGA didn't respond.")
                return False
            else:
                print(f"[ERROR] Unexpected ACK ({ack}) at address {address_str}.")
                return False

        except ValueError:
            print(f"[FORMAT ERROR] Error in the line {line_number}: '{line}'")
            continue

    print(f"--- Completed: {sent_lines} words stored from {file_path} ---")
    return True

# ================= Main Execution =================
try:
    print(f"Opening connection in {PORT} with {BAUD_RATE} bps...")
    
    with serial.Serial(PORT, BAUD_RATE, timeout=3) as ser:
        time.sleep(1) # Pause for stabilize the port
        
        # 1. UPLOAD (Write in FPGA)
        success_inst = parse_and_send(INSTRUCTIONS_FILE, ser)
        success_dados = parse_and_send(DATA_FILE, ser)
        
        # # 2. MONITORING / DUMP OF MEMORY (Read from FPGA)
        if success_inst and success_dados:

            # Warns that the FPGA finished (Address 0xFFFFFFFF and Data 0x00000000)
            ser.write(struct.pack('<I', 0xFFFFFFFF))
            ser.write(struct.pack('<I', 0x00000000)) 
            ser.flush()

            final_ack = ser.read(1)
            print(f"End command sent. ACK received: {final_ack.hex()}")

            print("\n" + "="*65)
            print("UPLOAD COMPLETED WITH SUCCESS!")
            print("Entering in DUMP OF MEMORY MODE (Press Ctrl+C to exit)")
            print("Start the signal 'mem_scan' in FPGA now...")
            print("="*65 + "\n")
            
            # Clean any "trash" that stay in buffer
            ser.reset_input_buffer()
            
            # Start address 0x10010000
            current_address = 0x10010000
            
            while True:
                # Read 4 in 4 bytes (1 word of 32 bits)
                if ser.in_waiting >= 4:
                    
                    # Read 4 bytes in the buffer
                    bytes_pack = ser.read(4)
                    
                    # Little-Endian ('<') for Integer Unsigned 32-bits ('I')
                    data_32bits = struct.unpack('<I', bytes_pack)[0]
                    
                    print(f"Address 0x{current_address:08X} | Hex: 0x{data_32bits:08X} | Dec: {data_32bits}")
                    
                    # Next address
                    current_address += 4
                    
                time.sleep(0.001)

except serial.SerialException as e:
    print(f"\n[FATAL ERROR] The serial port could not be opened: {e}")
except KeyboardInterrupt:
    print("\n\n[WARNING] Connection closed by user.")