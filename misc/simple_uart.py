import serial

def send_word(ser, word):
    if word.bit_length() > 32:
        print("only 32 bit instructions are allowed.")
        nop = [0x00, 0x00, 0x00, 0x13]
        ser.write(bytearray(nop))
        exit()
    word_bytes = []
    for i in range(4):
        mask = 0xff << (8 * i)
        res = (word & mask) >> (8 * i)
        word_bytes.append(res)
    ser.write(bytearray(word_bytes))

mem = [0x3fc00093,
       0x0000a023,
       0x0000a103,
       0x00110113,
       0x0020a023,
       0xff5ff06f]

ser = serial.Serial("/dev/ttyACM0", baudrate=115200, timeout=None)

while(1):
    addr = ser.read(4)
    result = int.from_bytes(addr, byteorder="little", signed=False)
    print(f"Received addr: {hex(result)}")
    instr = mem[result >> 2]
    print(f"Instr at {hex(result)}: {hex(instr)}")
    send_word(ser, instr)
