# Keyboard Shortcuts

Since the iPhone mirror window is non-interactive (click-through), all controls must be accessed via keyboard shortcuts.

## Available Shortcuts

### Control + Option + Command + T
**Cycle Transparency**
- Cycles through transparency levels: 30% → 50% → 70% → 90% → 30%
- Adjust how visible the window is vs background content
- Great for fine-tuning visibility while reading background text

### Control + Option + Command + ↑ (Up Arrow)
**Increase Opacity (Less Transparent)**
- Makes the window less transparent by 10%
- Use when you need to see iPhone content more clearly
- Range: 10% to 100% opacity

### Control + Option + Command + ↓ (Down Arrow)
**Decrease Opacity (More Transparent)**
- Makes the window more transparent by 10%
- Use when you need to see background content more clearly
- Range: 10% to 100% opacity

## Usage

The app always uses QuickTime mode for maximum reliability. Simply:

1. **Start QuickTime with iPhone:**
   - Open QuickTime Player
   - File → New Movie Recording
   - Select your iPhone

2. **Launch the app:**
   - Run from Xcode (Cmd + R)
   - App automatically captures from QuickTime

3. **Adjust transparency as needed:**
   - Press **Ctrl + Opt + Cmd + T** to cycle presets
   - Use arrow keys (↑↓) with Ctrl + Opt + Cmd for fine control

## Visual Feedback

In debug builds, you'll see a status indicator at the top-left of the window:
- **Green text**: "QuickTime Mode • Transparency: Ctrl+Opt+Cmd+T / ↑↓"
- Shows you're actively capturing from QuickTime and displays transparency shortcuts

## Future Shortcuts (To Be Added)

Potential shortcuts to add:
- **Cmd + Q**: Quit app
- **Cmd + H**: Hide/Show window
- **Cmd + T**: Toggle transparency level
- **Cmd + R**: Reconnect/Restart capture
- **Cmd + ,**: Open settings (if settings panel is added)

## Note

The window is configured with `ignoresMouseEvents = true`, making it completely click-through. This is intentional for the confidential overlay use case, but it means all interactions must be keyboard-driven.
