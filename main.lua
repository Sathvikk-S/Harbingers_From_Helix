-- main.lua

-- Declare variables and tables
local player
local playerSpeed = 200
local gravity = 800  -- Increased gravity for faster falling
local jumpHeight = -400  -- Adjust jump height
local isJumping = false
local groundY
local background
local groundImage
local playerImage
local coinImage
local plantImage
local spaceshipImage  -- Declare variable for spaceship image
local cameraX = 0 -- Camera position
local coins = {}  -- Table to hold coins
local coinCount = 0  -- Track the number of coins collected
local plant = nil  -- Table to hold plant data
local spaceship = nil  -- Table to hold spaceship data

-- New variables for plant collection and planting
local plantCount = 0  -- Track the number of plants collected
local plantedTrees = {}  -- Table to hold planted trees

-- Floating offset for planted trees
local plantFloatOffset = 50  -- Pixels above the ground

-- Optional: Load sounds
-- local collectSound
-- local plantSound
-- local plantPlaceSound  -- New sound for planting a tree

function love.load()
    -- Load images
    background = love.graphics.newImage("background.png")
    groundImage = love.graphics.newImage("ground.png")
    playerImage = love.graphics.newImage("player.png")
    coinImage = love.graphics.newImage("coin.png")  -- Load the coin image
    plantImage = love.graphics.newImage("plant.png")  -- Load the plant image
    spaceshipImage = love.graphics.newImage("spaceship.png")  -- Load the spaceship image
    treeImage = love.graphics.newImage("tree.png")
    -- Optional: Load sounds
    -- collectSound = love.audio.newSource("collect.wav", "static")
    -- plantSound = love.audio.newSource("plant_collect.wav", "static")
    -- plantPlaceSound = love.audio.newSource("plant_place.wav", "static")  -- New sound

    -- Initialize player properties
    player = {
        x = 100,
        y = 400,
        width = playerImage:getWidth(),
        height = playerImage:getHeight(),
        velocityY = 0,  -- Vertical velocity for jumping
        facingRight = true  -- Track which direction the player is facing
    }

    -- Calculate groundY based on ground image height
    groundY = love.graphics.getHeight() - groundImage:getHeight()

    -- Create coins at specific positions on the ground
    local numberOfCoins = 10  -- Total coins to spawn
    for i = 1, numberOfCoins do
        local coin = {
            x = math.random(50, background:getWidth() - 50),  -- Random x position within the background width
            y = groundY - coinImage:getHeight(),  -- Position the coin on the ground
            width = coinImage:getWidth(),
            height = coinImage:getHeight(),
            collected = false  -- Track if the coin is collected
        }
        table.insert(coins, coin)  -- Add coin to the coins table
    end

    -- Spawn spaceship on the ground near the player's spawn point
    spaceship = {
        x = 20,  -- Position the spaceship horizontally
        y = groundY - spaceshipImage:getHeight(),  -- Position it on the ground
        width = spaceshipImage:getWidth(),
        height = spaceshipImage:getHeight(),
    }
end

function love.update(dt)
    -- Horizontal movement
    if love.keyboard.isDown("right") then
        player.x = player.x + playerSpeed * dt
        player.facingRight = true  -- Player is facing right
    elseif love.keyboard.isDown("left") then
        player.x = player.x - playerSpeed * dt
        player.facingRight = false  -- Player is facing left
    end

    -- Jumping logic
    if love.keyboard.isDown("space") and not isJumping then
        player.velocityY = jumpHeight
        isJumping = true
    end

    -- Apply gravity
    if isJumping then
        player.velocityY = player.velocityY + gravity * dt  -- Apply gravity to the vertical velocity
        player.y = player.y + player.velocityY * dt  -- Update player Y position based on velocity
    end

    -- Check if player is on the ground
    if player.y >= groundY - player.height then
        player.y = groundY - player.height  -- Set player Y to ground level
        player.velocityY = 0  -- Reset vertical velocity
        isJumping = false  -- Allow jumping again
    end

    -- Update camera position to follow player
    cameraX = player.x - love.graphics.getWidth() / 2 + player.width / 2

    -- Optional: Limit camera movement
    cameraX = math.max(0, cameraX) -- Prevent camera from moving left beyond (0, 0)
    cameraX = math.min(cameraX, background:getWidth() - love.graphics.getWidth()) -- Prevent camera from moving right beyond background width

    -- Check for coin collection
    for _, coin in ipairs(coins) do
        if not coin.collected and checkCollision(player, coin) then
            coin.collected = true  -- Mark coin as collected
            coinCount = coinCount + 1  -- Increase coin count
            -- Optional: Play collect sound
            -- love.audio.play(collectSound)
            print("Coin collected! Total coins:", coinCount)

            -- Check if coinCount reached 5 and plant hasn't been spawned yet
            if coinCount%5 == 0 and not plant then
                spawnPlant()
                -- Optional: Reset coin count to allow multiple plant spawns
                
            end
        end
    end

    -- Check for plant collection
    if plant and checkCollision(player, plant) then
        plantCount = plantCount + 1  -- Increment the plant count
        -- Remove the collected plant
        plant = nil
        -- Optional: Play plant collect sound
        -- love.audio.play(plantSound)
        -- Optional: Provide additional rewards or feedback
        print("Plant collected! Total plants:", plantCount)
    end

    -- Animate planted trees to float
    for _, tree in ipairs(plantedTrees) do
        local floatSpeed = 50  -- Speed of floating
        local floatAmplitude = 10  -- How much the tree floats up and down

        tree.offset = tree.offset + tree.direction * floatSpeed * dt

        if tree.offset > floatAmplitude then
            tree.offset = floatAmplitude
            tree.direction = -1
        elseif tree.offset < -floatAmplitude then
            tree.offset = -floatAmplitude
            tree.direction = 1
        end

        tree.y = tree.baseY + tree.offset
    end
