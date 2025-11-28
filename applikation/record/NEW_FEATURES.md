# New Features - Auto UUID Detection & CSV Export

## Overview

The Movesense IMU recording system has been updated with two major improvements:

1. **Automatic UUID Detection** - No more manual UUID editing needed
2. **Automatic CSV Export** - Data exports directly to your phone's documents folder

## Automatic UUID Detection

### How It Works

When you connect to a Movesense sensor, the app automatically:

1. Discovers all services on the device
2. Finds the characteristic with notify capability
3. Detects and stores the Service UUID and Characteristic UUID
4. Displays a confirmation that "UUID Detected"

### Viewing Detected UUIDs

While recording, you can view the detected UUIDs by:

1. Looking at the recording screen header
2. Tapping the **ℹ️ Info button** (in the top-right corner)
3. A dialog will show:
   - Service UUID
   - Characteristic UUID
4. The UUIDs are selectable/copyable for documentation

### Benefits

- ✅ No code editing required
- ✅ Works with any Movesense sensor variant
- ✅ Automatic sensor detection
- ✅ Documentation of your sensor's UUIDs

## CSV Data Export

### What Gets Exported

The CSV file contains all recorded IMU data:

- **Timestamp**: When each reading was captured
- **AccelX, AccelY, AccelZ**: Acceleration values (m/s²)
- **GyroX, GyroY, GyroZ**: Rotation/gyroscope values (°/s)

### How to Export

1. **Stop Recording** (tap "Stop Recording" button)
2. **Tap Export** (the blue "Export" button)
3. **Wait for completion** - A notification will appear
4. **File location** - Automatically saved to your phone's Documents folder

### File Naming

Files are named with timestamps for easy organization:

```
imu_data_1700000000000.csv
```

The timestamp ensures each export has a unique filename.

### CSV Format Example

```csv
Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ
2024-11-20T10:30:45.123,0.123,0.456,9.812,0.001,0.002,-0.003
2024-11-20T10:30:45.234,0.125,0.458,9.815,0.001,0.002,-0.003
2024-11-20T10:30:45.345,0.127,0.460,9.818,0.001,0.002,-0.003
```

### Accessing Your Files

**On Android:**

1. Open File Manager
2. Navigate to: `Documents` or `/storage/emulated/0/Documents/`
3. Look for `imu_data_*.csv` files

**On iOS:**

1. Use the Files app
2. Navigate to: App's Documents folder
3. Look for `imu_data_*.csv` files

Or use any file transfer method:

- USB file transfer
- Cloud storage (Google Drive, OneDrive, iCloud)
- Email
- Bluetooth file transfer

### Using the CSV Files

The exported CSV files can be:

- ✅ Imported into Excel/Google Sheets
- ✅ Analyzed with Python/MATLAB
- ✅ Plotted with visualization tools
- ✅ Processed with machine learning libraries
- ✅ Shared with researchers or colleagues

### Example Analysis (Python)

```python
import pandas as pd

# Load the data
df = pd.read_csv('imu_data_1700000000000.csv')

# Basic statistics
print(df.describe())

# Plot acceleration
df.plot(x='Timestamp', y=['AccelX', 'AccelY', 'AccelZ'])

# Calculate magnitude
df['AccelMagnitude'] = (
    df['AccelX']**2 + df['AccelY']**2 + df['AccelZ']**2
).apply(lambda x: x**0.5)
```

## Device Scanning (Already Implemented)

The device scanning feature was already in place:

1. **Tap "Scan for Devices"** on the home screen
2. A list of available Bluetooth devices appears
3. **Select your Movesense sensor** from the list
4. **Automatic connection** with UUID detection
5. **Ready to record** - No manual UUID entry needed!

## Technical Details

### Auto-Detection Logic

The service scans for characteristics with:

- `notify` capability enabled
- Readable/notifiable properties
- Non-empty UUID

The first matching characteristic is assumed to be the IMU data stream.

### Export Implementation

The export function:

1. Reads all recorded `IMUData` objects
2. Converts each to CSV format
3. Writes to a file in the documents directory
4. Shows the file path in a notification

### File Permissions

The app uses `path_provider` package which handles:

- Android: `getApplicationDocumentsDirectory()`
- iOS: `getApplicationDocumentsDirectory()`
- Automatic permission handling

## Troubleshooting

### Export Button Disabled?

- Make sure you have recorded some data
- The button will show "Export" when ready
- Stops being disabled after successful export

### Can't Find CSV Files?

1. Check the file path shown in the notification
2. On Android, check: Settings > Apps > Permissions > Storage
3. Try looking in: Documents, Downloads, or the app folder
4. Use a file manager app to search for `imu_data_*.csv`

### Export Failed?

- Ensure device has storage space
- Check that app has write permissions
- Try again or check console logs

### UUID Shows "Not Detected"?

- Reconnect to the sensor
- Ensure sensor is actively streaming data
- Try a different Movesense sensor model

## Summary of Changes

### What Changed

1. ✅ Removed hardcoded UUIDs
2. ✅ Added automatic UUID detection
3. ✅ Implemented CSV export to documents folder
4. ✅ Added UUID display dialog
5. ✅ Added export progress indicator

### What Stayed the Same

1. Device scanning
2. Real-time recording
3. Data visualization
4. Disconnect functionality

### New Dependencies

- `path_provider: ^2.1.0` - For documents folder access

## Next Steps

The app is now fully functional with:

- 🎯 Automatic sensor detection
- 🎯 No manual configuration needed
- 🎯 Easy data export
- 🎯 File management-ready

Just connect to your sensor and start recording!
