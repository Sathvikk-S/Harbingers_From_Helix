-- **Game Variables**
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
local treeImage
local cameraX = 0

local coins = {}
local coinCount = 0
local plant = nil
local spaceship = nil
local plantCount = 0
local plantedTrees = {}
local plantFloatOffset = 50
local rocks = {}

-- **Game State Variables**
local welcomeScreen = true
local loadingProgress = 0
local loading = false
local welcomeBackground  -- Background image for the welcome screen

local showPlantPrompt = false
local promptText = "Press P to plant a tree"
local promptFont
local promptColor = {1, 1, 1, 1}  -- White color with full opacity

local gameOver = false  -- New Game Over State
local maxPlantedTrees = 2  -- Number of trees to plant before game over

-- **Love2D Load Function**
function love.load()
    -- **Load Images**
    background = love.graphics.newImage("background.png")
    groundImage = love.graphics.newImage("ground.png")
    playerImage = love.graphics.newImage("player.png")
    coinImage = love.graphics.newImage("coin.png")
    plantImage = love.graphics.newImage("plant.png")
    spaceshipImage = love.graphics.newImage("spaceship.png")
    treeImage = love.graphics.newImage("tree.png")
    rockImage = love.graphics.newImage("rock.png")

    -- **Load Welcome Background Image**
    welcomeBackground = love.graphics.newImage("welcome_background.jpg")  -- Ensure this path is correct

    -- **Set Prompt Font (Optional)**
    promptFont = love.graphics.newFont(14)
    love.graphics.setFont(promptFont)

    -- **Initialize Player and Level**
    initializePlayer()
    initializeLevel()
end

-- **Initialize Player Function**
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

-- **Initialize Level Function**
function initializeLevel()
    groundY = love.graphics.getHeight() - groundImage:getHeight()

    -- **Spawn Rocks First to Avoid Overlaps with Coins**
    local numberOfRocks = 5
    for i = 1, numberOfRocks do
        local rock = spawnObject("rock")
        if rock then
            table.insert(rocks, rock)
        end
    end

    -- **Spawn Coins After Rocks to Avoid Overlaps**
    local numberOfCoins = 10
    for i = 1, numberOfCoins do
        local coin = spawnObject("coin")
        if coin then
            table.insert(coins, coin)
        end
    end

    -- **Spawn Spaceship on the Ground**
    spaceship = {
        x = 20,
        y = groundY - spaceshipImage:getHeight(),
        width = spaceshipImage:getWidth(),
        height = spaceshipImage:getHeight(),
    }
end

-- **Helper Function: Check Collision Between Two Objects**
function checkCollision(a, b)
    local buffer = 10  -- Adjust buffer as needed
    return a.x + buffer < b.x + b.width - buffer and
           a.x + a.width - buffer > b.x + buffer and
           a.y + buffer < b.y + b.height - buffer and
           a.y + a.height - buffer > b.y + buffer
end

-- **Helper Function: Check Overlapping with a List of Objects**
function isOverlapping(obj, objectList)
    for _, other in ipairs(objectList) do
        if checkCollision(obj, other) then
            return true
        end
    end
    return false
end

-- **Helper Function: Spawn Objects Without Overlapping**
function spawnObject(type)
    local maxAttempts = 100
    local attempt = 0
    local obj = {}
    while attempt < maxAttempts do
        attempt = attempt + 1
        if type == "rock" then
            obj = {
                x = math.random(200, background:getWidth() - 100),
                y = groundY - rockImage:getHeight(),
                width = rockImage:getWidth(),
                height = rockImage:getHeight()
            }
            if not isOverlapping(obj, rocks) and not isOverlapping(obj, coins) and not isOverlapping(obj, plantedTrees) then
                return obj
            end
        elseif type == "coin" then
            obj = {
                x = math.random(50, background:getWidth() - 50),
                y = groundY - coinImage:getHeight(),
                width = coinImage:getWidth(),
                height = coinImage:getHeight(),
                collected = false
            }
            if not isOverlapping(obj, rocks) and not isOverlapping(obj, coins) then
                return obj
            end
        end
    end
    print("Failed to spawn a non-overlapping " .. type)
    return nil
end

