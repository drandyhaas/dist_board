import time
from serial import Serial

serialtimeout=1.0
ser=Serial("COM7",921600,timeout=serialtimeout)

# read firmware version
ser.write(bytearray([0]))
fwversion = ord(ser.read(1))
print(fwversion)

# toggle output enable for 1 second
ser.write(bytearray([3]))
time.sleep(1)
ser.write(bytearray([3]))

ser.close()
