--4
--cut startup peripheral calls from about 160 to about 60 if modems are already opened
 
local version = 4
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/sniffer.lua")
 
if latest ~= nil then
    local latestVersion = tonumber(string.sub(latest.readLine(), 3))
    if latestVersion > version then
        print("Out of date (version "..latestVersion.." is out).")
        print("Update notes: "..string.sub(latest.readLine(), 3))
        print("Do you wish to update? (y/n)")
        local timeout = os.startTimer(15)
        while true do
            local event = {os.pullEvent()}
            if event[1] == "char" then
                if event[2] == "y" then
                    fs.delete(shell.getRunningProgram())
                    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/sniffer.lua sniffer.lua")
                    print("Update complete!")
                    print("If you wish to run the new version, then hold CTRL+T and run sniffer.lua.")
                else
                    print("Not updating.")
                    break
                end
            elseif event[1] == "timer" and event[2] == timeout then
                print("Not updating.")
                break
            end
        end
    else
        print("Up to date! (or Github hasn't pushed my update)")
    end
else
    print("Failed to check for new version.")
end
 
print("Running version "..version)

local monitor = peripheral.find("monitor")
if monitor then
	monitor.clear()
	monitor.setTextScale(0.5)
	monitor.setCursorPos(1,1)
	monitor.setTextColor(colors.white)
	term.redirect(monitor)
end

if not fs.exists("blacklist.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/blacklist.lua blacklist.lua")
end

local blacklistFile = fs.open("blacklist.lua", "r")
local blacklist = textutils.unserialize(blacklistFile.readAll())
blacklistFile.close()
 
local iter = 0
local channel = 1

local function isBlacklisted(channel)
    for i = 1, #blacklist do
        if channel == blacklist[i] then return true end
    end
    return false
end

--local modems = {peripheral.find("modem", function(name, object) return object.isWireless() end)}
local modems = {}

if not fs.exists("cache.lua") then --delete this file to reopen everything
	local cache = fs.open("cache.lua", "w")
	cache.writeLine("{")
	cache.flush()
	peripheral.find("modem", function(name, object) if object.isWireless() then cache.writeLine("\""..name.."\",") cache.flush() end return object.isWireless() end)
	cache.writeLine("}")
	cache.close()
end
local cache = fs.open("cache.lua", "r")
local names = textutils.unserialize(cache.readAll())
table.sort(names)
for i = 1, #names do
	table.insert(modems, peripheral.wrap(names[i]))
end

for k = 1, #modems do
    for i = 1,128 do
		local v = modems[k]
        if i+iter > 65535 then break end
		if not v.isOpen(i+iter) and not isBlacklisted(i+iter) then
        	v.open(i+iter)
        	channel = channel + 1
		end
    end
    iter = iter+128
    sleep()
end
print("finished with channel "..channel-1)


local function writeTime(color)
    term.setTextColor(colors.purple)
    write(textutils.formatTime(os.time("utc"), true).." ")
	term.setTextColor(color)
end

print("sniffer initialized!")
while true do
    local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")
    if distance == nil then distance = "unknown" end
    if not isBlacklisted(replyChannel) then
        writeTime(colors.white)
        print(senderChannel..":"..replyChannel..":"..distance..":")
		term.setTextColor(colors.red)
		print(textutils.serialize(msg))
        sleep(1)
    end
end
