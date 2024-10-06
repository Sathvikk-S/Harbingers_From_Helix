local player
local playerSpeed = 200
local gravity = 800
local jumpHeight = -400
local isJumping = false
local groundY
local background
local groundImage
local playerImage
local coinImage
local plantImage
local spaceshipImage
local rockImage
local cameraX = 0
local coins = {}
local coinCount = 0
local plant = nil
local spaceship = nil
local plantCount = 0
local plantedTrees = {}
local plantFloatOffset = 50
local rocks = {}

-- Welcome screen variables
local welcomeScreen = true
local loadingProgress = 0
local loading = false
local welcomeBackground  -- Background image for the welcome screen

function love.load()
    -- Load images with error handling
    background = love.graphics.newImage("background.png")
    groundImage = love.graphics.newImage("ground.png")
    playerImage = love.graphics.newImage("player.png")
    coinImage = love.graphics.newImage("coin.png")
    plantImage = love.graphics.newImage("plant.png")
    spaceshipImage = love.graphics.newImage("spaceship.png")
    treeImage = love.graphics.newImage("tree.png")
    rockImage = love.graphics.newImage("rock.png")

    -- Load welcome background image
    welcomeBackground = love.graphics.newImage("welcome_background.jpg")  -- Replace with your actual image path

    -- Initialize player properties
    initializePlayer()
    initializeLevel()
end

function initializePlayer()
    player = {
        x = 100,
        y = 400,
        width = playerImage:getWidth(),
        height = playerImage:getHeight(),
        velocityY = 0,
        facingRight = true
    }
end

function initializeLevel()
    groundY = love.graphics.getHeight() - groundImage:getHeight()

    -- Create rocks at random positions first
    local numberOfRocks = 5
    for i = 1, numberOfRocks do
        local rock = spawnObject("rock", rocks, {x = 200, y = groundY - rockImage:getHeight(), width = rockImage:getWidth(), height = rockImage:getHeight()}, background:getWidth() - 100, groundY - rockImage:getHeight())
        if rock then
            table.insert(rocks, rock)
        end
    end

    -- Create coins at specific positions on the ground
    local numberOfCoins = 10
    for i = 1, numberOfCoins do
        local coin = spawnObject("coin", coins, {x = math.random(50, background:getWidth() - 50), y = groundY - coinImage:getHeight(), width = coinImage:getWidth(), height = coinImage:getHeight()}, background:getWidth() - 50, groundY - coinImage:getHeight(), {"rock", "coin"})
        if coin then
            table.insert(coins, coin)
        end
    end

    -- Spawn spaceship on the ground
    spaceship = {
        x = 20,
        y = groundY - spaceshipImage:getHeight(),
        width = spaceshipImage:getWidth(),
        height = spaceshipImage:getHeight(),
    }
end

-- Helper function to check overlap with multiple object types
function isOverlapping(obj, objectList)
    for _, other in ipairs(objectList) do
        if checkCollision(obj, other) then
            return true
        end
    end
    return false
end

-- General-purpose spawn function to avoid overlaps
function spawnObject(type, list, obj, maxX, groundY, avoidTypes)
    local maxAttempts = 100
    local attempt = 0
    while attempt < maxAttempts do
        attempt = attempt + 1
        obj.x = math.random(50, maxX)
        obj.y = groundY

        local overlapping = false

        if type == "rock" then
            -- Check against coins and existing rocks
            if isOverlapping(obj, coins) or isOverlapping(obj, list) then
                overlapping = true
            end
        elseif type == "coin" then
            -- Check against rocks and existing coins
            if isOverlapping(obj, rocks) or isOverlapping(obj, list) then
                overlapping = true
            end
        end

        if not overlapping then
            return obj
        end
    end
    print("Failed to spawn a non-overlapping " .. type)
    return nil
end

