local function trilaterate( A, B, C )
    local a2b = B.position - A.position
    local a2c = C.position - A.position
       
    if math.abs( a2b:normalize():dot( a2c:normalize() ) ) > 0.999 then
        return nil
    end
   
    local d = a2b:length()
    local ex = a2b:normalize( )
    local i = ex:dot( a2c )
    local ey = (a2c - (ex * i)):normalize()
    local j = ey:dot( a2c )
    local ez = ex:cross( ey )
 
    local r1 = A.distance
    local r2 = B.distance
    local r3 = C.distance
       
    local x = (r1*r1 - r2*r2 + d*d) / (2*d)
    local y = (r1*r1 - r3*r3 - x*x + (x-i)*(x-i) + j*j) / (2*j)
       
    local result = A.position + (ex * x) + (ey * y)
 
    local zSquared = r1*r1 - x*x - y*y
    if zSquared > 0 then
        local z = math.sqrt( zSquared )
        local result1 = result + (ez * z)
        local result2 = result - (ez * z)
       
        local rounded1, rounded2 = result1:round( 0.01 ), result2:round( 0.01 )
        if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
            return rounded1, rounded2
        else
            return rounded1
        end
    end
    return result:round( 0.01 )
end
 
local function narrow( p1, p2, fix )
    local dist1 = math.abs( (p1 - fix.position):length() - fix.distance )
    local dist2 = math.abs( (p2 - fix.position):length() - fix.distance )
   
    if math.abs(dist1 - dist2) < 0.01 then
        return p1, p2
    elseif dist1 < dist2 then
        return p1:round( 0.01 )
    else
        return p2:round( 0.01 )
    end
end
 
if not fs.exists("/"..shell.resolve "sniffConfig.lua") then shell.run("wget https://raw.githubusercontent.com/jakedacatman/ModemSniffer/master/reverseGPS/sniffConfig.lua /"..shell.resolve "sniffConfig.lua") 
local file = fs.open("/"..shell.resolve "sniffConfig.lua", "r")
local config = textutils.unserialize(file.readAll())
file.close()
if #config.channels > 128 then error "modems can only have 128 channels open" end

local isWanted(channel)
  for i = 1, #config.channels do
    if channel == i then return true end
  end
  return false
end

function locate(event, timeout)
    while true do
        local fixes = {}
        local timer = os.startTimer(timeout)
        repeat
            local args = {os.pullEvent("timer")}
            if args[2] == timer then return nil end     
            local _, side, chan, reply_chan, message = event
            if isWanted(chan) and type(message) ~= "nil" and tonumber(message[1]) and tonumber(message[2]) and tonumber(message[3]) and tonumber(message[4]) then                
                if debug then print("got a position ("..textutils.serialize(message)..")") end
                message.position = vector.new(message[1], message[2], message[3])
                message.distance = message[4]
                table.insert(fixes, message)
            end
        until #fixes == 4
 
        local first = fixes[1]
        local p1, p2 = trilaterate(fixes[1], fixes[2], fixes[3])
        if p1 and p2 then
            local pos = narrow(p1, p2, fixes[4])
            if debug then print(textutils.serialize(pos)) end
            return pos
        else 
            return nil 
        end
    end
end
