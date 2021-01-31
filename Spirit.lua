--[[
    Represents cloud spirits
]]

Spirit = Class{}

local WALKING_SPEED = 100
local RESPAWN_LMT = 120

function Spirit:init(map, x, y)

    self.map = map                  -- reference to map
    self.w = 80                     -- height and width in px
    self.h = 80

    self.x = x * map.tileW          -- initial map position
    self.y = y * map.tileH

    self.dx = WALKING_SPEED         -- x and y velocity
    self.dy = 0
    self.state = 'moving'           -- spirit state
    self.direction = 'right'
    self.xOffset = self.w / 2       -- sprite flip offsets (top left to center)
    self.yOffset = self.h / 2

    self.respawn = 0                -- respawn timer           
    self.burst = false              -- show burst sprites from player hit
    self.active = true              -- track status from player hit

    -- reference to map for checking tiles
    self.texture = love.graphics.newImage('graphics/tsula_sprite_sheet.png')
    self.sprites = generateQuads(self.texture, self.w, self.h)

    self.sounds = {
        ['suck'] = love.audio.newSource('sounds/spirit2.wav', 'static')
    }

    -- animation frames
    self.frames = {}
    self.currentFrame = nil

    -- cloud dispersal sprites
    self.burstSprites = {
        self.sprites[spiritBurst[1]],
        self.sprites[spiritBurst[2]],
        self.sprites[spiritBurst[3]],
        self.sprites[spiritBurst[4]]
    }

    -- initialize spirit animations
    self.animations = {
        ['moving'] = Animation({
            texture = self.texture,
            frames = { self.sprites[spirit[1]] }
        }),
        ['contact'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[spirit[1]],
                self.sprites[spirit[2]],
                self.sprites[spirit[3]]
            },
            interval = 0.2
        }),
        ['vanish'] = Animation({
            texture = self.texture,
            frames = { self.sprites[spiritBlue] }
        })
    }

    -- initialize animation and current frame to render
    self.animation = self.animations['moving']
    self.currentFrame = self.animation:getCurrentFrame()
end

-- updates all spirit status
function Spirit:update(dt)
    self:hit()
    self:collisionLR()
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()

    -- update position of spirit
    self.x = self.x + self.dx * dt

    -- run the respawn counter if in blue mode from player burst / dash
    if self.active == false then
        self.respawn = self.respawn + 1
    end

    -- reset respawn timer and reactivate spirit
    if self.respawn >= RESPAWN_LMT then
        self.active = true
        self.respawn = 0
        self.animation = self.animations['moving']
    end
end

-- check for collision w player and react
function Spirit:hit()

    if map:contact(self, map.player) and gameState > TITLE then

        -- if the player is dashing or pouncing, turn blue and do no damage
        if (map.player.state == 'dash' or map.player.state == 'pounce')
            and self.respawn < RESPAWN_LMT then
            self.active = false
            self.burst = true
            self.animation = self.animations['vanish']

        -- do damage
        elseif self.active == true then
            self.sounds['suck']:play()
            self.animation = self.animations['contact']

            if map.player.hp > 0 then
                map.player.hp = map.player.hp - 0.12
            else
                map.player.hp = 0
            end
        end

    elseif self.active == true then
        self.animation = self.animations['moving']
    end
end

-- checks two tiles l/r for collision
function Spirit:collisionLR()
    -- invert dx if spirit hits wall or end of platform
    if self.dx > 0 and (not self:collisionBelow() or
        self.map:collides(self.x + 80, self.y + 60)) then
        self.dx = -self.dx
        self.direction = 'left'

    elseif self.dx < 0 and (not self:collisionBelow() or
            self.map:collides(self.x, self.y + 60)) then
        self.dx = -self.dx
        self.direction = 'right'
    end
end

-- check for collision below spirit
function Spirit:collisionBelow()
    if self.direction == 'right' then
        xOffset = 90
    else
        xOffset = 0
    end

    if self.map:collides(self.x + xOffset, self.y + self.h) then
            return true
    end
    return false
end

-- render the spirit to the map in it's current state
function Spirit:render()
    local scaleX

    -- negative x scale factor if facing left, flips sprite when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- draw sprite with scale factor and offsets
    love.graphics.draw(self.texture, self.currentFrame, 
        math.floor(self.x + self.xOffset), math.floor(self.y + self.yOffset), 
        0, scaleX, 1, self.xOffset, self.yOffset)

    -- render spirit burst and reset
    if self.burst == true then
        love.graphics.draw(self.texture, self.burstSprites[1], 
        math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset - self.h), 
        0, 1, 1, self.xOffset, self.yOffset)

        love.graphics.draw(self.texture, self.burstSprites[2], 
        math.floor(self.x + self.xOffset + self.w),
        math.floor(self.y + self.yOffset), 
        0, 1, 1, self.xOffset, self.yOffset)

        love.graphics.draw(self.texture, self.burstSprites[3], 
        math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset + self.h), 
        0, 1, 1, self.xOffset, self.yOffset)

        love.graphics.draw(self.texture, self.burstSprites[4], 
        math.floor(self.x + self.xOffset - self.w),
        math.floor(self.y + self.yOffset), 
        0, 1, 1, self.xOffset, self.yOffset)

        self.burst = false
    end
end