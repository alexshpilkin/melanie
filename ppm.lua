local ppm = setmetatable({__name = 'ppm'}, {__call = function (self, ...)
	return self.open(...)
end})
ppm.__index = ppm

local format = string.format
local bt709 = require 'bt709'
local quant, rgb = bt709.quant, bt709.rgb_

function ppm.open(file, width, height, options)
	if width == nil then -- open{file, ...}
		options, file = file, file[1]
	elseif height == nil then -- open(file, {...})
		options = width
	elseif options == nil then -- open(file, width, height)
		options = {}
	-- else -- open(file, width, height, {...})
	end

	if file == nil then
		file = io.output() -- pray it is in the right mode
	elseif not pcall(function () assert(file.write) end) then
		local err
		file, err = io.open(file, 'wb')
		if not file then return nil, err end
	end
	width  = assert(tonumber(options.width or width))
	height = assert(tonumber(options.height or height))
	local maxval = 2^assert(tonumber(options.depth or 8)) - 1
	assert(maxval < 65536)

	file:write(format('P3\n%d %d\n%d\n', width, height, maxval))

	return setmetatable({
		file = file, width = width, height = height, maxval = maxval,
		i = 0, j = 0
	}, ppm)
end

function ppm:__call(...) self:putpx(...) end

function ppm:putpx(x, y, z)
	local file, maxval, i = self.file, self.maxval, self.i + 1

	-- The PNM specifications say to limit ourselves to 70 chars/line,
	-- but meh, the files are easier to inspect this way.

	local r, g, b = rgb(x, y, z)
	file:write(format('%s%3d %3d %3d',
	                  i > 1 and '  ' or '',
	                  quant(r, 0, maxval),
	                  quant(g, 0, maxval),
	                  quant(b, 0, maxval)))

	if i == self.width then
		file:write('\n')
		i = 0; local j = self.j + 1
		if j == self.height then
			self.file:close()
			self.file, i, j = nil, nil, nil
		end
		self.j = j
	end
	self.i = i
end

return ppm
