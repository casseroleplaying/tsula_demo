--[[
    Represents player in the game, with its own sprite.
]]

Player = Class{}

local WALKING_SPEED = 180
local JUMP_VELOCITY = 540
local CD_MAX = 12               -- cooldown limit
local DASH_X = 6                -- velocity multiplier for dash/burst/pounce

-- constructor
function Player:init(map, x, y)

    self.map = map              -- reference to map object
    self.w = 80                 -- player height and width
    self.h = 80

    self.x = x * map.tileW      -- initial position on map
    self.y = y * map.tileH
    self.startX = self.x        -- checkpoint variables
    self.startY = self.y - self.h
    self.checkpointX = 0        
    self.checkpointY = 0

    self.dx = 0                 -- x and y velocity
    self.dy = 0
    self.state = 'idle'         -- player state
    self.direction = 'left'
    self.xOffset = self.w / 2   -- sprite flip offsets (top left to center)
    self.yOffset = self.h / 2

    self.hp = 100               -- hit points (consumed by spirit clouds)

    self.alive = true           -- for spike contact death/respawn
    self.dashed = false         -- limit one dash / burst per jump
    self.bursted = false        -- i am aware bursted is NOT a word :)
    self.showControls = false   -- toggle controls view

    self.itemTotal = 0          -- tracks number of feathers found
    self.timer = 0              -- animation/state timer on game end states
    self.idleTime = 0           -- timer for idle/stretch animation
    self.cooldown = 0           -- cooldown timer

    -- sound effects
    self.sounds = {
        ['flight'] = love.audio.newSource('sounds/screech.wav', 'static'),
        ['dash'] = love.audio.newSource('sounds/whoosh.wav', 'static'),
        ['death'] = love.audio.newSource('sounds/death.wav', 'static')
     }

    -- animation frames
    self.frames = {}
    self.currentFrame = nil

    -- get sprites from texture
    self.texture = love.graphics.newImage('graphics/tsula_sprite_sheet.png')
    self.sprites = generateQuads(self.texture, self.w, self.h)

    -- static trail frames for dash/pounce/burst
    self.dashFrames = {
        self.sprites[dash[1]],
        self.sprites[dash[2]]
    }
    self.pounceFrames = {
        self.sprites[pounce[1]],
        self.sprites[pounce[2]]
    }

    -- initialize player animations
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = { self.sprites[walking[1]] } 
        }),
        ['stretch'] = Animation({
            texture = self.texture,
            frames = { 
                self.sprites[stretch[8]],
                self.sprites[stretch[4]],
                self.sprites[stretch[5]],
                self.sprites[stretch[6]],
                self.sprites[stretch[6]],
                self.sprites[stretch[6]],
                self.sprites[stretch[6]],
                self.sprites[stretch[7]],
                self.sprites[stretch[8]],
                self.sprites[stretch[8]]
            },
            interval = 0.15
        }),
        ['dash'] = Animation({
            texture = self.texture,
            frames = { self.sprites[dash[3]] } 
        }),
        ['pounce'] = Animation({
            texture = self.texture,
            frames = { self.sprites[pounce[3]] }
        }),
        ['crouching'] = Animation({
            texture = self.texture,
            frames = { self.sprites[crawling[1]] }
        }),
        ['walking'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[walking[1]],
                self.sprites[walking[2]],
                self.sprites[walking[3]],
                self.sprites[walking[4]],
                self.sprites[walking[5]],
                self.sprites[walking[6]],
                self.sprites[walking[7]],
                self.sprites[walking[8]]
            
            },
            interval = 0.1
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[jumping[1]],
                self.sprites[jumping[2]],
                self.sprites[jumping[3]],
                self.sprites[jumping[4]],
                self.sprites[jumping[5]],
                self.sprites[jumping[6]]
            },
            interval = 0.15
        }),
        ['crawling'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[crawling[1]],
                self.sprites[crawling[2]],
                self.sprites[crawling[3]],
                self.sprites[crawling[4]],
                self.sprites[crawling[5]],
                self.sprites[crawling[6]]
            },
            interval = 0.15
        }),
        ['transform'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[transform[1]],
                self.sprites[transform[2]],
                self.sprites[transform[3]],
                self.sprites[transform[4]],
                self.sprites[transform[5]],
                self.sprites[transform[6]],
                self.sprites[transform[7]],
                self.sprites[transform[8]]
            },
            interval = 0.15
        }),
        ['falcon'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[falcon[1]],
                self.sprites[falcon[2]],
                self.sprites[falcon[3]],
                self.sprites[falcon[4]]
            },
            interval = 0.1
        }),
        ['lost'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[transform[1]],
                self.sprites[transform[2]],
                self.sprites[transform[3]],
                self.sprites[transform[4]]
            },
            interval = 0.2
        }),
        ['death'] = Animation({
            texture = self.texture,
            frames = {
                self.sprites[death]
            }
        })
    }

    -- initialize animation and current frame to render
    self.animation = self.animations['idle']
    self.currentFrame = self.animation:getCurrentFrame()

    -- player state behaviors
    self.behaviors = {

        ['idle'] = function(dt)
            self.idleTime = self.idleTime + 1
            self.dx = 0
            -- go into stretch animation every ~5 seconds spent idle
            if self.idleTime > 300 then
                self.animation = self.animations['stretch']
                if self.animation:getFrameNumber() == 9 then
                    self.animations['stretch']:restart()
                    self.idleTime = 0
                end
            else
                self.animation = self.animations['idle']
            end
            self:checkInput()
            self:collisionLR()
        end,

        ['walking'] = function(dt)
            self.animation = self.animations['walking']
            self:checkInput()
            self:collisionLR()
        end,

        ['crawling'] = function(dt)
            self.animation = self.animations['crawling']
            self:checkInput()
            self:collisionLR()
        end,

        ['crouching'] = function(dt)
            self.dx = 0
            self.animation = self.animations['crouching']
            self:checkInput()
            self:collisionLR()
        end,

        ['jumping'] = function(dt)
            self.animation = self.animations['jumping']
            self:setDirectionDX()
            self.dy = self.dy + self.map.gravity
            self:collisionLR()

            -- check collision above
            if self.dy < 0 and self:collisionAbove() == true then
                self.dy = 0
            end
            -- check collision below
            if self:collisionBelow() then
                self.idleTime = 0
                self.state = 'idle'
                self.dy = 0
                self.y = (self.map:tileAt(self.x, self.y + self.h).y - 1) *
                    self.map.tileH - self.h
            end

            -- dash
            if (love.keyboard.isDown('left') or love.keyboard.isDown('right'))  
                and (active('a') or active('d')) then
                    if self.cooldown < CD_MAX and self.dashed == true then
                        self.state = 'dash'
                        self.sounds['dash']:play()
                    end

            -- pounce
            elseif love.keyboard.isDown('down') then
                self.state = 'pounce'

            -- burst upward
            elseif love.keyboard.isDown('up') and self.cooldown < CD_MAX
                and self.bursted == true then
                self.state = 'burst'
            end
        end,

        ['dash'] = function (dt)
            -- dash if within cooldown limit
            if self.cooldown < CD_MAX then
                self.cooldown = self.cooldown + 1
                if self.direction == 'left' then
                    self.dx = -WALKING_SPEED * DASH_X
                else
                    self.dx = WALKING_SPEED * DASH_X
                end 
                self.dy = 0
                self.animation = self.animations['dash']
                self:collisionLR()
                self.dashed = false         -- reset dash bool
            else
                self.state = 'jumping'
            end
        end,

        ['pounce'] = function (dt)
            self.animation = self.animations['pounce']
            self.dy = WALKING_SPEED * DASH_X
            self.dx = 0
            if self:collisionBelow() then
                self.dy = 0
                self.idleTime = 0
                self.state = 'idle'
                self.y = (self.map:tileAt(self.x, self.y + self.h).y - 1) 
                        * self.map.tileH - self.h
            end
        end,

        ['burst'] = function (dt)
            -- burst if within cooldown limit
            if self.cooldown < CD_MAX then
                self.cooldown = self.cooldown + 1
                self.animation = self.animations['pounce']
                self.dy = -WALKING_SPEED * DASH_X / 2
                self.dx = 0
                self.bursted = false        -- reset burst bool
                if self:collisionAbove() then
                    self.dy = 0
                    self.state = 'jumping'
                end
            else
                self.state = 'jumping'
            end
        end,

        ['lost'] = function (dt)
            self.animation = self.animations['lost']
            self.dx = 0
            self.dy = 0
        end,

        ['death'] = function (dt)
            self.animation = self.animations['death']
        end,

        ['falcon'] = function (dt)
            -- dummy state, does nothing
        end
    }
