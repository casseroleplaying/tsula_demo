--[[
    Key 4 Feather objects for game progression
]]

Feather = Class{}

function Feather:init(map, num, x, y)

    self.map = map                  -- reference to map
    self.w = 40                     -- width and height in px
    self.h = 40

    self.x = x * map.tileW          -- initial map position
    self.y = y * map.tileH
    self.num = num                  -- track which feather object of 4

    self.direction = 'left'
    self.xOffset = self.w / 2       -- sprite flip offsets (top left to center)
    self.yOffset = self.h / 2

    self.found = false              -- flags text box when found
    self.marked = false             -- sets as marked to move game state

    self.texture = love.graphics.newImage('graphics/tsula_environment.png')
    self.frame = love.graphics.newQuad(
            40 * (self.num - 1), 80, self.w, self.h, 160, 400)

    self.sound = love.audio.newSource('sounds/item2.wav', 'static')
end

-- update feather status, checks if found by player, sends sprite to hud
function Feather:update(dt)
    -- upon discovery, display text, and update gameState
    if map:contact(self, map.player) and not self.found then
        self.found = true
        gameState = START + self.num
        halt = true
        self.direction = 'right'

        if self.marked == false then
            map.player.hp = math.min(map.player.hp + 15, 100)
            self.y = self.y - 20
            self.sound:play()
            map.itemsFound = map.itemsFound + 1
            self.marked = true
        end
    end
end

function Feather:render()
    local scaleX

    -- negative x scale factor if facing left, flips sprite when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- move feather to HUD if recovered
    if self.marked == true and halt == false then
        self.x = math.floor(map.camX + screen_w - 240 + self.num * 40)
        self.y = math.floor(map.camY + 40)
    end

    -- draw sprite with scale factor and offsets
    love.graphics.draw(self.texture, self.frame, 
        math.floor(self.x + self.xOffset), math.floor(self.y + self.yOffset), 
        0, scaleX, 1, self.xOffset, self.yOffset)
end
