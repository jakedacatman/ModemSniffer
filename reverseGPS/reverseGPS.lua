if not fs.exists("/"..shell.resolve "locate.lua") then shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/reverseGPS/locate.lua /"..shell.resolve "locate.lua") 
if not fs.exists("/"..shell.resolve "sniffConfig.lua") then shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/reverseGPS/sniffConfig.lua /"..shell.resolve "sniffConfig.lua") 

