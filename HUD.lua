--[[
    Simple HUD of four feathers in top right corner, spirit bar top left
]]

HUD = Class{}

function HUD:init(map)
    self.map = map
    self.texture = love.graphics.newImage('graphics/tsula_environment.png')
    self.frame = love.graphics.newQuad(0, 120, 160, 40, 160, 400)
    hudFont = love.graphics.newFont('fonts/LithosPro-Bold.otf', 14)
end

function HUD:render()
    -- feathers
    love.graphics.draw(self.texture, self.frame,
        math.floor(map.camX + screen_w - 200), math.floor(map.camY + 40))
    love.graphics.printf('feathers recovered', hudFont,
        math.floor(map.camX + screen_w - 200), math.floor(map.camY + 90), 160, 'center')

    -- spirit bar
    love.graphics.setColor(124/255, 47/255, 186/255)
    love.graphics.rectangle(
        'fill', map.camX + 60, map.camY + 40, 320, 40, 10, 10)

    love.graphics.setColor(28/255, 187/255, 180/255)
    if map.player.hp > 0.5 then
        love.graphics.rectangle('fill', map.camX + 64, map.camY + 44,
            map.player.hp * 3.12, 32, 8, 8)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf('spirit remaining', hudFont,
        map.camX + 145, map.camY + 90, 160, 'center')
end
