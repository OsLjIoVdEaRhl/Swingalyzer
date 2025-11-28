# What You Can Do Now

## ✅ Feature 1: Connect to Any Movesense Sensor (No Code Editing!)

### Steps:

1. Open the app
2. Tap **"Scan for Devices"**
3. Wait for available devices to appear
4. **Select your Movesense sensor** from the list
5. App automatically detects the UUIDs
6. See **"UUID Detected"** message in the header

### Bonus:

- Tap the **ℹ️ Info button** to see the detected UUIDs
- UUIDs are selectable for copying
- No need to touch any code!

---

## ✅ Feature 2: Record IMU Data

### Steps:

1. Once connected, you're on the Recording Screen
2. Tap **"Start Recording"**
3. The app will capture all IMU data in real-time
4. See data points appear with timestamps
5. **Live statistics**: Data points count, recording status, duration
6. Move your device around to capture different motions

### What Gets Recorded:

- ✓ Acceleration X, Y, Z (m/s²)
- ✓ Rotation/Gyroscope X, Y, Z (°/s)
- ✓ Timestamp of each reading

---

## ✅ Feature 3: Export to CSV (One Tap!)

### Steps:

1. After recording, tap **"Stop Recording"**
2. Tap the blue **"Export"** button
3. Watch the loading spinner
4. Get a notification showing file path
5. **Done!** Your file is in Documents folder

### File Goes To:

- **Android**: Documents folder (access via File Manager)
- **iOS**: App's Documents folder (access via Files app)

### File Name Format:

```
imu_data_1700000000000.csv
         └─ Timestamp for unique names
```

---

## ✅ Feature 4: Access Your Data

### On Android:

1. Open **File Manager** app
2. Navigate to **Documents** folder
3. Look for `imu_data_*.csv` files
4. Long-press to share, copy, or open

### On iOS:

1. Open **Files** app
2. Go to **[App Name]** folder
3. Look for `imu_data_*.csv` files
4. Tap to preview or share

### Share Your Data:

- ✓ Email to colleagues
- ✓ Upload to Google Drive/Dropbox
- ✓ Share via cloud storage
- ✓ Transfer via USB

---

## 📊 What to Do With Your CSV Files

### In Excel/Google Sheets:

```
1. Open the CSV file
2. Data automatically organized in columns:
   - Column A: Timestamp
   - Columns B-D: Acceleration (X, Y, Z)
   - Columns E-G: Rotation (X, Y, Z)
3. Create charts and graphs
4. Analyze patterns
```

### In Python:

```python
import pandas as pd

# Load your data
df = pd.read_csv('imu_data_1700000000000.csv')

# View summary
print(df.describe())

# Plot acceleration over time
df.plot(x='Timestamp', y=['AccelX', 'AccelY', 'AccelZ'])

# Calculate total acceleration magnitude
df['AccelMag'] = (df['AccelX']**2 + df['AccelY']**2 + df['AccelZ']**2)**0.5
```

### In MATLAB:

```matlab
% Load CSV file
data = readtable('imu_data_1700000000000.csv');

% Extract columns
accel = [data.AccelX, data.AccelY, data.AccelZ];
gyro = [data.GyroX, data.GyroY, data.GyroZ];

% Plot
plot(accel);
legend('X', 'Y', 'Z');
```

---

## 🔧 Advanced: View Detected UUIDs

### When Connected:

1. Tap the **ℹ️ Info button** (top-right of recording screen)
2. See your sensor's Service UUID
3. See your sensor's Characteristic UUID
4. Tap to select and copy UUIDs

### Why This Matters:

- Documentation of your specific sensor
- Use UUIDs with other apps
- Share sensor info with developers
- Configure other tools

---

## ❓ Troubleshooting

### "No devices found"

- ✓ Make sure Bluetooth is ON
- ✓ Power on your Movesense sensor
- ✓ Move closer to sensor
- ✓ Tap "Scan for Devices" again

### "Export button disabled"

- ✓ Make sure you recorded some data first
- ✓ Stop recording before exporting
- ✓ Try again if it was still exporting

### "Can't find CSV file"

- ✓ Check Documents folder
- ✓ On Android: Use File Manager, go to Documents
- ✓ On iOS: Use Files app
- ✓ File name starts with "imu*data*"

### "Export failed"

- ✓ Check phone has free storage space
- ✓ Make sure app has permissions (check Settings)
- ✓ Try exporting again

---

## 📋 Quick Reference

| Feature          | How to Use                  | Result                |
| ---------------- | --------------------------- | --------------------- |
| **Scan Devices** | Tap "Scan for Devices"      | See available sensors |
| **Connect**      | Select sensor from list     | Auto UUID detection   |
| **View UUIDs**   | Tap ℹ️ Info button          | See detected UUIDs    |
| **Record**       | Tap "Start Recording"       | Collect IMU data      |
| **Stop**         | Tap "Stop Recording"        | End session           |
| **Export**       | Tap "Export" button         | Save CSV file         |
| **Access File**  | Open File Manager/Files app | Use your data         |

---

## 🎉 You're All Set!

Everything is ready to use. No code editing needed. Just:

1. ✅ Connect to your sensor
2. ✅ Record data
3. ✅ Export to CSV
4. ✅ Analyze your data

**Enjoy!**

---

## Need Help?

Check these files:

- **NEW_FEATURES.md** - Detailed feature guide
- **QUICKSTART.md** - Step-by-step instructions
- **FINAL_SUMMARY.md** - Overview of changes
