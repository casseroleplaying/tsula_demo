--[[
    Text boxes and game fonts
]]

TextBox = Class{}

-- game state enums (text{} index in Textbox class)
TITLE = 1
START = 7
EARTH_F = 8
WATER_F = 9
WIND_F = 10
FIRE_F = 11
ALL = 12
LOST = 13
END = 14
CREDIT1 = 15
CREDIT2 = 16
PRESS = 17
CONTROLS = 18
CONTROLS2 = 19

function TextBox:init(map)
    text = {
        'tsula, ghost of the desert',
        'long forgotten in a dream',
        'one must recover the four feathers',
        'to be healed and come back again',
        'beware the dark clouds that will consume your spirit',
        'if all is lost, you must tread this land again',
        'toggle controls: press c',
        'earth feather recovered',
        'water feather recovered',
        'wind feather recovered',
        'fire feather recovered',
        'all feathers recovered',
        'all spirit within has been drained',
        'the end',
        'programming, art, design:\nMatteo Potenza',
        'music:\nIan Crossman',
        '[press return]',
        'walk [a,d]\tjump [spc]\tcrawl [s]',
        'dash [a+<, d+>]\tpounce [jump+v]\tburst [jump+^]'
    }
    textBox = love.graphics.newImage('graphics/textBoxSW.png')
    titleFont = love.graphics.newFont('fonts/LithosPro-Regular.otf', 36)
    subFont = love.graphics.newFont('fonts/LithosPro-Regular.otf', 18)
    allFont = love.graphics.newFont('fonts/LithosPro-Bold.otf', 27)
    tbFont = love.graphics.newFont('fonts/LithosPro-Bold.otf', 15)
    keyFont = love.graphics.newFont('fonts/LithosPro-Bold.otf', 12)
end

function TextBox:render()
    -- text boxes for items / game states
    if halt == true then
        love.graphics.draw(textBox, 
            map.camX + screen_w / 3 - 75, map.camY + screen_h / 2)
        love.graphics.printf(text[gameState], tbFont, 
            map.camX + screen_w / 3, map.camY + screen_h / 2 + 65,
            215, 'center')
        love.graphics.printf(text[PRESS], keyFont,
            map.camX + screen_w / 3, map.camY + screen_h / 2 + 95, 
            200, 'center')
        
        if love.keyboard.isDown('return') then
            halt = false
        end
    end
    if gameState == ALL then
        love.graphics.printf(text[gameState],
            allFont, map.camX + screen_w / 3, map.camY + 70, 360, 'center')
    end

    if map.player.showControls == true then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill',  
            map.camX + screen_w / 3, map.camY + screen_h - 120, 600, 90)
            love.graphics.setColor(1, 1, 1)
        love.graphics.printf(text[CONTROLS],
            tbFont, map.camX + screen_w / 3, map.camY + screen_h - 100, 600, 'center')
        love.graphics.printf(text[CONTROLS2],
            tbFont, map.camX + screen_w / 3, map.camY + screen_h - 60, 600, 'center')
    end
end