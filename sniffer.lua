--1
--first commit
 
local version = 1
 
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
                    print("If you wish to run the new version, then hold CTRL+R and run sniffer.lua.")
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

local monitor = peripheral.wrap("monitor_834")
monitor.clear()
monitor.setTextScale(0.5)
monitor.setCursorPos(1,1)
term.redirect(monitor)
 
local blacklist = { } --enter the number of a channel you wish to blacklist from sniffing
 
local iter = 0
local channel = 1

for i,v in pairs({peripheral.find("modem", function(name, object) return object.isWireless() end)}) do
    for i = 1,128 do
        if channel > 65535 then break end
        v.open(i+iter)
        for k, bl in pairs(blacklist) do
            if i+iter == bl then v.close(i+iter) end
        end
        channel = channel+1
    end
    iter = iter+128
    sleep()
end
print("finished with channel "..channel-1)
 
--local modem = peripheral.find("modem", function(name, object) return object.isWireless() end)
local modem = peripheral.wrap("front")
 
local function isBlacklisted(channel)
    for i = 1, #blacklist do
        if channel == blacklist[i] then return true end
    end
    return false
end
print("sniffer initialized!")
while true do
    local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")
    if distance == nil then distance = "unknown" end
    if not isBlacklisted(replyChannel) then
    --print(event, side , senderChannel, replyChannel, msg, distance)
        print(senderChannel..":"..replyChannel..":"..distance..": \n"..textutils.serialize(msg))
        sleep(1)
    end
end
