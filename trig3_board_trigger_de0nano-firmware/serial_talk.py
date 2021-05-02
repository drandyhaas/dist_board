from serial import Serial
from struct import unpack
import time

ser=Serial("COM21",115200,timeout=1.0)

ser.write(bytearray([0])) # firmware version
result = ser.read(1); byte_array = unpack('%dB' % len(result), result); print("firmware v",byte_array[0])

wantactiveclock = True # True for wanting sync with external clock
ser.write(bytearray([8]))  # active clock info
result = ser.read(1)
byte_array = unpack('%dB' % len(result), result);
print("using external active clock", bin(byte_array[0]))
if wantactiveclock and not byte_array[0]:
    ser.write(bytearray([4]))  # toggle use other clk input
    time.sleep(.1)
if not wantactiveclock and byte_array[0]:
    ser.write(bytearray([4]))  # toggle use other clk input
    time.sleep(.1)
ser.write(bytearray([8]))  # active clock info
result = ser.read(1)
byte_array = unpack('%dB' % len(result), result);
print("using external active clock", bin(byte_array[0]))
time.sleep(.1)

for myiter in range(60):

    if myiter%2==0: ser.write(bytearray([5])) #increment phase
    time.sleep(.5)

    ser.write(bytearray([11]))  # delaycounter trigger info
    result = ser.read(1)
    byte_array = unpack('%dB' % len(result), result);
    print("delaycounter", bin(byte_array[0]))
    #if byte_array[0]>0: continue

    ser.write(bytearray([10])) # histo
    result = ser.read(32); byte_array = unpack('%dB' % len(result), result)
    myint=[]
    for i in range(8):
        myint.append( byte_array[4*i+0]+256*byte_array[4*i+1]+256*256*byte_array[4*i+2]+0*256*256*256*byte_array[4*i+3] )
    print(myint[0],myint[1],myint[2],myint[3],myint[4],myint[5],myint[6],myint[7])

ser.close()