end

-- sets player direction and dx based on input
function Player:setDirectionDX()
    if love.keyboard.isDown('a') then
        self.direction = 'left'
        if self.state == 'walking' or self.state == 'crawling' or 
            self.state == 'jumping' then
            self.dx = -WALKING_SPEED
        end

    elseif love.keyboard.isDown('d') then
        self.direction = 'right'
        if self.state == 'walking' or self.state == 'crawling' or 
            self.state == 'jumping' then
            self.dx = WALKING_SPEED
        end
    end
end

-- checks input and manages player states and animations
function Player:checkInput()

    -- toggle controls view
    if love.keyboard.wasPressed('c') then
        if self.showControls == false then
            self.showControls = true
        elseif self.showControls == true then
            self.showControls = false
        end
    end

    self:setDirectionDX()           -- set direction and dx

    -- falling
    if not self:collisionBelow() then
        self.state = 'jumping'
        self.animations['jumping']:restart()

    -- jump
    elseif love.keyboard.wasPressed('space') and not self:wedged() then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animations['jumping']:restart()
        self.dashed = true          -- reset action bools when initiate a jump
        self.bursted = true

    -- crouch / crawl
    elseif active('s') then
        if active('a') or active('d') then
            self.state = 'crawling'
        else
            self.state = 'crouching'
        end

    -- walk / dash
    elseif (active('a') or active('d')) and not self:wedged() then
        if (active('left') or active('right')) and self.cooldown < CD_MAX then
            self.state = 'dash'
            self.sounds['dash']:play()
        else
            self.state = 'walking'
        end

    -- default return to idle state
    elseif not self:wedged() then
            if self.state ~= 'idle' then
                self.idleTime = 0
            end
            self.state = 'idle'
    end
