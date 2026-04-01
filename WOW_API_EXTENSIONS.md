# Leveraging WoW VSCode Extensions for Development

## Overview

VSCode WoW development extensions provide comprehensive API documentation that can be used to verify correct WoW API signatures and discover available functions. This document explains how to leverage them for faster, more accurate addon development.

## Available Extensions

We use two primary extensions for WoW addon development:

### 1. **WoW API** (ketho.wow-api-0.22.3)
- **Purpose**: Complete WoW API documentation with type annotations
- **Location**: `C:\Users\eq_fu\.vscode\extensions\ketho.wow-api-0.22.3`
- **Provides**: `.lua` documentation files with function signatures and type hints

### 2. **WoW Bundle** (septh.wow-bundle-1.3.0)
- **Purpose**: Comprehensive WoW addon development environment
- **Includes**: Syntax highlighting, linting, TOC file support
- **Location**: `C:\Users\eq_fu\.vscode\extensions\septh.wow-bundle-1.3.0`

## How to Use the WoW API Extension

### Finding API Documentation

The WoW API extension stores annotated documentation in:
```
~\.vscode\extensions\ketho.wow-api-0.22.3\Annotations\Core\Blizzard_APIDocumentationGenerated\
```

**Key documentation files:**
- `MapDocumentation.lua` - All C_Map namespace functions
- `ChatDocumentation.lua` - C_ChatInfo and chat functions
- `PvPDocumentation.lua` - C_PvP functions
- `MinimapDocumentation.lua` - Minimap API

### Example: Finding the Correct API Signature

**Problem**: We were using `C_Map.GetBestMapID()` which doesn't exist.

**Solution Process**:
1. Located `MapDocumentation.lua`
2. Searched for "GetBestMap" functions
3. Found: `C_Map.GetBestMapForUnit(unitToken) → number? uiMapID`
4. Updated code to use: `C_Map.GetBestMapForUnit("player")`

### Searching the Documentation

Use grep/rg to search documentation files:

```bash
# Search for a function by name
grep -r "SendChatMessage" ~/.vscode/extensions/ketho.wow-api-0.22.3/Annotations/

# Search in a specific file
grep "GetMapInfo" ~/.vscode/extensions/ketho.wow-api-0.22.3/Annotations/Core/Blizzard_APIDocumentationGenerated/MapDocumentation.lua

# Case-insensitive search
grep -i "bestmap" ~/.vscode/extensions/ketho.wow-api-0.22.3/Annotations/Core/Blizzard_APIDocumentationGenerated/MapDocumentation.lua
```

## Documentation Format

Each function is documented with:
```lua
---[Documentation](https://warcraft.wiki.gg/wiki/API_C_Map.GetBestMapForUnit)
---@param unitToken UnitToken
---@return number? uiMapID
function C_Map.GetBestMapForUnit(unitToken) end
```

**Interpretation**:
- `---@param` = function parameters and their types
- `---@return` = return types (? means optional/nullable)
- Documentation links to official WoW Wiki

## API Reference Guide by Namespace

| Namespace | File | Common Functions |
|-----------|------|------------------|
| C_Map | MapDocumentation.lua | GetBestMapForUnit, GetMapInfo, GetMapChildrenInfo |
| C_ChatInfo | ChatDocumentation.lua | SendChatMessage |
| C_PvP | PvPDocumentation.lua | IsInBattleground |
| Minimap | MinimapDocumentation.lua | CreateMinimapIcon, GetMinimapPosition |

## Best Practices

1. **Always verify API signatures** in the documentation before implementing
2. **Check return types** - notice the `?` for optional returns
3. **Use the wiki links** - click the documentation URL for more details
4. **Search the annotations** - don't guess function names; search first
5. **Pay attention to version notes** - some APIs are mainline only

## Recent Discoveries

### C_Map API (WoW 12.0)
- ✅ `C_Map.GetBestMapForUnit("player")` - Returns current map ID
- ✅ `C_Map.GetMapInfo(mapID)` - Returns map details with `.name` field
- ❌ `C_Map.GetBestMapID()` - **Does NOT exist**
- ❌ `GetSubZoneText()` / `GetRealZoneText()` - **Removed in WoW 12.0**, use C_Map instead

### C_ChatInfo API (WoW 12.0)
- ✅ `SendChatMessage(message, chatType)` - Protected function
- ✅ Valid chat types: SAY, YELL, PARTY, RAID, INSTANCE_CHAT, GUILD
- ❌ `BATTLEGROUND` - Use `INSTANCE_CHAT` instead
- ❌ `INSTANCE` alone - Use `INSTANCE_CHAT`

## Integration with VSCode

The extensions provide:
- **IntelliSense** - Autocomplete suggestions for WoW APIs
- **Type hints** - Hover over functions to see signatures
- **Go to definition** - Jump to API definitions
- **Error highlighting** - Catch undefined functions before testing

## Workflow Tips

1. When implementing a new feature, search the documentation first
2. Copy the function signature from documentation exactly
3. Use the type hints to understand parameter requirements
4. Test in-game and check `/bgc debug` logs
5. If API fails, verify in documentation and check return types

## Further Reading

- Official WoW API Wiki: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- Extension repository: https://github.com/Ketho/wow-api-docs
- WoW Bundle docs: https://github.com/septh/wow-bundle

## Notes for Future Development

- **Location detection**: Always use C_Map API, not GetSubZoneText/GetRealZoneText
- **Chat messages**: Verify chat type constants are correct (INSTANCE_CHAT, not INSTANCE)
- **Protected functions**: Some functions are Blizzard-only; check documentation for alternatives
- **API changes**: WoW 12.0+ made significant changes; always verify against correct version
