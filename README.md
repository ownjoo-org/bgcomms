# Battleground Comms

A comprehensive World of Warcraft addon for battleground communication with dual communication modes (Cap/Defend and CTF), priority-based messaging, custom macros, and intelligent channel selection.

## Features

### Core Communication
- **Two Communication Modes**:
  - **Cap/Defend Frame**: Priority-based battlefield communication (CLEAR, INC with 6 priority levels)
  - **CTF Frame**: Capture-the-flag specific communication (offense/defense flag calls, base status)

### Cap/Defend Mode
- **Priority System** (0-5+): Set communication priority before sending messages
- **CLEAR Button**: Announce cleared areas with automatic location detection
- **INC Button**: Report incoming enemies with priority and location
- **Macro Buttons**: Create and execute custom messages (store them persistently)
- **Channel Selection**: Dropdown to select communication channel (SAY, YELL, PARTY, RAID, INSTANCE_CHAT, GUILD, BGCOMMS)

### CTF Mode
- **Offense Section**: Report "Their FC Running" with directions (West, Mid, East)
- **Defense Section**: 
  - Report "Our FC Running" with directions
  - "INC Flag Room" for incoming enemies at flag
  - "FC Needs HELP" for urgent defense
- **Smart Messaging**: All messages use raid marker icons for clarity

### UI & Controls
- **Minimap Icon**:
  - Left-click: Close frame or show dropdown to select Cap/Defend/CTF
  - Right-click: Open Settings panel
  - Draggable for repositioning
- **Settings Panel**: Control window opacity, lock position, smart channel detection
- **Movable Frames**: Both frames are draggable (when unlocked) and remember position
- **Smart Channel Detection**: Automatically uses BGCOMMS in battlegrounds, RAID in raids, PARTY otherwise

### Advanced Features
- **Logging System**: Python-style log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL) with debug export
- **Macro System**: Create, edit, delete, and execute custom message macros
- **Location Detection**: Auto-detects player location in battlegrounds (WoW 12.0 API)
- **Settings Persistence**: All settings saved to SavedVariables
- **Mutually Exclusive Frames**: Only one communication frame visible at a time, sharing same screen position

## Project Structure

```
BattlegroundComms/
├── BattlegroundComms.toc          # Addon manifest & load order
├── Core.lua                       # Main addon initialization & slash commands
├── UI.lua                         # Cap/Defend frame & minimap icon
├── CTF.lua                        # CTF frame for capture-the-flag
├── Communications.lua             # Chat sending logic & channel management
├── Locations.lua                  # Battleground zone detection
├── Logger.lua                     # Python-style logging system
├── Macros.lua                     # Custom macro storage & execution
├── Settings.lua                   # Settings panel UI
├── tests/                         # Unit tests
│   ├── test_communications.lua
│   ├── test_locations.lua
│   └── test_macros.lua
├── BattlegroundComms.zip          # Packaged addon
├── package.json                   # npm dependencies (for testing)
├── .busted                        # Busted test config
└── README.md                      # This file
```

## Installation

1. Copy the entire `BattlegroundComms` folder to your WoW `Interface/AddOns/` directory

### Windows Path
```
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\
```

2. Reload the addon in-game or restart WoW
3. Use `/bgc` to open the main window

## Usage

### Slash Commands

```
/bgc                           # Toggle Cap/Defend frame
/bgc ctf                       # Toggle CTF frame
/bgc settings                  # Open Settings panel
/bgc show / /bgc hide         # Show/hide current frame
/bgc clear                     # Send CLEAR message
/bgc inc <location>            # Send INC message with location
/bgc channel <channel>         # Change communication channel
/bgc smartchannel on|off      # Toggle smart channel detection
/bgc macro add <name> <msg>   # Add custom macro
/bgc macro remove <name>       # Remove macro
/bgc macro list                # List all macros
/bgc loglevel <level>          # Set log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
/bgc exportlog                 # Export debug log
/bgc clearlog                  # Clear debug log
/bgc help                      # Show help text
```

### Minimap Icon

- **Left-click**: 
  - If frame is open → Close it
  - If no frame is open → Show dropdown to select Cap/Defend or CTF
- **Right-click**: Open Settings panel
- **Drag**: Reposition on minimap

### Cap/Defend Frame

1. **Select Priority**: Click priority buttons (0-5+) to set priority level
   - 0 (blue): No priority set
   - 1-2 (yellow): Low/medium priority
   - 3-4 (orange): High priority
   - 5+ (red): Critical priority

2. **Select Channel**: Click dropdown to choose communication channel

3. **Send Messages**:
   - **CLEAR**: Click to report cleared area (auto-detects location)
   - **INC**: Click to report incoming enemies (uses selected priority and location)
   - **Macros**: Click custom macro buttons to send saved messages

### CTF Frame

