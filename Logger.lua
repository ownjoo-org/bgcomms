-- Logger.lua - Comprehensive logging and debugging system

local Logger = {}

-- Log levels
Logger.DEBUG = 1
Logger.INFO = 2
Logger.WARN = 3
Logger.ERROR = 4

-- Current log level (DEBUG shows everything)
Logger.currentLevel = Logger.DEBUG

-- Colors for chat output
Logger.colors = {
    DEBUG = "|cFF808080",  -- Gray
    INFO = "|cFF00FF00",   -- Green
    WARN = "|cFFFFFF00",   -- Yellow
    ERROR = "|cFFFF0000",  -- Red
    RESET = "|r",
}

-- Store log history for later inspection
Logger.history = {}
Logger.maxHistorySize = 100

-- Get level name from number
function Logger:GetLevelName(level)
    if level == self.DEBUG then return "DEBUG"
    elseif level == self.INFO then return "INFO"
    elseif level == self.WARN then return "WARN"
    elseif level == self.ERROR then return "ERROR"
    else return "UNKNOWN"
    end
end

-- Get color for level
function Logger:GetColor(level)
    if level == self.DEBUG then return self.colors.DEBUG
    elseif level == self.INFO then return self.colors.INFO
    elseif level == self.WARN then return self.colors.WARN
    elseif level == self.ERROR then return self.colors.ERROR
    else return self.colors.RESET
    end
end

-- Internal log function
function Logger:_Log(level, message)
    if level < self.currentLevel then
        return  -- Don't log messages below current level
    end

    local levelName = self:GetLevelName(level)
    local color = self:GetColor(level)
    local timestamp = date("%H:%M:%S")

    -- Format message
    local formattedMsg = string.format("%s[%s][%s] %s%s", color, timestamp, levelName, message, self.colors.RESET)

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

    -- Also print to console for debugging
    print(formattedMsg)
end

-- Public logging functions
function Logger:Debug(message)
    self:_Log(self.DEBUG, message)
end

function Logger:Info(message)
    self:_Log(self.INFO, message)
end

function Logger:Warn(message)
    self:_Log(self.WARN, message)
end

function Logger:Error(message)
    self:_Log(self.ERROR, message)
end

-- Get log history
function Logger:GetHistory(limit)
    limit = limit or self.maxHistorySize
    local result = {}
    local start = math.max(1, #self.history - limit + 1)
    for i = start, #self.history do
        table.insert(result, self.history[i])
    end
    return result
end

-- Print all history
function Logger:PrintHistory()
    print("\n=== BattlegroundComms Log History ===")
    for _, entry in ipairs(self:GetHistory()) do
        print(entry.formattedMsg)
    end
    print("=== End of History ===\n")
end

-- Export history as string
function Logger:ExportHistory()
    local lines = {}
    for _, entry in ipairs(self.history) do
        table.insert(lines, string.format("[%s][%s] %s", entry.timestamp, entry.levelName, entry.message))
    end
    return table.concat(lines, "\n")
end

-- Set log level
function Logger:SetLevel(level)
    self.currentLevel = level
    self:Info("Log level set to: " .. self:GetLevelName(level))
end

return Logger
