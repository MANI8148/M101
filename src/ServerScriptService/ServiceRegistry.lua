local ServiceRegistry = {}
ServiceRegistry._services = {}

function ServiceRegistry:Register(name, service)
    if self._services[name] then
        warn("Service " .. name .. " is already registered.")
        return
    end
    self._services[name] = service
end

function ServiceRegistry:Get(name)
    local service = self._services[name]
    if not service then
        warn("Attempted to get unregistered service: " .. name)
    end
    return service
end

return ServiceRegistry