function love.update(dt)
    if welcomeScreen then
        if loading then
            loadingProgress = loadingProgress + dt
            if loadingProgress >= 1 then
                loadingProgress = 1
                welcomeScreen = false  -- End loading
            end
        end
    else
        -- Horizontal movement
        if love.keyboard.isDown("right") then
            player.x = player.x + playerSpeed * dt
            player.facingRight = true
        elseif love.keyboard.isDown("left") then
            player.x = player.x - playerSpeed * dt
            player.facingRight = false
        end

        -- Jumping logic
        if love.keyboard.isDown("space") and not isJumping then
            player.velocityY = jumpHeight
            isJumping = true
        end

        -- Apply gravity
        if isJumping then
            player.velocityY = player.velocityY + gravity * dt
            player.y = player.y + player.velocityY * dt
        end

        -- Check if player is on the ground
        if player.y >= groundY - player.height then
            player.y = groundY - player.height
            player.velocityY = 0
            isJumping = false
        end

        -- Update camera position to follow player
        cameraX = player.x - love.graphics.getWidth() / 2 + player.width / 2
        cameraX = math.max(0, cameraX)
        cameraX = math.min(cameraX, background:getWidth() - love.graphics.getWidth())

        -- Check for coin collection
        for _, coin in ipairs(coins) do
            if not coin.collected and checkCollision(player, coin) then
                coin.collected = true
                coinCount = coinCount + 1
                print("Coin collected! Total coins:", coinCount)

                -- Check if coinCount reached multiples of 5 and plant hasn't been spawned yet
                if coinCount % 5 == 0 and not plant then
                    spawnPlant()
                end
            end
        end

        -- Check for plant collection
        if plant and checkCollision(player, plant) then
            plantCount = plantCount + 1
            plant = nil
            print("Plant collected! Total plants:", plantCount)
        end

        -- Animate planted trees to float
        for _, tree in ipairs(plantedTrees) do
            local floatSpeed = 50
            local floatAmplitude = 10

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

        -- Check for collision with rocks and respawn if collision happens
        for _, rock in ipairs(rocks) do
            if checkCollision(player, rock) then
                print("Hit a rock! Respawning player and rocks...")
                initializePlayer()
                respawnRocks()
                break
            end
        end
    end
end

function respawnRocks()
    rocks = {}  -- Clear existing rocks

    local numberOfRocks = 5
    for i = 1, numberOfRocks do
        local rock = spawnObject("rock", rocks, {x = 0, y = groundY - rockImage:getHeight(), width = rockImage:getWidth(), height = rockImage:getHeight()}, background:getWidth() - 100, groundY - rockImage:getHeight())
        if rock then
            table.insert(rocks, rock)
        end
    end
end

function love.draw()
    if welcomeScreen then
        -- Draw welcome background image
        love.graphics.draw(welcomeBackground, 0, 0)

        -- Draw welcome text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Welcome to the Game!", 0, love.graphics.getHeight() / 4, love.graphics.getWidth(), "center")
        love.graphics.printf("Loading...", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        
        -- Draw loading bar
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() * 3 / 4, love.graphics.getWidth() / 2, 30)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() * 3 / 4, (love.graphics.getWidth() / 2) * loadingProgress, 30)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press Enter to Start New Game", 0, love.graphics.getHeight() * 3 / 4 + 50, love.graphics.getWidth(), "center")
    else
        -- Draw Level 1 content
        drawLevel()
    end
end

