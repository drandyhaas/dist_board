from serial import Serial
from struct import unpack
import time
import random

ser=Serial("COM7",921600,timeout=1.0)

ser.write(bytearray([0])) # firmware version
result = ser.read(1); byte_array = unpack('%dB' % len(result), result); print("firmware v",byte_array[0])

time.sleep(.5)

def setrngseed():
    random.seed()
    b1 = random.randint(0, 255)
    b2 = random.randint(0, 255)
    b3 = random.randint(0, 255)
    b4 = random.randint(0, 255)
    ser.write(bytearray([6, b1, b2, b3, b4]))
    print("set trigboard random seed to", b1, b2, b3, b4)

def set_inputmask(m1,m2,m3,m4,m5,m6,m7,m8): # input mask for each set of 8 inputs (0-7,8-15,...)
    # ff would be unmasked, 0 would be masked
    m1 = int(m1,base=16)
    m2 = int(m2, base=16)
    m3 = int(m3, base=16)
    m4 = int(m4, base=16)
    m5 = int(m5, base=16)
    m6 = int(m6, base=16)
    m7 = int(m7, base=16)
    m8 = int(m8, base=16)
    ser.write(bytearray([14,m1,m2,m3,m4,m5,m6,m7,m8]))
    print("set input mask to",hex(m1),hex(m2),hex(m3),hex(m4),hex(m5),hex(m6),hex(m7),hex(m8))

def set_prescale(prescale):  # takes a float from 0-1 that is the fraction of events to pass
    if prescale > 1.0 or prescale < 0.0:
        print("bad prescale value,", prescale)
        return
    prescaleint = int((pow(2, 32) - 1) * prescale)
    b4 = int(prescaleint / 256 / 256 / 256) % 256
    b3 = int(prescaleint / 256 / 256) % 256
    b2 = int(prescaleint / 256) % 256
    b1 = int(prescaleint) % 256
    ser.write(bytearray([7, b1, b2, b3, b4]))
    print("set trigboard prescale to", prescale, " - will pass", prescaleint, "out of every 4294967295", ", bytes:", b1, b2, b3, b4)

def get_histos(h):
    ser.write(bytearray([2, h]))  # set histos to be from channel h
    ser.write(bytearray([10]))  # get histos
    res = ser.read(32)
    b = unpack('%dB' % len(res), res)
    mystr = "histos for "
    mystr+=str(h)
    mystr+=": "
    myint = []
    for i in range(8):
        myint.append(b[4 * i + 0] + 256 * b[4 * i + 1] + 256 * 256 * b[4 * i + 2] + 0 * 256 * 256 * 256 * b[4 * i + 3])
        mystr += str(myint[i]) + " "
        if i == 3: mystr += ", "
    return mystr, myint

setrngseed()
set_prescale(0.3)

set_inputmask("ff","ff","00","00","00","00","00","00") # use just the first 16 inputs

for his in range(64):
    histostr, histo = get_histos(his)
    if histo[0]>0: print(histostr)

ser.close()
