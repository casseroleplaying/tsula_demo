--[[
    the map is created as follows:
    map.png is a 97x97 pixel image (a buffer of one pixel extra is needed on the
    right and bottom to prevent a nil return from getPixel() calls) containing
    the layout of the game's map.
    6 colors (defined below) are used which reference various tiles and objects.
    the map constructor checks the r, g, b values of the pixel from map.png,
    considers only the r value and matches it against the globals defined below.
    a tile/object is placed/instantiated accordingly. 
]]

MAP_W = 96
MAP_H = 96
TILE_W = 40
TILE_H = 40
local rowSize = 4   -- row size of sprite sheet

-- global values reference indeces in the map.sprites table

TILE_EMPTY = -1         -- empty (non-collidable)
EMPTY_COLLIDES = 16     -- empty collidable

--[[
-- plants
AGAVE_BLUE = 2
BRUSH = 3
TREE = 4
AGAVE = 5
BRUSH_DRY = 6
OCTOTILLO = 7
CACTUS = 8

-- feathers
ITEM1 = 9
ITEM2 = 10
ITEM3 = 11
ITEM4 = 12

-- dirt / sand tiles
DIRT_NW = 17
DIRT_N = 18
DIRT_NE = 19
DIRT_W = 25
DIRT = 26
DIRT_E = 27
DIRT_SW = 33
DIRT_S = 34
DIRT_SE = 35

-- spikes
SPIKE_N = 49
SPIKE_S = 42
SPIKE_E = 43
SPIKE_W = 44
]]

AGAVE_BLUE = 2
BRUSH = 3
TREE = 4
AGAVE = 5
BRUSH_DRY = 6
OCTOTILLO = 7
CACTUS = 8

-- feathers
ITEM1 = 9
ITEM2 = 10
ITEM3 = 11
ITEM4 = 12

-- dirt / sand tiles
DIRT_NW = 17
DIRT_N = 18
DIRT_NE = 19
DIRT_W = 21
DIRT = 22
DIRT_E = 23
DIRT_SW = 25
DIRT_S = 26
DIRT_SE = 27

-- spikes
SPIKE_NW = 29
SPIKE_N = 30
SPIKE_NE = 31
SPIKE_W = 33
SPIKE_E = 35
SPIKE_SW = 37
SPIKE_S = 38 
SPIKE_SE = 39

-- tile r(gb) values (for creation from map.png)
FOX_R = 28/255      --1cbbb4
ITEM_R = 1          --ffffff
SPIRIT_R = 133/255  --8560a8
PLANT_R = 87/255    --57a470
DIRT_R = 225/255    --e1a16b
SPIKE_R = 200/255   --c80000