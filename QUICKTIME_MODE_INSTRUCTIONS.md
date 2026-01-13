# QuickTime Mode - Workaround for Authorization Issues

Since your iPhone won't prompt for direct authorization, we've implemented a workaround that uses **QuickTime Player** as an intermediary.

## How It Works

1. QuickTime Player (already authorized by your iPhone) displays the iPhone screen
2. Your app captures QuickTime's window using ScreenCaptureKit
3. The captured content is displayed in your translucent window
4. Screen recording protection still works (QuickTime's window is excluded from captures)

## Setup Instructions

### Step 1: Start QuickTime with iPhone Screen
1. **Open QuickTime Player**
2. Go to **File** → **New Movie Recording**
3. Click the dropdown next to the record button
4. Select **"Bhaveek's iPhone"** (the screen option, not camera)
5. You should see your iPhone's screen in QuickTime
6. **Position the QuickTime window** - it can be anywhere on screen
7. You can **minimize** QuickTime or move it off-screen

### Step 2: Run Your App
1. In Xcode, press **Cmd + R** to build and run
2. When you see the "Authorization Blocked" error
3. **Two ways to activate QuickTime Mode:**
   - Click the **"Use QuickTime Mode"** button, OR
   - Press **Control + Option + Command + H** (keyboard shortcut)
4. Your app will now capture from QuickTime

### Step 3: Grant Screen Recording Permission (One Time)
macOS will prompt: **"iphone would like to record this screen"**
- Click **Open System Settings**
- Enable **Screen Recording** permission for your app
- Restart the app

### Step 4: Done!
Your app should now show your iPhone's screen content!

## Advantages of QuickTime Mode

✅ Works immediately (no iPhone authorization issues)
✅ Same translucent window display
✅ Still protected from screen recording (captures QuickTime's protection)
✅ No need to reset iPhone privacy settings

## Limitations

⚠️  Requires QuickTime Player to be running
⚠️  Slightly higher resource usage (two apps)
⚠️  If QuickTime window closes, need to restart

## Tips

- **Hide QuickTime**: After starting, minimize or move QuickTime window off-screen
- **Auto-start**: You can keep QuickTime always running in background
- **Performance**: QuickTime adds ~5-10ms latency (barely noticeable)
- **Toggle Modes**: Press **Ctrl + Opt + Cmd + H** anytime to toggle between QuickTime and direct mode
- **Status Indicator**: In debug mode, green text shows "QuickTime Mode" when active

## Troubleshooting

**"QuickTime not showing iPhone" error:**
- Make sure QuickTime is open with iPhone screen recording active
- Check that QuickTime window title contains "iPhone"

**No frames appearing:**
- Grant Screen Recording permission in System Settings
- Restart the app after granting permission

**High CPU usage:**
- Make QuickTime window smaller
- Reduce frame rate in QuickTime (if option available)
