# Android Permissions Fix for Bluetooth Scanning

If you see the error **"Permission android.permission.BLUETOOTH_SCAN required"** when trying to scan for devices, follow these steps:

## Quick Fix

The app now provides a helpful error message with detailed instructions. When you see the permission error:

1. **Tap "Try Again"** to attempt scanning again
2. **If error persists**, manually grant permissions:

### For Android 12 and above (Recommended)

1. Go to **Settings**
2. Navigate to **Apps** (or **Applications**)
3. Find and tap **Record** app
4. Select **Permissions**
5. Enable the following:
   - **Bluetooth** - Allow
   - **Location** - Allow (required for Bluetooth scanning on some Android versions)
   - **Nearby Devices** - Allow (if available)

### For Android 11 and below

1. Go to **Settings**
2. Navigate to **Apps** or **Application Manager**
3. Find **Record** app
4. Select **Permissions**
5. Enable:
   - **Location** - Allow

## What Changed in the Code

The app now:

- ✅ Shows a clear error message when permissions are denied
- ✅ Provides step-by-step instructions in the app UI
- ✅ Allows you to retry scanning after granting permissions
- ✅ Detects permission errors and displays an appropriate icon and message

## Manifest Permissions

The app has the following permissions declared in `AndroidManifest.xml`:

- `android.permission.BLUETOOTH` - Connect to Bluetooth devices
- `android.permission.BLUETOOTH_ADMIN` - Initiate Bluetooth connections
- `android.permission.BLUETOOTH_SCAN` - Scan for Bluetooth devices (Android 12+)
- `android.permission.BLUETOOTH_CONNECT` - Connect to already-paired devices (Android 12+)
- `android.permission.ACCESS_FINE_LOCATION` - Precise location for BLE scanning
- `android.permission.ACCESS_COARSE_LOCATION` - Approximate location for BLE scanning

These are necessary for the Movesense sensor to work properly.

## Testing

After granting permissions:

1. Open the Record app
2. Tap "Scan for Devices"
3. Your Movesense sensor should appear in the list
4. Tap to connect and start recording IMU data

## Still Having Issues?

If permissions are enabled but scanning still fails:

- **Restart the app** - This ensures the new permissions are loaded
- **Restart your device** - Sometimes Android needs a reboot to apply permissions
- **Check Bluetooth is enabled** - Make sure Bluetooth is turned on in device settings
- **Check sensor is powered on** - Ensure your Movesense sensor is powered and in pairing mode
