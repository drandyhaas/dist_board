from serial import Serial
from struct import unpack
import time

ser=Serial("COM6",115200,timeout=1.0)
try:
    
    ser.write(bytearray([0])) # firmware version
    result = ser.read(1); byte_array = unpack('%dB' % len(result), result); print "firmware v",byte_array[0]
    
    ser.write(bytearray([4])) # toggle use other clk input
    #ser.write(bytearray([7])) # toggle use full (2 bin) width
    #ser.write(bytearray([11])) # toggle veto pmt last
    
    iter=0
    while (1):        
        
        if iter%2==0: ser.write(bytearray([5])) #increment phase
        #if iter%20==1: 
        #    ser.write(bytearray([6])) #increment phase bin offset
        #    print "phase bin"
        
        ser.write(bytearray([10])) # histo
        result = ser.read(16); byte_array = unpack('%dB' % len(result), result)
        #print byte_array
        myint=[]
        for i in range(4):
            myint.append( byte_array[4*i+0]+256*byte_array[4*i+1]+256*256*byte_array[4*i+2]+0*256*256*256*byte_array[4*i+3] )
        print myint[0],myint[1],myint[2],myint[3]
        
        iter=iter+1
        time.sleep(.3)
except:
    ser.close()

ser.close()
