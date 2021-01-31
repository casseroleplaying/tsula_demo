--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen. References MapInfo.lua heavily
]]

require 'Util'

Map = Class{}

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- a basic map referenced for the construction of game map
local imageData = love.image.newImageData('graphics/tsula_map.png')

-- constructor for map obj
function Map:init()

    self.tileW = 40                         -- tile h and w in px
    self.tileH = 40
    self.mapW = 96                          -- map w and h in tiles
    self.mapH = 96
    self.mapWPx = self.mapW * self.tileW    -- map w and h in px
    self.mapHPx = self.mapH * self.tileH

    self.spritesheet = love.graphics.newImage('graphics/environment2.png')
    self.sprites = generateQuads(self.spritesheet, self.tileW, self.tileH)
    self.music = love.audio.newSource('music/ambient_guitar.wav', 'static')

    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 15

    -- associate player, feathers, spirits, HUD and textboxes with map
    self.hud = HUD(self)
    self.textBox = TextBox(self)
    self.spirits = {}
    self.feathers = {}

    -- camera offsets
    self.camX = 0
    self.camY = -3

    -- counters for feather placement, collection
    self.itemNum = 0
    self.itemsFound = 0

    -- generate the map w vertical scan lines
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            -- set empty tile by default
            self:setTile(x, y, TILE_EMPTY)

            -- get pixel from basic map for r(gb) value comparison
            local r, g, b = imageData:getPixel(x-1, y-1)

            -- set tiles based on r value of pixel scanned
            if r == FOX_R then
                self.player = Player(self, x-1, y-2)
            elseif r == ITEM_R then
                self.itemNum = self.itemNum + 1
                table.insert(self.feathers,
                    Feather(self, self.itemNum, x-1, y-1))
            elseif r == SPIRIT_R then
                table.insert(self.spirits, Spirit(self, x-1, y-2))
            elseif r == PLANT_R then
                self:setTile(x, y, 1 + math.random(7))
            elseif r == DIRT_R then
                self:setDirt(x, y)
            elseif r == SPIKE_R then
                self:setSpike(x, y)
            end
        end
    end

    -- play background music
    self.music:setLooping(true)
    self.music:play()
end

-- determines which dirt tile to place
function Map:setSpike(x, y)
    local rE, gE, bE = imageData:getPixel(x, y-1)   -- tile to be placed right
    local rS, gS, bS = imageData:getPixel(x-1, y)   -- tile to be placed below
    tileRight = rE                                  -- only need r values
    tileBelow = rS
    tileLeft = self:getTile(x-1, y)
    tileAbove = self:getTile(x, y-1)

    -- above tile is empty
    if tileAbove < DIRT_NW then
        if tileLeft < DIRT_NW then
            self:setTile(x, y, SPIKE_NW)
        elseif tileRight < SPIKE_R then
            self:setTile(x, y, SPIKE_NE)
        else
            self:setTile(x, y, SPIKE_N)
        end

    -- tile to left is empty
    elseif tileLeft < DIRT_NW then
        if tileBelow < SPIKE_R then
            self:setTile(x, y, SPIKE_SW)
        else
            self:setTile(x, y, SPIKE_W)
        end

    -- tile to right is empty
    elseif tileRight < SPIKE_R then
        if tileBelow < SPIKE_R then
            self:setTile(x, y, SPIKE_SE)
        else
            self:setTile(x, y, SPIKE_E)
        end

    -- tile below is empty
    elseif tileBelow < SPIKE_R then
        self:setTile(x, y, SPIKE_S)
    end
end

-- determines which dirt tile to place
function Map:setDirt(x, y)
    local rE, gE, bE = imageData:getPixel(x, y-1)   -- tile to be placed right
    local rS, gS, bS = imageData:getPixel(x-1, y)   -- tile to be placed below
    tileRight = rE                                  -- only need r values
    tileBelow = rS
    tileLeft = self:getTile(x-1, y)
    tileAbove = self:getTile(x, y-1)

    -- above tile is empty
    if tileAbove < DIRT_NW then
        if tileLeft < DIRT_NW then
            self:setTile(x, y, DIRT_NW)
        elseif tileRight < SPIKE_R then
            self:setTile(x, y, DIRT_NE)
        else
            self:setTile(x, y, DIRT_N)
        end

    -- tile to left is empty
    elseif tileLeft < DIRT_NW then
        if tileBelow < SPIKE_R then
            self:setTile(x, y, DIRT_SW)
        else
            self:setTile(x, y, DIRT_W)
        end

    -- tile to right is empty
    elseif tileRight < SPIKE_R then
        if tileBelow < SPIKE_R then
            self:setTile(x, y, DIRT_SE)
        else
            self:setTile(x, y, DIRT_E)
        end

    -- tile below is empty
    elseif tileBelow < SPIKE_R then
        self:setTile(x, y, DIRT_S)

    -- default use internal dirt tile
    else
        self:setTile(x, y, DIRT)
    end
end

-- return true if tile at x, y is collidable
function Map:collides(x, y)
    tile = self:tileAt(x, y)
    -- only dirt tiles and spikes are collidable on the map
    if (tile.id >= DIRT_NW and tile.id <= SPIKE_SE) then
        return true
    end
    return false
end

-- update camera offset with delta time
function Map:update(dt)

    -- update all map associated objects
    self.player:update(dt)
    for i in ipairs(self.feathers) do
        self.feathers[i]:update(dt)
    end
    for i in ipairs(self.spirits) do
        self.spirits[i]:update(dt)
    end

    -- camera coordinates follow player, stopping at edges of map
    self.camX = math.max(0, 
        math.min(self.player.x - screen_w / 2, self.mapWPx - screen_w))      

    -- stop y tracking if end of game (fly off screen)
    if gameState ~= ALL then
        self.camY = math.max(0, 
            math.min(self.player.y - screen_h / 2, self.mapHPx - screen_h))
    end
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileW) + 1,
        y = math.floor(y / self.tileH) + 1,
        id = self:getTile(math.floor(x / self.tileW) + 1,
                            math.floor(y / self.tileH) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapW + x]
end


-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapW + x] = id
end

-- checks if two map objects are contacting/overlapping
function Map:contact(obj1, obj2)
    if (obj1.x > obj2.x - 80 and obj1.x < obj2.x + 80) and
        (obj1.y > obj2.y - 80 and obj1.y < obj2.y + 80) then
        return true
    end
    return false
end

-- renders map to screen, called by main's render
function Map:render()

    for y = 1, self.mapH do
        for x = 1, self.mapW do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileW, (y - 1) * self.tileH)
            end
        end
    end

    -- render map associated objects
    self.player:render()
    for i in ipairs(self.feathers) do
        self.feathers[i]:render()
    end
    for i in ipairs(self.spirits) do
        self.spirits[i]:render()
    end
    self.hud:render()
    self.textBox:render()
end