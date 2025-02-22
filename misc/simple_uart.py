import serial
import time

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

mem = [0] * 256
mem[0] = 0x3fc00093
mem[1] = 0x0000a023
mem[2] = 0x0000a103
mem[3] = 0x00110113
mem[4] = 0x0020a023
mem[5] = 0xff5ff06f

ser = serial.Serial("/dev/ttyACM0", baudrate=115200, timeout=None)

start = 0
while(mem[255] != 255):
    com = ser.read(1)
    if start == 0:
        start = time.time()
    addr = ser.read(4)
    res_com = int.from_bytes(com, byteorder="little", signed=False)
    if (res_com & 0xf0) == 0x20:
        data = ser.read(4)
        res_addr = int.from_bytes(addr, byteorder="little", signed=False)
        res_data = int.from_bytes(data, byteorder="little", signed=False)

        wstrb = ['0', '0', '0', '0']
        mem[res_addr >> 2] = 0
        if res_com & 0x01:
            mem[res_addr >> 2] |= (res_data & 0x000000ff)
            wstrb[0] = '1'
        if res_com & 0x02:
            mem[res_addr >> 2] |= (res_data & 0x0000ff00)
            wstrb[1] = '1'
        if res_com & 0x04:
            mem[res_addr >> 2] |= (res_data & 0x00ff0000)
            wstrb[2] = '1'
        if res_com & 0x08:
            mem[res_addr >> 2] |= (res_data & 0xff000000)
            wstrb[3] = '1'

        wstrb_s = "".join(wstrb)
        print(f"[wr {res_addr:08x}] {res_data:08x} (wstrb={wstrb_s})")
        ser.write(b'\xc8')
    elif res_com == 0x77:
        res_addr = int.from_bytes(addr, byteorder="little", signed=False)
        data = mem[res_addr >> 2]
        print(f"[rd {res_addr:08x}] {data:08x}")
        send_word(ser, data)
    else:
        print("Bad command!");
print(f"Completed in {time.time() - start}")
ser.close()
