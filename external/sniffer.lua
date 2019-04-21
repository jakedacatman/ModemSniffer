--8
--delay in config
 
local version = 8
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/external/sniffer.lua")
 
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
                    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/external/sniffer.lua sniffer.lua")
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
 
if not fs.exists("sniffConfig.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/external/sniffConfig.lua sniffConfig.lua")
end


local configFile = fs.open("sniffConfig.lua", "r")
local config = textutils.unserialize(configFile.readAll())
configFile.close()

local channel = config.channel or 31415

local monitor = peripheral.find("monitor")
if monitor then
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorPos(1,1)
    monitor.setTextColor(colors.white)
    term.redirect(monitor)
end

local modem = peripheral.find("modem", function(name, object) return object.isWireless() end)
modem.open(channel)

local function writeTime(color)
    term.setTextColor(colors.purple)
    write(textutils.formatTime(os.time("utc"), true).." ")
    term.setTextColor(color)
end

local function writeInfo(color, sender, receiver, distance, dimension)
    term.setTextColor(colors.yellow)
	print("sender: "..sender.." reply: "..receiver.." distance: "..distance.." dimension: "..dimension)
	term.setTextColor(color)
end

local function isBlacklisted(channel, blacklist)
    for i = 1, #blacklist do
        if channel == blacklist[i] then return true end
    end
    return false
end

while true do
	local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")
	
	local message = msg.message
	local allowedOrigin = config.origin or msg.origin
	local blacklist = config.blacklist or {}
	distance = msg.distance or "unknown"
	local dimension = msg.dimension or "unknown"
	
	if not isBlacklisted(msg.senderChannel, blacklist) and msg.origin == allowedOrigin then
		writeTime(colors.white)
		writeInfo(colors.green, msg.senderChannel, msg.replyChannel, distance, dimension)
		local s = textutils.serialize(message)
		if config.truncate and type(config.truncate) == "number" then
			if s:len() > config.truncate then
				s = s:sub(1, config.truncate).."...\n}"
			end
		end
		print(s)
	end
	sleep(config.delay)
end
