import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "math"

---------------------------------------------
---------------- Constants ------------------
---------------------------------------------

--- The mathematical constant Pi
local PI <const> = math.pi
--- Pi divided by 3
local PI_3 <const> = PI / 3
--- Maximum velocity for the jetpod
local MAX_VELOCITY <const> = 3.0
--- Gravity constant
local GRAVITY <const> = 0.05
--- Length of the tractor beam
local TRACTOR_LENGTH <const> = 50.0

---------------------------------------------
--------------- Global State ----------------
---------------------------------------------

------ Graphics library for drawing
local gfx <const> = playdate.graphics
--- Particles table to hold all particle objects
local particles <const> = {}
--- Items table to hold all item objects
local items <const> = { { x = 100, y = 100 } }
--- Jetpod object representing the player's ship
local jetpod <const> = {
    position = vector(200, 120), -- Starting position in the center of the screen
    velocity = vector(),
    heading = 0,
    isThrusting = false,
    tractorBeam = {
        isActive = false,
        target = nil, -- The item being targeted by the tractor beam
    },
}

---------------------------------------------
---------- Updating the Game State ----------
---------------------------------------------

--- Updates the particles by moving them and removing those that have expired.
local function updateParticles()
    for i = #particles, 1, -1 do
        local particle = particles[i]
        -- Remove the particle if its lifetime is over
        if particle.lifetime <= 0 then
            table.remove(particles, i)
        else
            -- Update the particle's position based on its velocity
            particle.position = addvector(particle.position, particle.velocity)
            particle.lifetime = particle.lifetime - 1
        end
    end
end

--- Creates a new particle at the specified position with an optional velocity
--- and adds it to the particles table.
--- @param x number The x-coordinate of the particle's position
--- @param y number The y-coordinate of the particle's position
--- @param vx number (optional) The x-component of the particle's velocity
--- @param vy number (optional) The y-component of the particle's velocity
local function makeParticle(x, y, vx, vy)
    local particle = {
        position = vector(x, y),
        velocity = vector(vx or 0, vy or 0),
        lifetime = 20 + math.random(7), -- Lifetime in frames
    }
    particles[#particles + 1] = particle
end

--- Updates the jetpod's position and velocity based on its thrust and heading.
local function updateJetpod()
    -- Compute acceleration based on thrust and heading
    local acceleration = vector(0, GRAVITY) -- Gravity always acts downwards
    local angle = jetpod.heading

    if jetpod.isThrusting then
        acceleration = vector(math.cos(angle) * 0.1, math.sin(angle) * 0.1)
    end

    -- Move the jetpod based on its acceleration and velocity
    jetpod.velocity = addvector(jetpod.velocity, acceleration)
    -- Clamp the velocity to the maximum allowed
    jetpod.velocity = clampvector(jetpod.velocity, -MAX_VELOCITY, MAX_VELOCITY)
    -- Update the position of the jetpod
    jetpod.position = addvector(jetpod.position, jetpod.velocity)

    -- Create particles for thrust
    if jetpod.isThrusting then
        local particleCount = 1
        for i = 1, particleCount do
            local angleOffset = PI_3 - math.random() * 2 * PI_3 -- Random angle offset for variation
            local vx = -math.cos(jetpod.heading + angleOffset) * 2
            local vy = -math.sin(jetpod.heading + angleOffset) * 2
            makeParticle(jetpod.position.x, jetpod.position.y, vx, vy)
        end
    end
end

local function activateTractorBeam()
    if jetpod.tractorBeam.isActive then
        return -- If the tractor beam is already active, do nothing
    end

    -- Activate the tractor beam and find the nearest item
    local nearestItem = nil
    local nearestDistance = TRACTOR_LENGTH

    for itemIndex, item in ipairs(items) do
        local distance = vectorLength(subvector(jetpod.position, vector(item.x, item.y)))
        if distance < nearestDistance then
            nearestDistance = distance
            nearestItem = itemIndex
        end
    end

    if nearestItem then
        jetpod.tractorBeam.isActive = true
        jetpod.tractorBeam.target = nearestItem
    end
end

local function deactivateTractorBeam()
    jetpod.tractorBeam.isActive = false
    jetpod.tractorBeam.target = nil
end

---------------------------------------------
----------------- Drawing -------------------
---------------------------------------------

--- Draws all particles on the screen.
local function drawParticles()
    gfx.setColor(gfx.kColorWhite)
    for _, particle in ipairs(particles) do
        gfx.fillCircleAtPoint(particle.position.x, particle.position.y, 2)
    end
end

--- Draws all items on the screen.
local function drawItems()
    gfx.setColor(gfx.kColorWhite)
    for _, item in ipairs(items) do
        gfx.fillRect(item.x - 5, item.y - 5, 10, 10)
    end
end

--- Draws the jetpod on the screen as a triangle pointing in its heading direction.
local function drawJetpod()
    gfx.setColor(gfx.kColorWhite)
    -- Draw the jetpod as a simple triangle
    local size = 10
    local angle = jetpod.heading
    local x = jetpod.position.x
    local y = jetpod.position.y
    local x1 = x + size * math.cos(angle)
    local y1 = y + size * math.sin(angle)
    local x2 = x + size * math.cos(angle + PI * 2 / 3)
    local y2 = y + size * math.sin(angle + PI * 2 / 3)
    local x3 = x + size * math.cos(angle - PI * 2 / 3)
    local y3 = y + size * math.sin(angle - PI * 2 / 3)
    gfx.fillTriangle(x1, y1, x2, y2, x3, y3)
    -- Draw the tractor beam if active
    if jetpod.tractorBeam.isActive and jetpod.tractorBeam.target then
        local targetItem = items[jetpod.tractorBeam.target]
        if targetItem then
            gfx.setColor(gfx.kColorWhite)
            gfx.drawLine(x, y, targetItem.x, targetItem.y)
        end
    end
end

---------------------------------------------
------------- Handling Input ----------------
---------------------------------------------

--- Handles user input for controlling the game.
local function handleInput()
    jetpod.isThrusting = playdate.buttonIsPressed(playdate.kButtonA)

    if playdate.buttonIsPressed(playdate.kButtonUp) then
        activateTractorBeam()
    end

    if playdate.buttonIsPressed(playdate.kButtonDown) then
        deactivateTractorBeam()
    end

    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        jetpod.heading = jetpod.heading - 0.1
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        jetpod.heading = jetpod.heading + 0.1
    end
end

---------------------------------------------
---------------- Game Loop ------------------
---------------------------------------------

--- Main update function called every frame.
function playdate.update()
    gfx.clear(gfx.kColorBlack)
    gfx.sprite.update()
    playdate.timer.updateTimers()

    handleInput()

    updateParticles()
    updateJetpod()

    drawParticles()
    drawItems()
    drawJetpod()
end
