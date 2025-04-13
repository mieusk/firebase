local http = require("coro-http")
local json = require("json")

local AXIOMS = {
    HTTP_METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE"},
    FIREBASE_PATH_RULES = {
        no_leading_slash = true,
        no_trailing_slash = true,
        no_empty_segments = true
    },
    VALID_RESPONSE_CODES = {200, 201, 204},
    MAX_RECURSION_DEPTH = 5
}

local FirebaseAPI = {}
FirebaseAPI.__index = FirebaseAPI

function FirebaseAPI.new(url, token, options)
    local self = setmetatable({}, FirebaseAPI)
    self.databaseURL = url:gsub("/$", "")
    self.authToken = token
    self.options = options or {
        maxRetries = 3,
        retryDelay = 1000,
        timeout = 5000
    }
    
    self.metrics = {
        requestCount = 0,
        totalResponseTime = 0,
        errorCount = 0
    }
    
    return self
end

function FirebaseAPI:_request(method, path, data, attempt)
    attempt = attempt or 1
    local startTime = os.clock()
    
    path = path:gsub("^/", ""):gsub("/$", "")
    if path:find("//") then
        return nil, "Invalid path: contains empty segments"
    end
    
    local url = self.databaseURL .. "/" .. path .. ".json"
    if self.authToken then
        url = url .. "?auth=" .. self.authToken
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    local body = data and json.encode(data) or nil

    local success, response, res_body = pcall(http.request, method, url, headers, body)
    
    local responseTime = os.clock() - startTime
    self.metrics.requestCount = self.metrics.requestCount + 1
    self.metrics.totalResponseTime = self.metrics.totalResponseTime + responseTime
    
    if not success then
        self.metrics.errorCount = self.metrics.errorCount + 1
        return nil, "Network error: " .. tostring(response)
    end
    
    if not response then
        self.metrics.errorCount = self.metrics.errorCount + 1
        return nil, "No response received"
    end
    
    if response.code >= 400 then
        self.metrics.errorCount = self.metrics.errorCount + 1
        
        if response.code >= 500 and attempt < self.options.maxRetries then
            local delay = self.options.retryDelay * (2 ^ (attempt - 1))
            os.execute("sleep " .. delay/1000)
            return self:_request(method, path, data, attempt + 1)
        end
        
        return nil, "HTTP " .. response.code .. ": " .. (res_body or "no details")
    end

    if res_body and res_body ~= "" then
        local success, decoded = pcall(json.decode, res_body)
        if success then
            return decoded
        else
            return nil, "Failed to decode JSON: " .. decoded
        end
    end
    
    return true
end

function FirebaseAPI:get(path)
    return self:_request("GET", path)
end

function FirebaseAPI:post(path, data)
    return self:_request("POST", path, data)
end

--like :set()
function FirebaseAPI:put(path, data)
    return self:_request("PUT", path, data)
end

function FirebaseAPI:patch(path, data)
    return self:_request("PATCH", path, data)
end

function FirebaseAPI:delete(path)
    return self:_request("DELETE", path)
end

function FirebaseAPI:getMetrics()
    return {
        requestCount = self.metrics.requestCount,
        avgResponseTime = self.metrics.requestCount > 0 
            and (self.metrics.totalResponseTime / self.metrics.requestCount) 
            or 0,
        errorRate = self.metrics.requestCount > 0
            and (self.metrics.errorCount / self.metrics.requestCount)
            or 0
    }
end

function FirebaseAPI:node(path)
    local node = {
        _path = path,
        _api = self,
        get = function(self) return self._api:get(self._path) end,
        set = function(self, data) return self._api:put(self._path, data) end,
        update = function(self, data) return self._api:patch(self._path, data) end,
        delete = function(self) return self._api:delete(self._path) end
    }
    
    return setmetatable(node, {
        __index = function(t, k)
            local data = t:get()
            return data and data[k]
        end,
        __newindex = function(t, k, v)
            local current = t:get() or {}
            current[k] = v
            t:update({[k] = v})
        end
    })
end

function FirebaseAPI:query(path)
    local query = {
        filters = {},
        path = path,
        api = self,
        where = function(self, field, operator, value)
            self.filters[field] = {op = operator, value = value}
            return self
        end,
        execute = function(self)
            local data = self.api:get(self.path)
            if not data or type(data) ~= "table" then return data end
            
            local result = {}
            for id, item in pairs(data) do
                local match = true
                for field, condition in pairs(self.filters) do
                    local itemValue = item[field]
                    local op, value = condition.op, condition.value
                    
                    if not (op == "==" and itemValue == value or
                           op == ">=" and itemValue >= value or
                           op == "<=" and itemValue <= value or
                           op == ">"  and itemValue >  value or
                           op == "<"  and itemValue <  value or
                           op == "~=" and itemValue ~= value) then
                        match = false
                        break
                    end
                end
                if match then result[id] = item end
            end
            return result
        end
    }
    return query
end

return FirebaseAPI