end

-- returns true if player is crouching/crawling with a low tile overhead
function Player:wedged()
    if (self.state == 'crawling' or self.state == 'crouching') and  
        self:collisionAbove() == true then
        return true
    end
    return false
end

-- returns player to one of 3 checkpoints if collision with spikes
function Player:setCheckPoint()
    if self.y < 23 * map.tileH then
        self.checkpointX = 42 * map.tileW
        self.checkpointY = 23 * map.tileH
    elseif self.y > 74 * map.tileH then
        self.checkpointX = 49 * map.tileW
        self.checkpointY = 74 * map.tileH
    else
        self.checkpointX = self.startX
        self.checkpointY = self.startY
    end
end

-- updates all player status
function Player:update(dt)

    self:setCheckPoint()        -- set current checkpoint
    self:endStates()            -- check end states of the game

    -- check cooldown, reset on limit
    if self.cooldown >= CD_MAX and self.cooldown < CD_MAX * 3 then
        self.cooldown = self.cooldown + 1
    elseif self.cooldown >= CD_MAX * 3 then
        self.cooldown = 0
    end

    -- stop player movement to read text boxes, else update
    if halt == true then
        self.state = 'idle'
        self.animation = self.animations['idle']
        self.dx = 0
    else
        self.behaviors[self.state](dt)
        self.animation:update(dt)
        self.currentFrame = self.animation:getCurrentFrame()

        -- stop player from moving off map
        if self.x < 10 then
            self.x = 12
        elseif self.x > map.mapW * map.tileW - 90 then
            self.x = map.mapW * map.tileW - 92
        elseif self.y < 10 and gameState < ALL then
            self.y = 12

        -- update position
        else
            self.x = self.x + self.dx * dt
            self.y = self.y + self.dy * dt
        end

        --self:endStates()            -- check end states of the game
    end
end

-- checks if reached various end states of game
function Player:endStates()

    -- game over if hp == 0
    if self.hp == 0 then
        self.state = 'lost'
        self.timer = self.timer + 1
        if self.timer > 60 then
            gameState = LOST
            self.hp = 100
            self.timer = 0
        end

    -- if spike collision respawn at last checkpoint
    elseif self.alive == false then
        self.state = 'death'
        self.timer = self.timer + 1
        if self.timer > 15 then
            self.state = 'idle'
            self.x = self.checkpointX
            self.y = self.checkpointY
            self.alive = true
            self.timer = 0
        end
    
    -- end game transformation on success
    elseif gameState == ALL and halt == false then
        self.dx = 0
        self.state = 'falcon'
        self.timer = self.timer + 1

        if self.timer > 320 and self.y < map.camY - 120 then
            self.sounds['flight']:play()
            self.animation = self.animations['falcon']
            gameState = END
        elseif self.timer > 60 then
            self.sounds['flight']:play()
            self.animation = self.animations['falcon']
            self.dy = -180
        else
            self.animation = self.animations['transform']
        end
    
    -- all items found, display text after 4th item textbox
    elseif map.itemsFound == 4 and halt == false and gameState < ALL then
        halt = true
        gameState = ALL
    end
end