function drawLevel()
    -- Draw repeating background
    local backgroundWidth = background:getWidth()
    local screenWidth = love.graphics.getWidth()

    for i = 0, math.ceil(screenWidth / backgroundWidth) do
        love.graphics.draw(background, i * backgroundWidth - cameraX, 0)
    end

    -- Draw repeating ground
    local groundWidth = groundImage:getWidth()
    local numGroundTiles = math.ceil(love.graphics.getWidth() / groundWidth) + 1

    for i = 0, numGroundTiles - 1 do
        love.graphics.draw(groundImage, i * groundWidth - (cameraX % groundWidth), groundY)
    end

    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then
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

    -- Draw rocks
    for _, rock in ipairs(rocks) do
        love.graphics.draw(rockImage, rock.x - cameraX, rock.y)
    end

    -- Draw player with camera offset
    if player.facingRight then
        love.graphics.draw(playerImage, player.x - cameraX, player.y)
    else
        love.graphics.draw(playerImage, player.x - cameraX, player.y, 0, -1, 1)
    end

    -- Display the coin count
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Garbage Collected: " .. coinCount, 10, 10)

    -- Display the plant count
    love.graphics.print("Plants: " .. plantCount, 10, 30)

    -- Display the number of planted trees
    love.graphics.print("Planted Trees: " .. #plantedTrees, 10, 50)
end

function love.keypressed(key)
    if welcomeScreen then
        if key == "return" then
            loading = true  -- Start loading when Enter is pressed
        end
    else
        if key == "p" then
            if plantCount > 0 then
                plantTree()
            else
                print("No plants available to plant!")
            end
        end
    end
end

-- Function to check for collision between two rectangles
function checkCollision(a, b)
    local buffer = 10  -- Adjust this value to shrink the collision radius (increase for a smaller detection area)
    return a.x + buffer < b.x + b.width - buffer and
           a.x + a.width - buffer > b.x + buffer and
           a.y + buffer < b.y + b.height - buffer and
           a.y + a.height - buffer > b.y + buffer
end

-- Function to spawn the plant on the ground as a reward
function spawnPlant()
    print("Spawning plant as a reward!")

    local maxX = background:getWidth() - plantImage:getWidth() - 50
    local plantX = player.x + 200
    if plantX > maxX then
        plantX = maxX
    end

    local newPlant = {
        x = plantX,
        y = groundY - plantImage:getHeight(),
        width = plantImage:getWidth(),
        height = plantImage:getHeight()
    }

    -- Ensure the plant does not overlap with rocks or coins
    if not isOverlapping(newPlant, rocks) and not isOverlapping(newPlant, coins) then
        plant = newPlant
    else
        -- Find a non-overlapping position
        local maxAttempts = 100
        local attempt = 0
        local placed = false
        while attempt < maxAttempts and not placed do
            attempt = attempt + 1
            newPlant.x = math.random(50, maxX)
            if not isOverlapping(newPlant, rocks) and not isOverlapping(newPlant, coins) and not (plant and checkCollision(newPlant, plant)) then
                plant = newPlant
                placed = true
            end
        end

        if not placed then
            print("Failed to spawn a non-overlapping plant.")
            plant = nil
        end
    end
end

-- Function to plant a tree at the player's current position
function plantTree()
    local treeX = player.x
    local baseY = groundY - plantImage:getHeight() - plantFloatOffset

    local newTree = {
        x = treeX,
        baseY = baseY,
        y = baseY,
        width = plantImage:getWidth(),
        height = plantImage:getHeight(),
        offset = 0,
        direction = 1
    }

    -- Ensure the tree does not overlap with rocks or existing trees
    if not isOverlapping(newTree, rocks) and not isOverlapping(newTree, plantedTrees) then
        table.insert(plantedTrees, newTree)
        plantCount = plantCount - 1
        print("Tree planted! Total planted trees:", #plantedTrees)
    else
        -- Find a non-overlapping position
        local maxAttempts = 100
        local attempt = 0
        local placed = false
        while attempt < maxAttempts and not placed do
            attempt = attempt + 1
            newTree.x = math.random(50, background:getWidth() - 50)
            if not isOverlapping(newTree, rocks) and not isOverlapping(newTree, plantedTrees) then
                newTree.baseY = groundY - plantImage:getHeight() - plantFloatOffset
                newTree.y = newTree.baseY
                table.insert(plantedTrees, newTree)
                plantCount = plantCount - 1
                print("Tree planted! Total planted trees:", #plantedTrees)
                placed = true
            end
        end

        if not placed then
            print("Failed to plant a non-overlapping tree.")
        end
    end
end
