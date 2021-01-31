--[[
    tsula, ghost of the desert
    a modest platforming demo
    author: Matteo Potenza
    acknowledgment: Colton Ogden @ harvard university for some of the building blocks in this project taken from his mario project on cs50 games
]]

Class = require 'class'

require 'Animation'
require 'Map'
require 'MapInfo'
require 'Player'
require 'Feather'
require 'HUD'
require 'TextBox'
require 'Spirit'
require 'Sprites'

-- instantiate map
map = Map()

-- performs initialization of all objects and data needed by program
function love.load()

    background = love.graphics.newImage('graphics/tsula_background.png')
    logo = love.graphics.newImage('graphics/tsula_logo.png')

    --get screen dimensions
    love.window.setMode(1920, 1080, {fullscreen = false})
    screen_w = love.graphics.getWidth()
    screen_h = love.graphics.getHeight()

    -- tables for keys pressed and released in play
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    gameState = TITLE       -- init game state
    halt = true             -- suspend player input during textboxes
    timer = 0               -- timer for title sequence
    gameState = START       -- FIMXE: remove
end

-- global key pressed function
function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

-- global key released function
function love.keyboard.wasReleased(key)
    if (love.keyboard.keysReleased[key]) then
        return true
    else
        return false
    end
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
    love.keyboard.keysPressed[key] = true
end

-- called whenever a key is released
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

-- global keyboard input function (cleans up branching conditions)
function active(key)
    if love.keyboard.isDown(key) or love.keyboard.wasPressed(key) then
        return true
    end
    return false
end

-- called every frame, with dt passed in as delta in time since last frame
function love.update(dt)
    map:update(dt)
    timer = timer + 1       -- increment timer for title sequence

    -- initialize a new map and reset game state if user pressed enter at end
    if gameState == LOST and love.keyboard.isDown('return') then
        gameState = START
        map:init()
        timer = 0
    end

    -- reset all keys pressed and released this frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- called each frame, used to render to the screen
function love.draw()
    love.graphics.clear(0/255, 0/255, 0/255, 0/255)
    -- title sequence (6 text entries)
    if gameState == TITLE then
        love.graphics.draw(logo, screen_w / 2, screen_h / 2)
        love.graphics.printf(text[math.ceil(timer / 400)], titleFont,
            screen_w / 4, screen_h / 3, 600, 'center')
        if timer > 2400 then
            gameState = START
        end

    elseif gameState == LOST then
        love.graphics.clear(0/255, 0/255, 0/255, 0/255)
        love.graphics.draw(logo, screen_w / 2, screen_h / 2)
        love.graphics.printf(text[LOST], titleFont,
            screen_w / 4, screen_h / 3, 600, 'center')

    elseif gameState == END then
        love.graphics.draw(logo, screen_w / 3, screen_h / 2)
        love.graphics.printf(text[END], titleFont, 
            screen_w / 4, screen_h / 3, 180, 'center')
        love.graphics.printf(text[CREDIT1], subFont, 
            screen_w * .5, screen_h / 2, 500, 'center')
        love.graphics.printf(text[CREDIT2], subFont, 
            screen_w * .6, screen_h / 2 + 100, 500, 'center')

    -- start game
    else
        love.graphics.translate(
            math.floor(-map.camX + 0.5), math.floor(-map.camY + 0.5))
        love.graphics.draw(background)
        map:render()
    end
end

--[[
to run in terminal:
& "C:\Program Files\LOVE\love.exe" "C:\Users\thatw\LoveGames\tsula"

to distribute: (as admin)
-- move zip to love folder and rename
cmd /c copy /b love.exe+tsula.love tsula.exe
]]