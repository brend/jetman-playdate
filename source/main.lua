import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

local particles <const> = {}
local jetpod <const> = { x = 200, y = 120, heading = 0, isThrusting = false, velocity = 0, acceleration = 0 }

---------------------------------------------
---------- Updating the Game State ----------
---------------------------------------------

local function updateParticles()
    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.y = particle.y + 1    -- Move the particle down
        if particle.y > 240 then
            table.remove(particles, i) -- Remove the particle if it goes off-screen
        end
    end
end

local function makeParticle(x, y)
    local particle = {
        x = x,
        y = y
    }
    particles[#particles + 1] = particle
end

local function updateJetpod()
    if jetpod.isThrusting then
        jetpod.acceleration = 0.1

        -- Create particles at the jetpod's position
        makeParticle(jetpod.x, jetpod.y)
    end

    -- Move the jetpod based on its heading
    local angle = jetpod.heading
    jetpod.velocity = jetpod.velocity + jetpod.acceleration
    jetpod.x = jetpod.x + math.cos(angle) * jetpod.velocity
    jetpod.y = jetpod.y + math.sin(angle) * jetpod.velocity
    jetpod.acceleration = 0 -- Reset acceleration after applying it

    -- Keep the jetpod within screen bounds
    if jetpod.x < 0 then jetpod.x = 0 end
    if jetpod.x > 400 then jetpod.x = 400 end
    if jetpod.y < 0 then jetpod.y = 0 end
    if jetpod.y > 240 then jetpod.y = 240 end
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
    gfx.fillRect(jetpod.x - 10, jetpod.y - 10, 20, 20)
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
