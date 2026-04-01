-- BGCommsLogger.lua - Logging system with configurable log levels

BGCommsLogger = {}

-- Log levels (higher number = more severe, only log at or above current level)
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

-- Store log history for later inspection
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

-- Internal log function
function BGCommsLogger:_Log(level, message)
    -- Only log if message level is at or above current level threshold
    if level < self.currentLevel then
        return
    end

    local levelName = self:GetLevelName(level)
    local color = self:GetColor(level)
    local timestamp = date("%H:%M:%S")

    -- Format message: [HH:MM:SS] [LEVEL] message
    local formattedMsg = string.format("%s[%s] [%s] %s%s", color, timestamp, levelName, message, self.colors.RESET)

    -- Add to history
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

    -- Also print to console
    print(formattedMsg)
end

-- Public logging functions
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