-- **Love2D Update Function**
function love.update(dt)
    if welcomeScreen then
        if loading then
            loadingProgress = loadingProgress + dt
            if loadingProgress >= 1 then
                loadingProgress = 1
                welcomeScreen = false  -- End loading
            end
        end
    elseif gameOver then
        -- **Game Over State: No Updates Needed**
        -- You can add animations or other effects here if desired
    else
        -- **Player Movement**
        if love.keyboard.isDown("right") then
            player.x = player.x + playerSpeed * dt
            player.facingRight = true
        elseif love.keyboard.isDown("left") then
            player.x = player.x - playerSpeed * dt
            player.facingRight = false
        end

        -- **Player Jumping Logic**
        if love.keyboard.isDown("space") and not isJumping then
            player.velocityY = jumpHeight
            isJumping = true
        end

        -- **Apply Gravity**
        if isJumping then
            player.velocityY = player.velocityY + gravity * dt
            player.y = player.y + player.velocityY * dt
        end

        -- **Check if Player is on the Ground**
        if player.y >= groundY - player.height then
            player.y = groundY - player.height
            player.velocityY = 0
            isJumping = false
        end

        -- **Update Camera Position to Follow Player**
        cameraX = player.x - love.graphics.getWidth() / 2 + player.width / 2
        cameraX = math.max(0, cameraX)
        cameraX = math.min(cameraX, background:getWidth() - love.graphics.getWidth())

        -- **Check for Coin Collection**
        for _, coin in ipairs(coins) do
            if not coin.collected and checkCollision(player, coin) then
                coin.collected = true
                coinCount = coinCount + 1
                print("Coin collected! Total coins:", coinCount)

                -- **Check if Coin Count Reached Multiples of 5 and Plant is Not Spawned Yet**
                if coinCount % 5 == 0 and not plant then
                    spawnPlant()
                end
            end
        end

        -- **Check for Plant Collection**
        if plant and checkCollision(player, plant) then
            plantCount = plantCount + 1
            plant = nil
            showPlantPrompt = true  -- Show prompt when plant is collected
            print("Plant collected! Total plants:", plantCount)
        end

        -- **Animate Planted Trees to Float**
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

        -- **Check for Collision with Rocks and Respawn if Collision Happens**
        for _, rock in ipairs(rocks) do
            if checkCollision(player, rock) then
                print("Hit a rock! Respawning player and rocks...")
                initializePlayer()
                respawnRocks()
                break  -- Exit the loop after respawning
            end
        end
    end
end

-- **Respawn Rocks Function**
function respawnRocks()
    rocks = {}  -- Clear existing rocks

    local numberOfRocks = 5
    for i = 1, numberOfRocks do
        local rock = spawnObject("rock")
        if rock then
            table.insert(rocks, rock)
        end
    end
end

-- **Love2D Draw Function**
function love.draw()
    if welcomeScreen then
        -- **Draw Welcome Background Image**
        love.graphics.draw(welcomeBackground, 0, 0)

        -- **Draw Welcome Text**
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Welcome to the Game!", 0, love.graphics.getHeight() / 4, love.graphics.getWidth(), "center")
        love.graphics.printf("Loading...", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")

        -- **Draw Loading Bar**
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() * 3 / 4, love.graphics.getWidth() / 2, 30)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() * 3 / 4, (love.graphics.getWidth() / 2) * loadingProgress, 30)

        -- **Draw Start Game Prompt**
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press Enter to Start New Game", 0, love.graphics.getHeight() * 3 / 4 + 50, love.graphics.getWidth(), "center")
    elseif gameOver then
        -- **Draw Game Over Screen**
        love.graphics.setColor(0, 0, 0, 0.7)  -- Semi-transparent black background
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setColor(1, 0, 0)  -- Red color for "GAME OVER" text
        local gameOverText = "GAME OVER"
        local font = love.graphics.newFont(48)
        love.graphics.setFont(font)
        love.graphics.printf(gameOverText, 0, love.graphics.getHeight() / 2 - 24, love.graphics.getWidth(), "center")

        -- **Optional: Restart Prompt**
        love.graphics.setColor(1, 1, 1)  -- White color for prompt
        local prompt = "Press R to Restart or Q to Quit"
        local smallFont = love.graphics.newFont(24)
        love.graphics.setFont(smallFont)
        love.graphics.printf(prompt, 0, love.graphics.getHeight() / 2 + 40, love.graphics.getWidth(), "center")
    else
        -- **Draw Game Level**
        drawLevel()
    end
