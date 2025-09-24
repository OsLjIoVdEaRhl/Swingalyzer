import asyncio
from bleak import BleakClient, BleakScanner

NOTIFY_UUID = "0000ae02-0000-1000-8000-00805f9b34fb"
WRITE_UUID  = "0000ae01-0000-1000-8000-00805f9b34fb"

async def notification_handler(sender, data):
    print(f"Notification from handle {sender}: {data.hex()}")

async def main():
    print("Scanning for IMU...")
    device = await BleakScanner.find_device_by_name("imu-V3.11")
    if not device:
        print("IMU not found.")
        return

    async with BleakClient(device) as client:
        print("Connected!")

        # Find the *correct* notify characteristic (first one in service 0xAE30)
        notify_char = None
        write_char = None
        for service in client.services:
            if service.uuid.startswith("0000ae30"):  # <- pick the AE30 service
                for char in service.characteristics:
                    if char.uuid == NOTIFY_UUID and "notify" in char.properties:
                        notify_char = char
                    if char.uuid == WRITE_UUID and "write-without-response" in char.properties:
                        write_char = char

        if notify_char is None:
            raise RuntimeError("Notify characteristic not found in AE30 service!")
        if write_char is None:
            raise RuntimeError("Write characteristic not found in AE30 service!")

        print(f"Using notify handle {notify_char.handle}, write handle {write_char.handle}")

        await client.start_notify(notify_char, notification_handler)

        # Example: send command to start streaming (if required)
        await client.write_gatt_char(write_char, b'\x01')  # adjust command for IMU

        print("Listening for notifications... Press Ctrl+C to exit.")
        while True:
            await asyncio.sleep(1)

asyncio.run(main())
