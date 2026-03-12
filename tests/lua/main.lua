local Greeter = {}
Greeter.__index = Greeter

function Greeter.new(prefix)
  return setmetatable({ prefix = prefix }, Greeter)
end

function Greeter:message(name)
  return string.format("%s, %s!", self.prefix, name)
end

local function main()
  local g = Greeter.new("Hello from Lua")
  local names = { "Ada", "Grace", "Linus" }

  for _, name in ipairs(names) do
    print(g:message(name))
  end

  -- Uncomment for diagnostics test:
  -- print(g.unknown_field)
end

main()
