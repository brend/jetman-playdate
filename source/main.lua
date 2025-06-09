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
----------------- Sound ---------------------
---------------------------------------------

local snd <const> = playdate.sound
local thrusterSynth = snd.synth.new(snd.kWaveNoise)
local thrusterChannel = snd.channel.new()
local isPlayingThruster = false

-- Configure the thruster sound to be hoarse and gravelly like Solar Jetman
thrusterSynth:setADSR(0.01, 0.1, 0.8, 0.2) -- Quick attack, short decay, high sustain, short release
thrusterSynth:setVolume(0.3)
thrusterChannel:addSource(thrusterSynth)

-- Low-pass filter to make it more muffled and gravelly
local thrusterFilter = snd.twopolefilter.new(snd.kFilterLowPass)
thrusterFilter:setFrequency(800) -- Cut off higher frequencies for gravel effect
thrusterFilter:setResonance(0.3)
thrusterChannel:addEffect(thrusterFilter)

-- Add some distortion for the hoarse quality
local thrusterDistortion = snd.bitcrusher.new()
thrusterDistortion:setAmount(0.4)        -- Moderate bit crushing
thrusterDistortion:setUndersampling(0.2) -- Slight undersampling
thrusterChannel:addEffect(thrusterDistortion)

-- Sound effect for the tractor beam
local beamSound = snd.synth.new(snd.kWaveSquare)
beamSound:setADSR(0.005, 0.02, 0.2, 0.05)

---------------------------------------------
----------------- Entities ------------------
---------------------------------------------

local function createEntity(x, y, attributes)
    local entity = {
        position = playdate.geometry.vector2D.new(x, y),
        velocity = playdate.geometry.vector2D.new(0, 0),
        mass = 1, -- Default mass
    }
    if attributes then
        for k, v in pairs(attributes) do
            entity[k] = v
        end
    end
    return entity
end

---------------------------------------------
--------------- Global State ----------------
---------------------------------------------

------ Graphics library for drawing
local gfx <const> = playdate.graphics
--- Particles table to hold all particle objects
local particles <const> = {}
--- Items table to hold all item objects
local items <const> = { createEntity(100, 100) }
--- Jetpod object representing the player's ship
local jetpod <const> = createEntity(0, 0, {
    velocity = playdate.geometry.vector2D.new(0, 0),
    heading = 0,
    isThrusting = false,
    tractorBeam = {
        isActive = false,
        target = nil, -- The item being targeted by the tractor beam
    },
    maxHealth = 100,
    health = 100,
    maxFuel = 100,
    fuel = 100,
})

---------------------------------------------
----------------- Terrain -------------------
---------------------------------------------

local terrainSegments = {
    { x1 = 0,   y1 = 180, x2 = 100, y2 = 180 },
    { x1 = 100, y1 = 180, x2 = 200, y2 = 160 },
    { x1 = 200, y1 = 160, x2 = 400, y2 = 160 },
}

local function pointToSegmentDistance(px, py, x1, y1, x2, y2)
    local A = px - x1
    local B = py - y1
    local C = x2 - x1
    local D = y2 - y1

    local dot = A * C + B * D
    local lenSq = C * C + D * D
    local param = dot / lenSq

    local xx, yy
    if param < 0 then
        xx, yy = x1, y1
    elseif param > 1 then
        xx, yy = x2, y2
    else
        xx = x1 + param * C
        yy = y1 + param * D
    end

    local dx = px - xx
    local dy = py - yy
    return math.sqrt(dx * dx + dy * dy)
end

local function checkJetpodCollision()
    for _, seg in ipairs(terrainSegments) do
        local dist = pointToSegmentDistance(
            jetpod.position.x, jetpod.position.y,
            seg.x1, seg.y1, seg.x2, seg.y2
        )
        if dist < 5 then -- radius for collision
            return seg
        end
    end
    return nil
end

