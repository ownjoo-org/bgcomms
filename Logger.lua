-- BGCommsLogger.lua - Logging system with configurable log levels

BGCommsLogger = {}

-- Log levels (higher number = more severe, only output at or above current level)
BGCommsLogger.DEBUG = 1
BGCommsLogger.INFO = 2
BGCommsLogger.WARNING = 3
BGCommsLogger.ERROR = 4
BGCommsLogger.CRITICAL = 5

-- Current log level (default to WARNING - only show warnings and above during gameplay)
BGCommsLogger.currentLevel = BGCommsLogger.WARNING

-- Colors for chat output
BGCommsLogger.colors = {
    DEBUG = "|cFF808080",    -- Gray
    INFO = "|cFF00FF00",     -- Green
    WARNING = "|cFFFFFF00",  -- Yellow
    ERROR = "|cFFFF0000",    -- Red
    CRITICAL = "|cFFFF00FF", -- Magenta
    RESET = "|r",
}

-- Store log history for later inspection (in-memory)
BGCommsLogger.history = {}
BGCommsLogger.maxHistorySize = 100

-- Get level name from number
function BGCommsLogger:GetLevelName(level)
    if level == self.DEBUG then return "DEBUG"
    elseif level == self.INFO then return "INFO"
    elseif level == self.WARNING then return "WARNING"
    elseif level == self.ERROR then return "ERROR"
    elseif level == self.CRITICAL then return "CRITICAL"
    else return "UNKNOWN"
    end
end

-- Get color for level
function BGCommsLogger:GetColor(level)
    if level == self.DEBUG then return self.colors.DEBUG
    elseif level == self.INFO then return self.colors.INFO
    elseif level == self.WARNING then return self.colors.WARNING
    elseif level == self.ERROR then return self.colors.ERROR
    elseif level == self.CRITICAL then return self.colors.CRITICAL
    else return self.colors.RESET
    end
end

-- Internal log function - always called, filtering happens here
function BGCommsLogger:_Log(level, message)
    local levelName = self:GetLevelName(level)
    local color = self:GetColor(level)
    local timestamp = date("%H:%M:%S")

    -- Format message: [HH:MM:SS] [LEVEL] message
    local formattedMsg = string.format("%s[%s] [%s] %s%s", color, timestamp, levelName, message, self.colors.RESET)

    -- Add to in-memory history (always keep recent logs)
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

    -- Only output to chat/console if level meets threshold
    if level >= self.currentLevel then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)
        end
        print(formattedMsg)
    end

    -- If DEBUG level, also save to SavedVariables for file export
    if self.currentLevel == self.DEBUG then
        BGCommsDebugLog = BGCommsDebugLog or {}
        table.insert(BGCommsDebugLog, string.format("[%s] [%s] %s", timestamp, levelName, message))
        -- Keep debug log reasonably sized
        if #BGCommsDebugLog > 500 then
            table.remove(BGCommsDebugLog, 1)
        end
    end
end

-- Public logging functions - always called, filtering in _Log
function BGCommsLogger:Debug(message)
    self:_Log(self.DEBUG, message)
end

function BGCommsLogger:Info(message)
    self:_Log(self.INFO, message)
end

function BGCommsLogger:Warning(message)
    self:_Log(self.WARNING, message)
end

function BGCommsLogger:Error(message)
    self:_Log(self.ERROR, message)
end

function BGCommsLogger:Critical(message)
    self:_Log(self.CRITICAL, message)
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
        table.insert(lines, string.format("[%s] [%s] %s", entry.timestamp, entry.levelName, entry.message))
    end
    return table.concat(lines, "\n")
end

-- Set log level
function BGCommsLogger:SetLogLevel(level)
    self.currentLevel = level
    self:Info("Log level set to: " .. self:GetLevelName(level))
    if level == self.DEBUG then
        self:Info("Debug logs will be saved to SavedVariables for export")
    end
end

-- Get log level name
function BGCommsLogger:GetLogLevelName()
    return self:GetLevelName(self.currentLevel)
end

-- Parse log level string to number
function BGCommsLogger:ParseLogLevel(levelStr)
    levelStr = levelStr:upper()
    if levelStr == "DEBUG" then return self.DEBUG
    elseif levelStr == "INFO" then return self.INFO
    elseif levelStr == "WARNING" then return self.WARNING
    elseif levelStr == "ERROR" then return self.ERROR
    elseif levelStr == "CRITICAL" then return self.CRITICAL
    else return self.WARNING  -- Default to WARNING if invalid
    end
end

-- Export debug log to chat for copying
function BGCommsLogger:ExportDebugLog()
    if not BGCommsDebugLog or #BGCommsDebugLog == 0 then
        self:Info("No debug logs recorded yet. Enable DEBUG mode with /bgc loglevel debug")
        return
    end

    self:Info("Debug log (" .. #BGCommsDebugLog .. " entries):")
    for _, entry in ipairs(BGCommsDebugLog) do
        print(entry)
    end

    self:Info("Copy the above logs and save to: <WoW>/Interface/AddOns/BattlegroundComms/bgc_debug.log")
    self:Info("Debug logs are stored in SavedVariables and persist across sessions while DEBUG level is active")
end

-- Clear debug log
function BGCommsLogger:ClearDebugLog()
    BGCommsDebugLog = {}
    self:Info("Debug log cleared")
end