1. **Report Offense**: Use "Their FC Running" buttons to call flag carrier direction
2. **Report Defense**: Use "Our FC Running" buttons to call friendly flag carrier direction
3. **Emergency Calls**: 
   - "INC Flag Room" for incoming at flag location
   - "FC Needs HELP" for urgent defense requests

### Settings Panel

- **Lock Window**: Prevent accidental frame movement
- **Smart Channel**: Auto-detect and use appropriate channel (BGCOMMS in BG, RAID in raids, PARTY otherwise)
- **Opacity**: Adjust background transparency (0-100%)
- **Position**: View/edit exact frame coordinates
- **Channel**: Change communication channel

## Configuration

### Default Settings

The addon uses smart defaults:
- **Default Channel**: PARTY (changes to BGCOMMS in battlegrounds)
- **Default Log Level**: WARNING (suppresses debug spam)
- **Default Position**: Centered on screen
- **Smart Channel**: Enabled by default

### Customize Settings

Edit settings in-game:
- Use `/bgc settings` to open the Settings panel
- Adjust opacity, lock state, channel, and smart detection
- Settings persist across sessions

### Create Custom Macros

```
/bgc macro add inchbase "INC @ base, defend!"
/bgc macro add fcpushed "FC pushed mid"
/bgc macro add focus "Focus on priorities"
```

Macros appear as buttons on the Cap/Defend frame and persist between sessions.

## Testing

This project uses **Busted**, the standard Lua testing framework.

### Setup

```bash
cd BattlegroundComms
npm install
```

### Run Tests

```bash
npm test
```

### Run Tests with Coverage

```bash
npm run test:coverage
```

## Message Format Examples

### Cap/Defend Mode
- `{square}{square} CLEAR: Stables` - Priority 0 clear
- `{star}{star} INC 1 : North Gate` - Priority 1 incoming
- `{circle}{circle} INC 3 : South Gate` - Priority 3 incoming
- `{cross}{cross} INC 5+: Base` - Priority 5+ critical incoming

### CTF Mode
- `{diamond}{diamond} FLAG TAKEN : Road` - Flag status
- `{triangle}{triangle} BASE DEFENDED` - Base defense status
- `{cross}{cross} THEIR FC RUNNING WEST` - Enemy flag carrier direction
- `{diamond}{diamond} INC FLAG ROOM` - Incoming at flag location
- `{cross}{cross} FC NEEDS HELP` - Urgent defense call

## API & Architecture

### Module System

Each Lua file is a self-contained module:

- **Core.lua**: Initialization, event handling, slash commands
- **UI.lua**: Frame creation, button layout, minimap icon management
- **CTF.lua**: CTF-specific frame and button management
- **Communications.lua**: Chat message sending, channel management, smart detection
- **Locations.lua**: Zone detection and location caching
- **Logger.lua**: Python-style logging with debug export
- **Macros.lua**: Macro CRUD operations and persistence
- **Settings.lua**: Settings panel UI and preference management

### SavedVariables

Stored in `BGCommsDB` (account-wide) and `BGCommsCharDB` (per-character):

```lua
BGCommsDB = {
    chatChannel = "PARTY",           -- Current communication channel
    windowX = 0,                     -- Frame X position
    windowY = -800,                  -- Frame Y position
    isLocked = false,                -- Frame lock state
    backgroundOpacity = 0.5,         -- Window transparency (0-1)
    useSmartChannelDetection = true, -- Auto-detect channel
    activeFrame = "Main",            -- Currently active frame (Main or CTF)
    settingsPanelX = -100,           -- Settings panel position X
    settingsPanelY = 0,              -- Settings panel position Y
}

BGCommsCharDB = {
    customMacros = {                 -- Per-character macro storage
        ["MacroName"] = "message content",
    }
}

BGCommsDebugLog = {                  -- Debug log (when DEBUG level active)
    -- Array of log entries up to 500 items
}
```

## Troubleshooting

### Messages not appearing?
- Check `/bgc channel` to verify correct channel selected
- Check that smart channel detection isn't conflicting with your group type
- Try disabling smart channel detection with `/bgc smartchannel off`

### Frames not showing?
- Try `/bgc show` to explicitly show the frame
- Check if another addon is overlapping
- Try `/bgc` to toggle visibility

### Missing macros?
- Macros are stored per-character. Switch characters to see different macro sets
- Use `/bgc macro list` to see all macros

### Debug information?
- Enable DEBUG level with `/bgc loglevel DEBUG`
- Export logs with `/bgc exportlog` to save to WoW logs folder
- Clear logs with `/bgc clearlog`

## Known Limitations

- Location detection requires being in an actual battleground (not available in regular zones)
- Custom channels (like BGCOMMS) must be manually joined the first time

## Future Improvements

- [ ] Voice channel integration
- [ ] Raid-wide communication options
- [ ] Customizable button layouts
- [ ] Preset message templates
- [ ] Performance optimization for large raids
- [ ] Additional battleground zone definitions

## Credits

Built for efficient WoW battleground communication using WoW 12.0+ APIs.

## License

Open source - feel free to modify and share!
