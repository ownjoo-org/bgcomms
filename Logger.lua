-- BGCommsLogger.lua - Comprehensive logging and debugging system

BGCommsLogger = {}

-- Log levels
BGCommsLogger.DEBUG = 1
BGCommsLogger.INFO = 2
BGCommsLogger.WARN = 3
BGCommsLogger.ERROR = 4

-- Current log level (DEBUG shows everything)
BGCommsLogger.currentLevel = BGCommsLogger.DEBUG

-- Colors for chat output
BGCommsLogger.colors = {
    DEBUG = "|cFF808080",  -- Gray
    INFO = "|cFF00FF00",   -- Green
    WARN = "|cFFFFFF00",   -- Yellow
    ERROR = "|cFFFF0000",  -- Red
    RESET = "|r",
}

-- Store log history for later inspection
BGCommsLogger.history = {}
BGCommsLogger.maxHistorySize = 100

-- Debug mode: when enabled, writes to disk (SavedVariables) instead of memory
BGCommsLogger.debugMode = true  -- Default ON for development

-- Get level name from number
function BGCommsLogger:GetLevelName(level)
    if level == self.DEBUG then return "DEBUG"
    elseif level == self.INFO then return "INFO"
    elseif level == self.WARN then return "WARN"
    elseif level == self.ERROR then return "ERROR"
    else return "UNKNOWN"
    end
end

-- Get color for level
function BGCommsLogger:GetColor(level)
    if level == self.DEBUG then return self.colors.DEBUG
    elseif level == self.INFO then return self.colors.INFO
    elseif level == self.WARN then return self.colors.WARN
    elseif level == self.ERROR then return self.colors.ERROR
    else return self.colors.RESET
    end
end

-- Internal log function
function BGCommsLogger:_Log(level, message)
    if level < self.currentLevel then
        return  -- Don't log messages below current level
    end

    local levelName = self:GetLevelName(level)
    local color = self:GetColor(level)
    local timestamp = date("%H:%M:%S")

    -- Format message
    local formattedMsg = string.format("%s[%s][%s] %s%s", color, timestamp, levelName, message, self.colors.RESET)
    local plainMsg = string.format("[%s][%s] %s", timestamp, levelName, message)

    -- If debug mode is on, write directly to disk (SavedVariables)
    if self.debugMode then
        BGCommsDebugLog = BGCommsDebugLog or {}
        table.insert(BGCommsDebugLog, plainMsg)
        -- Don't keep memory history when debug mode is on
        return
    end

    -- Add to history (memory only when debug mode is off)
    table.insert(self.history, {
        level = level,
        levelName = levelName,
        message = message,
        timestamp = timestamp,
        formattedMsg = formattedMsg,
    })

    -- Maintain history size
    if #self.history > self.maxHistorySize then
        table.remove(self.history, 1)
    end

    -- Print to chat
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)
    end

    -- Also print to console for debugging
    print(formattedMsg)
end

-- Public logging functions
function BGCommsLogger:Debug(message)
    self:_Log(self.DEBUG, message)
end

function BGCommsLogger:Info(message)
    self:_Log(self.INFO, message)
end

function BGCommsLogger:Warn(message)
    self:_Log(self.WARN, message)
end

function BGCommsLogger:Error(message)
    self:_Log(self.ERROR, message)
end

-- Get log history
function BGCommsLogger:GetHistory(limit)
    limit = limit or self.maxHistorySize
    local result = {}
    local start = math.max(1, #self.history - limit + 1)
    for i = start, #self.history do
        table.insert(result, self.history[i])
    end
    return result
end

-- Print all history
function BGCommsLogger:PrintHistory()
    print("\n=== BattlegroundComms Log History ===")
    for _, entry in ipairs(self:GetHistory()) do
        print(entry.formattedMsg)
    end
    print("=== End of History ===\n")
end

-- Export history as string
function BGCommsLogger:ExportHistory()
    local lines = {}
    for _, entry in ipairs(self.history) do
        table.insert(lines, string.format("[%s][%s] %s", entry.timestamp, entry.levelName, entry.message))
    end
    return table.concat(lines, "\n")
end

-- Set log level
function BGCommsLogger:SetLevel(level)
    self.currentLevel = level
    self:Info("Log level set to: " .. self:GetLevelName(level))
end

-- Toggle debug mode
function BGCommsLogger:SetDebugMode(enabled)
    self.debugMode = enabled
    if enabled then
        print("|cFF00FF00[BGComms]|r Debug mode ON - logging to disk")
        BGCommsDebugLog = {}  -- Initialize debug log
    else
        print("|cFF00FF00[BGComms]|r Debug mode OFF - logging to memory")
    end
end

-- Get debug log file location
function BGCommsLogger:GetDebugLogLocation()
    print("|cFF00FF00[BGComms]|r Debug log file location:")
    print("World of Warcraft/_retail_/WTF/Account/[YourAccount]/SavedVariables/BattlegroundComms.lua")
    print("|cFF00FF00[BGComms]|r Debug logs are stored in the BGCommsDebugLog variable")
end

-- Export debug log to file (by showing where it is)
function BGCommsLogger:ExportDebugLog()
    if not BGCommsDebugLog or #BGCommsDebugLog == 0 then
        print("|cFF00FF00[BGComms]|r No debug logs recorded")
        return
    end

    print("|cFF00FF00[BGComms]|r Debug log (" .. #BGCommsDebugLog .. " entries):")
    for _, entry in ipairs(BGCommsDebugLog) do
        print(entry)
    end

    print("|cFF00FF00[BGComms]|r Log file saved to SavedVariables")
    self:GetDebugLogLocation()
end
