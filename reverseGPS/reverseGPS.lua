local Config = require('config')
local GPS    = require('gps')
local Util   = require('util')
local fs         = _G.fs
local gps 			    = _G.gps
local os         = _G.os
local peripheral = _G.peripheral
local read       = _G.read
local term       = _G.term
local turtle     = _G.turtle
local vector     = _G.vector

local STARTUP_FILE = 'usr/autorun/reverseGPS.lua'

local function memoize(t, k, fn)
    local e = t[k]
	   if not e then
		        e = fn()
		        t[k] = e
	   end
	   return e
end

local function configure()
	local function getOption(prompt)
		while true do
			term.write(prompt)
			local value = read()
			if tonumber(value) then
				return tonumber(value)
			end
			print('Invalid value, try again.\n')
		end
	end

	print('rGPS configuration\n\n')

	Config.update('rGPS', {
		x = getOption('Turtle x: '),
		y = getOption('Turtle y: '),
		z = getOption('Turtle z: '),
		east = getOption('East modem: modem_'),
		south = getOption('South modem: modem_'),
		west = getOption('West modem: modem_'),
		north = getOption('North modem: modem_'),
  locate = getOption "Scan on channel "
	})

	print('Make sure all wired modems are activated')
	print('Enter to continue')
	read()

	if not fs.exists(STARTUP_FILE) then
		Util.writeFile(STARTUP_FILE,
			[[shell.openForegroundTab('reverseGPA.lua rGPS')]])
		print('Autorun program created: ' .. STARTUP_FILE)
	end
end

local function ok()
	local computers = { }

	if not fs.exists('usr/config/rGPS') then
		configure()
	end

	local config = Config.load('rGPS')

	local modems = { }
	modems['modem_' .. config.east]  = { x = config.x + 2, y = config.y + 2, z = config.z     }
	modems['modem_' .. config.west]  = { x = config.x - 2, y = config.y + 2, z = config.z     }
	modems['modem_' .. config.south] = { x = config.x,     y = config.y,     z = config.z + 2 }
	modems['modem_' .. config.north] = { x = config.x,     y = config.y,     z = config.z - 2 }

	for k, modem in pairs(modems) do
		Util.merge(modem, peripheral.wrap(k) or { })
		Util.print('%s: %d %d %d', k, modem.x, modem.y, modem.z)
		if not modem.open then
			error('Modem is not activated or connected: ' .. k)
		end
		modem.open(config.locate)
		--modem.open(999)
	end

	print('\nStarting rGPS')

	local function getPosition(computerId, modem, distance)
		local computer = memoize(computers, computerId, function() return { } end)
		table.insert(computer, {
			position = vector.new(modem.x, modem.y, modem.z),
			distance = distance,
		})
		if #computer == 4 then
			local pt = GPS.trilaterate(computer)
			if pt then
				positions[computerId] = pt
				term.clear()
				for k,v in pairs(positions) do
					Util.print('ID: %d: %s %s %s', k, v.x, v.y, v.z)
				end
			end
			computers[computerId] = nil
		end
	end

	while true do
		local e, side, channel, computerId, message, distance = os.pullEvent( "modem_message" )
			if distance and modems[side] then
				if channel == config.channel and message then
					getPosition(computerId, modems[side], distance)
				end
			end
	end
end

ok()
