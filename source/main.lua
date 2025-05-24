import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "math"

---------------------------------------------
------------- Global Variables --------------
---------------------------------------------
local PI <const> = math.pi
local PI_3 <const> = PI / 3

local MAX_VELOCITY <const> = 3.0

local gfx <const> = playdate.graphics

local particles <const> = {}
local jetpod <const> = {
    position = vector(200, 120), -- Starting position in the center of the screen
    velocity = vector(),
    heading = 0,
    isThrusting = false,
}

---------------------------------------------
---------- Updating the Game State ----------
---------------------------------------------

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

local function makeParticle(x, y, vx, vy)
    local particle = {
        position = vector(x, y),
        velocity = vector(vx or 0, vy or 0),
        lifetime = 20 + math.random(7), -- Lifetime in frames
    }
    particles[#particles + 1] = particle
end

local function updateJetpod()
    -- Compute acceleration based on thrust and heading
    local acceleration = vector()
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

    -- Keep the jetpod within screen bounds
    if jetpod.position.x < 0 then jetpod.position.x = 0 end
    if jetpod.position.x > 400 then jetpod.position.x = 400 end
    if jetpod.position.y < 0 then jetpod.position.y = 0 end
    if jetpod.position.y > 240 then jetpod.position.y = 240 end

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

---------------------------------------------
----------------- Drawing -------------------
---------------------------------------------

local function drawParticles()
    gfx.setColor(gfx.kColorWhite)
    for _, particle in ipairs(particles) do
        gfx.fillCircleAtPoint(particle.position.x, particle.position.y, 2)
    end
end

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
end

---------------------------------------------
------------- Handling Input ----------------
---------------------------------------------

local function handleInput()
    jetpod.isThrusting = playdate.buttonIsPressed(playdate.kButtonUp)

    if playdate.buttonIsPressed(playdate.kButtonDown) then
        -- TODO
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        jetpod.heading = jetpod.heading - 0.1
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        jetpod.heading = jetpod.heading + 0.1
    end
end

function playdate.update()
    gfx.clear(gfx.kColorBlack)
    gfx.sprite.update()
    playdate.timer.updateTimers()

    handleInput()

    updateParticles()
    updateJetpod()

    drawParticles()
    drawJetpod()
end