end

function love.draw()
    -- Draw repeating background
    local backgroundWidth = background:getWidth()
    local screenWidth = love.graphics.getWidth()

    -- Draw the background multiple times
    for i = 0, math.ceil(screenWidth / backgroundWidth) do
        love.graphics.draw(background, i * backgroundWidth - cameraX, 0)
    end

    -- Draw repeating ground
    local groundWidth = groundImage:getWidth()
    -- Calculate how many ground tiles are needed to cover the screen, plus one extra to avoid gaps
    local numGroundTiles = math.ceil(love.graphics.getWidth() / groundWidth) + 1

    for i = 0, numGroundTiles - 1 do
        love.graphics.draw(groundImage, i * groundWidth - (cameraX % groundWidth), groundY)
    end

    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then  -- Only draw coins that haven't been collected
            love.graphics.draw(coinImage, coin.x - cameraX, coin.y)
        end
    end

    -- Draw plant if it exists
    if plant then
        love.graphics.draw(plantImage, plant.x - cameraX, plant.y)
    end

    -- Draw spaceship on the ground
    if spaceship then
        love.graphics.draw(spaceshipImage, spaceship.x - cameraX, spaceship.y)
    end

    -- Draw planted trees
    for _, tree in ipairs(plantedTrees) do
        love.graphics.draw(treeImage, tree.x - cameraX, tree.y)
    end

    -- Draw player with camera offset
    if player.facingRight then
        love.graphics.draw(playerImage, player.x - cameraX, player.y)
    else
        love.graphics.draw(playerImage, player.x - cameraX, player.y, 0, -1, 1) -- Flip the player sprite
    end

    -- Display the coin count
    love.graphics.setColor(1, 1, 1) -- Set color to white
    love.graphics.print("Garbage Collected: " .. coinCount, 10, 10)  -- Display coin count at the top left

    -- Display the plant count
    love.graphics.print("Plants: " .. plantCount, 10, 30)  -- Display plant count below coin count

    -- Display the number of planted trees
    love.graphics.print("Planted Trees: " .. #plantedTrees, 10, 50)  -- Display planted trees count below plants
end

function love.keypressed(key)
    -- Plant a tree when the player presses 'p'
    if key == "p" then
        if plantCount > 0 then
            plantTree()
        else
            print("No plants available to plant!")
        end
    end
end

function love.keyreleased(key)
    -- Reset jumping when the space key is released
    if key == "space" then
        -- isJumping remains false; handled in the update logic
    end
end

-- Function to check for collision between two rectangles
function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

-- Function to spawn the plant on the ground as a reward
function spawnPlant()
    print("Spawning plant as a reward!")

    -- Choose a position ahead of the player within the background bounds
    local plantX = player.x + 200  -- Plant appears 200 pixels ahead of the player
    if plantX > background:getWidth() - 50 then
        plantX = background:getWidth() - 50  -- Ensure plant doesn't spawn beyond background
    end

    plant = {
        x = plantX,
        y = groundY - plantImage:getHeight(),  -- Position plant on the ground
        width = plantImage:getWidth(),
        height = plantImage:getHeight(),
        collected = false  -- This field is now redundant and can be removed
    }

    -- Optional: Reset coin count to allow multiple plant spawns
    -- coinCount = 0
end

-- Function to plant a tree at the player's current position
function plantTree()
    -- Calculate the planting position
    local treeX = player.x
    local baseY = groundY - plantImage:getHeight() - plantFloatOffset  -- Base Y for floating

    -- Add the tree to the plantedTrees table with animation properties
    table.insert(plantedTrees, {
        x = treeX,
        baseY = baseY,  -- Base Y position
        y = baseY,       -- Current Y position
        width = plantImage:getWidth(),
        height = plantImage:getHeight(),
        offset = 0,      -- Current offset for animation
        direction = 1    -- Direction of movement (1 for up, -1 for down)
    })

    -- Decrement the plant count as one plant has been used
    plantCount = plantCount - 1

    -- Optional: Play plant placement sound
    -- love.audio.play(plantPlaceSound)

    print("Tree planted! Total planted trees:", #plantedTrees)
end