end

-- **Draw Level Function**
function drawLevel()
    -- **Draw Repeating Background**
    local backgroundWidth = background:getWidth()
    local screenWidth = love.graphics.getWidth()

    for i = 0, math.ceil(screenWidth / backgroundWidth) do
        love.graphics.draw(background, i * backgroundWidth - cameraX, 0)
    end

    -- **Draw Repeating Ground**
    local groundWidth = groundImage:getWidth()
    local numGroundTiles = math.ceil(love.graphics.getWidth() / groundWidth) + 1

    for i = 0, numGroundTiles - 1 do
        love.graphics.draw(groundImage, i * groundWidth - (cameraX % groundWidth), groundY)
    end

    -- **Draw Coins**
    for _, coin in ipairs(coins) do
        if not coin.collected then
            love.graphics.draw(coinImage, coin.x - cameraX, coin.y)
        end
    end

    -- **Draw Plant if Exists**
    if plant then
        love.graphics.draw(plantImage, plant.x - cameraX, plant.y)
    end

    -- **Draw Spaceship on the Ground**
    if spaceship then
        love.graphics.draw(spaceshipImage, spaceship.x - cameraX, spaceship.y)
    end

    -- **Draw Planted Trees**
    for _, tree in ipairs(plantedTrees) do
        love.graphics.draw(treeImage, tree.x - cameraX, tree.y)
    end

    -- **Draw Rocks**
    for _, rock in ipairs(rocks) do
        love.graphics.draw(rockImage, rock.x - cameraX, rock.y)
    end

    -- **Draw Player with Camera Offset**
    if player.facingRight then
        love.graphics.draw(playerImage, player.x - cameraX, player.y)
    else
        love.graphics.draw(playerImage, player.x - cameraX, player.y, 0, -1, 1)  -- Flip horizontally
    end

    -- **Set Text Color to White**
    love.graphics.setColor(1, 1, 1)

    -- **Display UI Texts**
    love.graphics.print("Garbage Collected: " .. coinCount, 10, 10)
    love.graphics.print("Plants: " .. plantCount, 10, 30)
    love.graphics.print("Planted Trees: " .. #plantedTrees, 10, 50)

    -- **Display Planting Prompt if Applicable**
    if showPlantPrompt and plantCount > 0 then
        love.graphics.printf(promptText, 0, 70, love.graphics.getWidth(), "right")
    end
end

-- **Love2D Keypressed Function**
function love.keypressed(key)
    if welcomeScreen then
        if key == "return" then
            loading = true  -- Start loading when Enter is pressed
        end
    elseif gameOver then
        if key == "r" then
            restartGame()
        elseif key == "q" then
            love.event.quit()
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

-- **Function to Spawn Plant as a Reward**
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

    -- **Ensure the Plant Does Not Overlap with Rocks or Coins**
    if not isOverlapping(newPlant, rocks) and not isOverlapping(newPlant, coins) then
        plant = newPlant
    else
        -- **Find a Non-Overlapping Position**
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

-- **Function to Plant a Tree**
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

    -- **Ensure the Tree Does Not Overlap with Rocks or Existing Trees**
    if not isOverlapping(newTree, rocks) and not isOverlapping(newTree, plantedTrees) then
        table.insert(plantedTrees, newTree)
        plantCount = plantCount - 1
        print("Tree planted! Total planted trees:", #plantedTrees)

        -- **Check if Maximum Planted Trees Reached**
        if #plantedTrees >= maxPlantedTrees then
            gameOver = true
        end

        showPlantPrompt = false  -- Hide the prompt after planting
    else
        -- **Find a Non-Overlapping Position**
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

                -- **Check if Maximum Planted Trees Reached**
                if #plantedTrees >= maxPlantedTrees then
                    gameOver = true
                end

                placed = true
                showPlantPrompt = false  -- Hide the prompt after planting
            end
        end

        if not placed then
            print("Failed to plant a non-overlapping tree.")
        end
    end
end

-- **Function to Restart the Game**
function restartGame()
    -- **Reset All Game Variables**
    coinCount = 0
    plantCount = 0
    plantedTrees = {}
    coins = {}
    rocks = {}
    plant = nil
    gameOver = false
    showPlantPrompt = false

    -- **Re-initialize Player and Level**
    initializePlayer()
    initializeLevel()

    print("Game Restarted!")
end
