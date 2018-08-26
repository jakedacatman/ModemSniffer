if not fs.exists("/gps.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/gps.lua gps.lua")
end

if not fs.exists("host.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/host.lua host.lua")
end

if not fs.exists("coords.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/coords.lua coords.lua")
    print("Edit coords.lua and put the host's coordinates in this order: x, y, z (replace the placeholders with your coordinates)")
else
    local coordsFile = fs.open("coords.lua", "r")
    local coords = textutils.unserialize(coordsFile.readAll())
    coordsFile.close()
    shell.run("host.lua", "host", coords[1], coords[2], coords[3])
end
