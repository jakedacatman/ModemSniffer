if not fs.exists("/"..shell.resolve "locate.lua") then shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/reverseGPS/locate.lua /"..shell.resolve "locate.lua") end
if not fs.exists("/"..shell.resolve "sniffConfig.lua") then shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/reverseGPS/sniffConfig.lua /"..shell.resolve "sniffConfig.lua") end 

local l = require("/"..shell.resolve "locate")
 
local file = fs.open("/"..shell.resolve "sniffConfig.lua", "r")
local config = textutils.unserialize(file.readAll())
file.close()
if not config or config.channels then error "delete sniffConfig.lua" end
if #config.channels > 128 then error "modems can only have 128 channels open" end

local modems = peripheral.find("modem", function(name, obj) return obj.isWireless() end)
if #modems < 4 or #modems > 4 then error "needs 4 modems to locate" end
    
for i = 1, #modems do
  for v = 1, #config.channels do
    modems[i].open(v)        
  end
end
    
while true do
  local ev = os.pullEvent "modem_message"
  local pos = {l.locate(ev, 5)}
  print(pos)
  sleep(1)
end
