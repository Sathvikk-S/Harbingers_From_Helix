-- main.lua

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
local cameraX = 0 -- Camera position
local coins = {}  -- Table to hold coins
local coinCount = 0  -- Track the number of coins collected

function love.load()
    -- Load images
    background = love.graphics.newImage("background.png")
    groundImage = love.graphics.newImage("ground.png")
    playerImage = love.graphics.newImage("player.png")
    coinImage = love.graphics.newImage("garbage.png")  -- Load the coin image

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
    local numberOfCoins = 5  -- Number of coins to spawn
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
        end
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

    -- Draw ground
    love.graphics.draw(groundImage, 0, groundY)

    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then  -- Only draw coins that haven't been collected
            love.graphics.draw(coinImage, coin.x - cameraX, coin.y)
        end
    end

    -- Draw player with camera offset
    if player.facingRight then
        love.graphics.draw(playerImage, player.x - cameraX, player.y)
    else
        love.graphics.draw(playerImage, player.x - cameraX, player.y, 0, -1, 1) -- Flip the player sprite
    end

    -- Display the coin count
    love.graphics.setColor(1, 1, 1) -- Set color to white
    love.graphics.print("Garbage collected: " .. coinCount, 10, 10)  -- Display coin count at the top left
end

function love.keyreleased(key)
    -- Reset jumping when the space key is released
    if key == "space" then
        -- isJumping remains false; handled in the update logic
    end
end

-- Function to check for collision between player and coins
function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
