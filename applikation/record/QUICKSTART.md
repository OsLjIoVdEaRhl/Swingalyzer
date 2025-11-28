# Quick Start Guide - Movesense IMU Recording

## What You Need

- Flutter app running on an Android or iOS device
- Movesense sensor (powered on)
- Bluetooth enabled on your mobile device

## Step-by-Step Instructions

### 1. Launch the App

Start the Swingalyzer record application on your device.

### 2. Scan for Devices

- You'll see the home screen with a "Scan for Devices" button
- Ensure your Movesense sensor is **powered on**
- Tap **"Scan for Devices"**
- The app will search for nearby Bluetooth sensors

### 3. Select Your Sensor

- A list of available devices will appear
- Select your **Movesense sensor** from the list
- The app will attempt to connect
- Wait for the "Connected" confirmation

### 4. Start Recording

- Once connected, you'll see the **Recording Screen**
- The header shows your connected device name
- A green dot indicates active connection
- Tap **"Start Recording"** to begin capturing IMU data

### 5. Monitor Data

While recording, you'll see:

- **Data Points**: Number of readings captured
- **Status**: "Recording" or "Stopped"
- **Duration**: How long the session has been running
- **Live Data Display**: Each sensor reading with acceleration and rotation values

### 6. Stop Recording

- When finished, tap **"Stop Recording"**
- Your data will be preserved on screen

### 7. Export Data (Coming Soon)

- Tap **"Export"** to save your data as CSV
- (Feature coming in next update)

### 8. Disconnect

- Tap **"Disconnect"** when done
- This returns you to the home screen
- You can connect to a different sensor or end the session

## Sensor Data Explained

### Acceleration (m/s²)

- **X, Y, Z**: Linear movement in three axes
- Typical range: -50 to +50 m/s²
- Shows device tilt and movement

### Rotation (°/s)

- **X, Y, Z**: Angular velocity in three axes
- Typical range: -500 to +500 °/s
- Shows device rotation speed

### Timestamp

- **Time**: When the reading was captured
- Used for synchronizing with other data sources

## Common Issues & Solutions

| Issue              | Solution                                              |
| ------------------ | ----------------------------------------------------- |
| "No devices found" | Ensure sensor is powered on, try scanning again       |
| Connection fails   | Move closer to sensor, restart the sensor             |
| No data appearing  | Check sensor is actively streaming, reconnect         |
| App crashes        | Restart app, ensure Bluetooth permissions are granted |

## Tips for Better Recordings

1. **Stable Connection**: Stay within 5-10 meters of the sensor
2. **Clear Environment**: Avoid heavy Bluetooth interference
3. **Fresh Battery**: Ensure sensor has adequate battery
4. **Consistent Movement**: Slow, steady movements for best results
5. **Multiple Readings**: Capture longer sessions for better analysis

## Permission Requirements

The app needs these permissions:

- **Bluetooth**: To connect to Movesense sensor
- **Location** (Android): Required for BLE scanning
- **Storage** (when exporting): To save CSV files

## FAQ

**Q: Can I record from multiple sensors?**
A: Currently, the app records from one sensor at a time. Sequential recording is supported.

**Q: How long can I record?**
A: Recording duration depends on your device's memory. Expect 10,000+ data points on typical devices.

**Q: What happens if Bluetooth disconnects?**
A: Data is preserved. Reconnect and the recording session continues.

**Q: Can I edit the sensor UUIDs?**
A: Yes. Edit `lib/services/movesense_service.dart` with your sensor's UUIDs.

## Getting Help

For detailed technical information, see `MOVESENSE_GUIDE.md` in the project root.
