# Battleground Comms

A simple World of Warcraft addon for quick battleground communication with buttons and slash commands.

## Features

- **CLEAR** button - Send "CLEAR" to chat
- **INC** button - Send "INC [location]" to chat
- **Movable UI** - Drag the frame to reposition
- **Slash commands** - `/bgc` to toggle, `/bgc clear`, `/bgc inc <location>`

## Project Structure

```
BattlegroundComms/
├── BattlegroundComms.toc       # Addon manifest
├── Core.lua                    # Main addon initialization & slash commands
├── Locations.lua               # Battleground zone definitions (easily editable)
├── Communications.lua          # Chat sending logic
├── UI.lua                      # Button frames and UI
├── tests/                      # Unit tests
│   ├── test_locations.lua
│   └── test_communications.lua
├── package.json                # npm dependencies (for testing)
└── .busted                     # Busted test config
```

## Installation

1. Copy the entire `BattlegroundComms` folder to your WoW `Interface/AddOns/` directory
2. Reload the addon in-game or restart WoW

### On Windows:
```
C:\Users\[YourUsername]\AppData\Local\Blizzard\World of Warcraft\_retail_\Interface\AddOns\
```

## Usage

### In-Game

- `/bgc` or `/bgcomms` - Toggle the addon window
- Click **CLEAR** - Sends "CLEAR" to chat
- Click **INC** - Sends "INC Location" to chat (location will be auto-detected in future versions)
- Drag the window to move it

### Configuration

Edit `Communications.lua` to change the chat channel:

```lua
Communications.CHAT_CHANNEL = "PARTY"  -- Options: PARTY, RAID, BATTLEGROUND, SAY
```

### Adding Locations

Edit `Locations.lua` to customize battleground zones:

```lua
Locations.MyBattleground = {
    "Zone 1",
    "Zone 2",
    "Zone 3",
}
```

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

## Future Improvements

- [ ] Auto-detect current zone/location
- [ ] Detect which battleground you're in
- [ ] Macro buttons for custom messages
- [ ] Persist settings (window position, chat channel)
- [ ] Add more battleground zone definitions
- [ ] Squad/group specific messages

## Notes

- The addon currently returns default zones until battleground detection is implemented
- All WoW API calls are mocked in tests (except in the actual game)
- Messages are prefixed with `[BGComms]` for easy identification
