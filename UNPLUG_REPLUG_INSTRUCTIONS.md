# How to Fix the "Connecting..." Issue

## Quick Solution: Use QuickTime Mode

If you can't get the authorization prompt to appear, press **Control + Option + Command + H** to switch to QuickTime mode (see QUICKTIME_MODE_INSTRUCTIONS.md).

---

# How to Fix the "Connecting..." Issue

## The Problem

Your app is currently connecting to the **iPhone Camera** device, not the **iPhone Screen** device. These are two different devices:

1. **Bhaveek's iPhone Camera** - The physical camera on your iPhone (Model: iPhone18,1, 8 formats)
2. **Bhaveek's iPhone** - The screen sharing device (Model: iOS Device, 1 format) ← **This is what we need!**

The screen device **only appears** when you unplug and replug your iPhone while the app is running.

## The Solution - Step by Step

### 1. Build and Run
- In Xcode, press **Cmd + R** to build and run
- You'll see the app window with "Waiting for screen device..."

### 2. **UNPLUG your iPhone**
- While the app is running, physically unplug your iPhone from the USB port
- Wait 2-3 seconds

### 3. **REPLUG your iPhone**
- Plug your iPhone back into the USB port
- **IMMEDIATELY WATCH YOUR IPHONE SCREEN!**

### 4. Authorization Prompt on iPhone
You should see this on **your iPhone** (not Mac):

```
"[Mac Name] would like to use
camera and microphone"

[Don't Allow]  [Allow]
```

**TAP "ALLOW" IMMEDIATELY**

### 5. Check the Logs
After replugging, look for this in Xcode console:

```
DEBUG: Device connected notification: Bhaveek's iPhone
DEBUG:   Model: iOS Device, Formats: 1, Is Screen: true
DEBUG: Switching to iOS device: Bhaveek's iPhone
```

If you see error -11852, the authorization was denied or the prompt didn't appear.

## If No Prompt Appears on iPhone

The permission might have been previously denied. Reset it:

**On your iPhone:**
1. Settings → General → Transfer or Reset iPhone
2. Tap **Reset**
3. Tap **Reset Location & Privacy**
4. Enter passcode and confirm
5. **iPhone will restart**
6. After restart, reconnect to Mac
7. Run the app again
8. Unplug/replug iPhone
9. The prompt WILL appear this time - tap Allow!

## What the App Should Show

### Before Unplug/Replug:
- "Waiting for screen device..."
- "Please UNPLUG and REPLUG your iPhone"

### After Successful Authorization:
- You should see your iPhone's screen content in the window
- The app should display exactly what's on your iPhone screen

## Troubleshooting

### "Authorization Required" Error
- The prompt appeared but you tapped "Don't Allow", OR
- The prompt never appeared because it was previously denied
- **Solution:** Reset Location & Privacy on iPhone (see above)

### Still Shows "Connecting..."
- The app is using the camera device, not screen device
- **Solution:** Unplug and replug iPhone to trigger screen device appearance

### Screen Device Never Appears
- Make sure your iPhone iOS version supports this (iOS 16+)
- Try using QuickTime first to verify it works:
  - QuickTime → File → New Movie Recording
  - Select your iPhone from dropdown
  - If this works, the app should work too

## Key Points

1. The **screen device** is different from the **camera device**
2. Screen device only appears during iPhone reconnection
3. Authorization prompt appears **on iPhone**, not Mac
4. You must tap "Allow" on iPhone for screen sharing to work
5. If denied, you must reset Location & Privacy on iPhone

## Expected Console Output

When it works correctly:

```
DEBUG: Device connected notification: Bhaveek's iPhone
DEBUG:   Model: iOS Device, Formats: 1, Is Screen: true
DEBUG: Switching to iOS device: Bhaveek's iPhone
DEBUG: Successfully created device input
DEBUG: Successfully added input to session
DEBUG: Capture session started running
DEBUG: Successfully captured frame: (1170.0, 2532.0)
DEBUG: Updated currentFrame with size: (1170.0, 2532.0)
```

Good luck! The key is: **UNPLUG → REPLUG → WATCH IPHONE → TAP ALLOW**
