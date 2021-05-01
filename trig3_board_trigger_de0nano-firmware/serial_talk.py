from serial import Serial
from struct import unpack
import time

ser=Serial("COM21",115200,timeout=1.0)

ser.write(bytearray([0])) # firmware version
result = ser.read(1); byte_array = unpack('%dB' % len(result), result); print("firmware v",byte_array[0])

#ser.write(bytearray([4])) # toggle use other clk input

for myiter in range(100):

    #if myiter%2==0: ser.write(bytearray([5])) #increment phase
    time.sleep(.3)

    ser.write(bytearray([11]))  # delaycounter trigger info
    result = ser.read(1);
    byte_array = unpack('%dB' % len(result), result);
    print("delaycounter", byte_array[0])

    ser.write(bytearray([10])) # histo
    result = ser.read(16); byte_array = unpack('%dB' % len(result), result)
    myint=[]
    for i in range(4):
        myint.append( byte_array[4*i+0]+256*byte_array[4*i+1]+256*256*byte_array[4*i+2]+0*256*256*256*byte_array[4*i+3] )
    print(myint[0],myint[1],myint[2],myint[3])

ser.close()
