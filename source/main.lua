import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

---------------------------------------------
------------- Global Variables --------------
---------------------------------------------
local PI <const> = math.pi
local PI_3 <const> = PI / 3

local MAX_VELOCITY <const> = 3.0

local gfx <const> = playdate.graphics

local particles <const> = {}
local jetpod <const> = {
    position = { x = 200, y = 120 },
    velocity = { x = 0, y = 0 },
    heading = 0,
    isThrusting = false,
}

---------------------------------------------
---------- Updating the Game State ----------
---------------------------------------------

local function updateParticles()
    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.x = particle.x + particle.vx
        particle.y = particle.y + particle.vy
        particle.lifetime = particle.lifetime - 1

        -- Remove the particle if its lifetime is over
        if particle.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
    -- Remove particles that are out of bounds
    for i = #particles, 1, -1 do
        local particle = particles[i]
        if particle.x < 0 or particle.x > 400 or particle.y < 0 or particle.y > 240 then
            table.remove(particles, i)
        end
    end
    -- Limit the number of particles
    if #particles > 100 then
        for i = #particles, 101, -1 do
            table.remove(particles, i)
        end
    end
end

local function makeParticle(x, y, vx, vy)
    local particle = {
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        lifetime = 20 + math.random(7), -- Lifetime in frames
    }
    particles[#particles + 1] = particle
end

local function updateJetpod()
    -- Compute acceleration based on thrust and heading
    local acceleration = { x = 0, y = 0 }
    local angle = jetpod.heading

    if jetpod.isThrusting then
        acceleration.x = math.cos(angle) * 0.1
        acceleration.y = math.sin(angle) * 0.1
    end

    -- Move the jetpod based on its acceleration and velocity
    jetpod.velocity.x = jetpod.velocity.x + acceleration.x
    jetpod.velocity.y = jetpod.velocity.y + acceleration.y

    jetpod.velocity.x = math.max(-MAX_VELOCITY, math.min(MAX_VELOCITY, jetpod.velocity.x))
    jetpod.velocity.y = math.max(-MAX_VELOCITY, math.min(MAX_VELOCITY, jetpod.velocity.y))

    jetpod.position.x = jetpod.position.x + jetpod.velocity.x
    jetpod.position.y = jetpod.position.y + jetpod.velocity.y

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
        gfx.fillCircleAtPoint(particle.x, particle.y, 2)
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
