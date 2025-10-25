import asyncio
from bleak import BleakClient, BleakScanner
from bleak.backends.characteristic import BleakGATTCharacteristic
from array import array
import numpy as np
import time  # Added to introduce delay

# Characteristic UUID of the device
# par_notification_characteristic="0000ae02-0000-1000-8000-00805f9b34fb"
par_notification_characteristic= "0000ae02-0000-1000-8000-00805f9b34fb"
# Characteristic UUID of the device (with write attribute Write)
# par_write_characteristic="0000ae01-0000-1000-8000-00805f9b34fb"

par_write_characteristic = "0000ae01-0000-1000-8000-00805f9b34fb"

par_device_addr="E6:6F:24:E5:83:9F" # MAC address of the device You need to fill in the mac address of the device here

def notification_handler(characteristic: BleakGATTCharacteristic, data: bytearray):
    parse_imu(data)

def parse_imu(buf):
    scaleAccel       = 0.00478515625      # acceleration [-16g~+16g]
    scaleAngleSpeed  = 0.06103515625      # Angular velocity [-2000~+2000]
    scaleAngle       = 0.0054931640625    # Angle scale (example value)

    if buf[0] != 0x11:
        return  # ignore invalid data

    ctl = (buf[2] << 8) | buf[1]
    L = 7  # start index for sensor data

    # Acceleration without gravity
    if ctl & 0x0001:
        ax = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAccel; L += 2
        ay = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAccel; L += 2
        az = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAccel; L += 2
        #print(f"Acceleration (g): ax={ax:.3f}, ay={ay:.3f}, az={az:.3f}")
        time.sleep(0.01)  # Added delay

    # Gyroscope
    if ctl & 0x0004:
        gx = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngleSpeed; L += 2
        gy = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngleSpeed; L += 2
        gz = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngleSpeed; L += 2
        #print(f"Gyroscope (°/s): gx={gx:.3f}, gy={gy:.3f}, gz={gz:.3f}")
        time.sleep(0.01)  # Added delay
    # Angle
    if ctl & 0x0008:
        ax = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngle; L += 2
        ay = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngle; L += 2
        az = np.short((np.short(buf[L+1]) << 8) | buf[L]) * scaleAngle; L += 2
        print(f"Angle (°): ax={ax:.3f}, ay={ay:.3f}, az={az:.3f}")
        time.sleep(0.01)  # Added delay

async def main():
    print("starting scan...")

    # Find devices based on MAC address
    device = await BleakScanner.find_device_by_address(
        par_device_addr, cb=dict(use_bdaddr=False)
    )
    if device is None:
        print("could not find device with address '%s'" % par_device_addr)
        return

    # Event definition
    disconnected_event = asyncio.Event()

    # Disconnect callback
    def disconnected_callback(client):
        print("Disconnected callback called!")
        disconnected_event.set()

    print("connecting to device...")
    async with BleakClient(device, disconnected_callback=disconnected_callback) as client:
        print("Connected")

        # ----------------------
        # Resolve notify characteristic
        notify_char = None
        for service in client.services:
            for char in service.characteristics:
                if char.uuid == par_notification_characteristic and "notify" in char.properties:
                    if service.uuid.startswith("0000ae30"):  # choose AE30 version
                        notify_char = char

        if notify_char is None:
            raise RuntimeError("Notify characteristic not found in AE30 service!")

        await client.start_notify(notify_char, notification_handler)
        # ----------------------

        # ----------------------
        # Resolve write characteristic
        write_char = None
        for service in client.services:
            if service.uuid.startswith("0000ae30"):
                for char in service.characteristics:
                    if char.uuid == par_write_characteristic and ("write" in char.properties or "write-without-response" in char.properties):
                        write_char = char

        if write_char is None:
            raise RuntimeError("Write characteristic not found in AE30 service!")
        # ----------------------

        # Stay connected: send wakestr
        wakestr = bytes([0x29])
        await client.write_gatt_char(write_char, wakestr)
        await asyncio.sleep(0.2)

        print("------------------------------------------------")
        # High-speed communication feature
        fast = bytes([0x46])
        await client.write_gatt_char(write_char, fast)
        await asyncio.sleep(0.2)

        # Parameter settings
        isCompassOn = 0
        barometerFilter = 2
        Cmd_ReportTag = 0x7F
        params = bytearray([0x00 for _ in range(11)])
        params[0] = 0x12
        params[1] = 5
        params[2] = 255
        params[3] = 0
        params[4] = ((barometerFilter & 3) << 1) | (isCompassOn & 1)
        params[5] = 60
        params[6] = 1
        params[7] = 3
        params[8] = 5
        params[9] = Cmd_ReportTag & 0xFF
        params[10] = (Cmd_ReportTag >> 8) & 0xFF
        await client.write_gatt_char(write_char, params)
        await asyncio.sleep(0.2)

        # Notes command
        notes = bytes([0x19])
        await client.write_gatt_char(write_char, notes)

        # Keep program running while receiving data
        while not disconnected_event.is_set():
            await asyncio.sleep(1.0)


asyncio.run(main())