-- checks for collision above the player
function Player:collisionAbove()
    if self.direction == 'right' then
        head = self.w - 3
        tail = 25
    else
        head = 3
        tail = self.w - 25
    end

    -- checks for collision with spikes
    tileAtHead = map:tileAt(self.x + head, self.y + 18)
    tileAtRear = map:tileAt(self.x + tail, self.y + 18)
    if tileAtHead.id >= SPIKE_NW or tileAtRear.id >= SPIKE_NW then
        self.sounds['death']:play()
        self.alive = false
    end

    if self.map:collides(self.x + head, self.y + 18) or
        self.map:collides(self.x + tail, self.y + 18) then       
        return true
    end

    return false
end

-- checks for collision below the player
function Player:collisionBelow()
    if self.direction == 'right' then
        head = self.w - 3
        tail = 25
    else
        head = 3
        tail = self.w - 25
    end

    -- checks for collision with spikes
    tileAtHead = map:tileAt(self.x + head, self.y + self.h)
    tileAtRear = map:tileAt(self.x + tail, self.y + self.h)
    if tileAtHead.id >= SPIKE_NW or tileAtRear.id >= SPIKE_NW then
        self.sounds['death']:play()
        self.alive = false
    end

    if self.map:collides(self.x + head, self.y + self.h) or
        self.map:collides(self.x + tail, self.y + self.h) then
            return true
    end

    return false
end

-- checks two tiles l/r for collision
function Player:collisionLR()
    if self.state == 'crawling' or self.state == 'crouching' then
        yOffset = 45
    else
        yOffset = 18
    end

    if self.dx > 0 then
        xOffset = self.w
    else
        xOffset = 0
    end

    -- check if collision w spikes
    tileAtHead = map:tileAt(self.x + xOffset, self.y + yOffset)
    tileAtFeet = map:tileAt(self.x + xOffset, self.y + self.h - 1)
    if tileAtHead.id >= SPIKE_NW or tileAtFeet.id >= SPIKE_NW then
        self.sounds['death']:play()
        self.alive = false
    end

    -- set the bounds for upper and lower collision of the player (head and paw)
    upperCollision = self.map:collides(self.x + xOffset, self.y + yOffset)
    lowerCollision = self.map:collides(self.x + xOffset, self.y + self.h - 1)
    if self.dx ~= 0 and (upperCollision or lowerCollision) then
        self.dx = 0
    end
end

-- render the player to the map in it's current state
function Player:render()
    local scaleX

    -- negative x scale factor if facing left, flips sprite when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- draw dash trail sprites
    if self.state == 'dash' then
        if self.direction == 'left' then
            love.graphics.draw(self.texture, self.dashFrames[2],
                math.floor(self.x + self.xOffset + 24),
                math.floor(self.y + self.yOffset),
                0, scaleX, 1, self.xOffset, self.yOffset)
            love.graphics.draw(self.texture, self.dashFrames[1],
                math.floor(self.x + self.xOffset + 12),
                math.floor(self.y + self.yOffset),
                0, scaleX, 1, self.xOffset, self.yOffset)
        else
            love.graphics.draw(self.texture, self.dashFrames[1],
                math.floor(self.x + self.xOffset - 24),
                math.floor(self.y + self.yOffset),
                0, scaleX, 1, self.xOffset, self.yOffset)
            love.graphics.draw(self.texture, self.dashFrames[2],
                math.floor(self.x + self.xOffset - 12),
                math.floor(self.y + self.yOffset),
                0, scaleX, 1, self.xOffset, self.yOffset)
        end

    -- draw pounce trail sprites
    elseif self.state =='pounce' then
        love.graphics.draw(self.texture, self.pounceFrames[1],
            math.floor(self.x + self.xOffset), 
            math.floor(self.y + self.yOffset - 24), 
            0, scaleX, 1, self.xOffset, self.yOffset)
        love.graphics.draw(self.texture, self.pounceFrames[2],
            math.floor(self.x + self.xOffset), 
            math.floor(self.y + self.yOffset - 12), 
            0, scaleX, 1, self.xOffset, self.yOffset)

    -- draw burst trail sprites
    elseif self.state =='burst' then
        love.graphics.draw(self.texture, self.pounceFrames[1],
            math.floor(self.x + self.xOffset), 
            math.floor(self.y + self.yOffset + 24), 
            0, scaleX, 1, self.xOffset, self.yOffset)
        love.graphics.draw(self.texture, self.pounceFrames[2],
            math.floor(self.x + self.xOffset), 
            math.floor(self.y + self.yOffset + 12), 
            0, scaleX, 1, self.xOffset, self.yOffset)
    end

    -- draw sprite with scale factor and offsets
    love.graphics.draw(self.texture, self.currentFrame,
        math.floor(self.x + self.xOffset), math.floor(self.y + self.yOffset),
        0, scaleX, 1, self.xOffset, self.yOffset)
end