local function reflectVelocity(velocity, x1, y1, x2, y2)
    -- Compute segment direction
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / length, dy / length

    -- Compute normal (perpendicular to segment)
    local nx, ny = -dy, dx

    -- Dot product of velocity and normal
    local dot = velocity.dx * nx + velocity.dy * ny

    -- Reflect: v - 2*(v·n)*n
    velocity.dx = velocity.dx - 2 * dot * nx
    velocity.dy = velocity.dy - 2 * dot * ny

    -- Dampen to reduce energy
    velocity.dx = velocity.dx * 0.6
    velocity.dy = velocity.dy * 0.6
end

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
            particle.position:addVector(particle.velocity)
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
local function makeParticle(x, y, vx, vy, size)
    local particle = createEntity(x, y, {
        velocity = playdate.geometry.vector2D.new(vx or 0, vy or 0),
        lifetime = 20 + math.random(7), -- Lifetime in frames
        size = size or 2,               -- Size of the particle
    })
    particles[#particles + 1] = particle
end

local function updateTractorBeam(deltaTime)
    deltaTime = deltaTime or (1 / 30)

    if not jetpod.tractorBeam.isActive then
        return
    end

    local item = items[jetpod.tractorBeam.target]
    local delta = jetpod.position - item.position
    local distance = delta:magnitude()
    local restLength = TRACTOR_LENGTH

    if distance < 0.01 then
        return
    end

    local direction = delta:normalized()

    -- Desired position for the item, keeping it at TRACTOR_LENGTH from the jetpod
    local targetPosition = jetpod.position - direction * restLength

    -- Move item toward target position with fixed speed
    local pullSpeed = 100 -- Units per second
    local moveVector = targetPosition - item.position
    local moveDistance = math.min(moveVector:magnitude(), pullSpeed * deltaTime)

    item.position = item.position + moveVector:normalized() * moveDistance
end

--- Updates the jetpod's position and velocity based on its thrust and heading.
local function updateJetpod()
    -- Compute acceleration based on thrust and heading
    local acceleration = playdate.geometry.vector2D.new(0, GRAVITY) -- Gravity always acts downwards
    local angle = jetpod.heading

    if jetpod.isThrusting and jetpod.fuel > 0 then
        acceleration = playdate.geometry.vector2D.new(math.cos(angle) * 0.1, math.sin(angle) * 0.1)

        -- Start thruster sound if not already playing
        if not isPlayingThruster then
            -- Play a low-pitched noise with slight frequency modulation for gravel effect
            local baseFreq = 80 + math.random(20) -- Random base frequency between 80-100 Hz
            thrusterSynth:playNote(baseFreq, 1.0) -- Play indefinitely
            isPlayingThruster = true
        end

        -- Decrease fuel
        jetpod.fuel = jetpod.fuel - 0.1
        if jetpod.fuel < 0 then
            jetpod.fuel = 0 -- Prevent negative fuel
        end

        -- Add slight frequency modulation for realistic engine sound
        local freqMod = 80 + math.random(30) -- Vary frequency slightly
        thrusterSynth:setFrequencyMod(freqMod)
    else
        -- Stop thruster sound when not thrusting
        if isPlayingThruster then
            thrusterSynth:noteOff()
            isPlayingThruster = false
        end
    end

    -- Move the jetpod based on its acceleration and velocity
    jetpod.velocity:addVector(acceleration)
    -- Clamp the velocity to the maximum allowed
    jetpod.velocity = clampvector(jetpod.velocity, -MAX_VELOCITY, MAX_VELOCITY)
    -- Update the position of the jetpod
    jetpod.position:addVector(jetpod.velocity)

    -- Collision detection with terrain
    local hitSegment = checkJetpodCollision()
    if hitSegment then
        reflectVelocity(jetpod.velocity, hitSegment.x1, hitSegment.y1, hitSegment.x2, hitSegment.y2)
        -- Slightly push jetpod away to avoid sticking
        jetpod.position:addVector(jetpod.velocity)
        -- Play a dull, ringing sound on collision
        local collisionSound = snd.synth.new(snd.kWaveTriangle)
        collisionSound:setADSR(0.01, 0.1, 0.3, 0.5)
        collisionSound:playNote(60, 0.4, 0.7)
        -- Visually indicate the collision
        for i = 1, 5 do
            -- Create a particle at the collision point
            local v = randomvector()
            local size = math.random(2, 4)
            makeParticle(jetpod.position.x, jetpod.position.y, v.x, v.y, size)
        end
    end

    -- Create particles for thrust
    if jetpod.isThrusting then
        local particleCount = 1
        for i = 1, particleCount do
            local angleOffset = PI_3 - math.random() * 2 * PI_3 -- Random angle offset for variation
            local vx = -math.cos(jetpod.heading + angleOffset) * 2
            local vy = -math.sin(jetpod.heading + angleOffset) * 2
            makeParticle(jetpod.position.x, jetpod.position.y, vx, vy, 1)
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
        local distance = (jetpod.position - item.position):magnitude()
        if distance < nearestDistance then
            nearestDistance = distance
            nearestItem = itemIndex
        end
    end

    if nearestItem then
        jetpod.tractorBeam.isActive = true
        jetpod.tractorBeam.target = nearestItem
    end

    if jetpod.tractorBeam.isActive then
        -- Play a sharper, higher-pitched sound effect for the tractor beam activation
        beamSound:playNote(350, 0.6, 0.1)
    end
end

local function deactivateTractorBeam()
    jetpod.tractorBeam.isActive = false
    jetpod.tractorBeam.target = nil
    -- Stop the tractor beam sound
    beamSound:noteOff()
end

---------------------------------------------
----------------- Drawing -------------------
---------------------------------------------

local fuelIcon = gfx.image.new("images/fuelIcon")
local energyIcon = gfx.image.new("images/energyIcon")

--- Draws all particles on the screen.
local function drawParticles()
    gfx.setColor(gfx.kColorWhite)
    for _, particle in ipairs(particles) do
        gfx.fillCircleAtPoint(particle.position.x, particle.position.y, particle.size)
    end
end

--- Draws all items on the screen.
local function drawItems()
    gfx.setColor(gfx.kColorWhite)
    for _, item in ipairs(items) do
        gfx.fillRect(item.position.x - 5, item.position.y - 5, 10, 10)
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
    local x2 = x + size * math.cos(angle + PI * 5 / 7)
    local y2 = y + size * math.sin(angle + PI * 5 / 7)
    local x3 = x + size * math.cos(angle - PI * 5 / 7)
    local y3 = y + size * math.sin(angle - PI * 5 / 7)
    gfx.fillTriangle(x1, y1, x2, y2, x3, y3)
    -- Draw the tractor beam if active
    if jetpod.tractorBeam.isActive and jetpod.tractorBeam.target then
        local targetItem = items[jetpod.tractorBeam.target]
        if targetItem then
            gfx.setColor(gfx.kColorWhite)
            gfx.drawLine(x, y, targetItem.position.x, targetItem.position.y)
        end
    end
end

local function drawTerrain()
    gfx.setColor(gfx.kColorWhite)
    for _, seg in ipairs(terrainSegments) do
        gfx.drawLine(seg.x1, seg.y1, seg.x2, seg.y2)
    end
end

local function drawHud()
    -- draw fuel gauge as a horizontal bar
    fuelIcon:draw(0, 10)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(10, 10, 100, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(11, 11, 98, 8)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(12, 12, 96 * (jetpod.fuel / jetpod.maxFuel), 6)

    -- draw energy gauge as a horizontal bar
    energyIcon:draw(0, 30)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(10, 30, 100, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(11, 31, 98, 8)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(12, 32, 96 * (jetpod.health / jetpod.maxHealth), 6)
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
    updateTractorBeam()

    -- Center the view on the jetpod
    gfx.setDrawOffset(200 - jetpod.position.x, 120 - jetpod.position.y)
    drawTerrain()
    drawParticles()
    drawItems()
    drawJetpod()
    gfx.setDrawOffset(0, 0)
    drawHud();
end
