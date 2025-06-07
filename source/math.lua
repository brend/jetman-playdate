-----------------------------------------------
------------------- Vectors -------------------
-----------------------------------------------

--- Constraints a vector's components to be within a specified range.
--- @param v table The vector to clamp
--- @param min number The minimum value for both x and y components
--- @param max number The maximum value for both x and y components
--- @return table A new vector with clamped components
function clampvector(v, min, max)
    local m = v:magnitude()
    if m < min then
        return v:normalized() * min
    elseif m > max then
        return v:normalized() * max
    else
        return v
    end
end

--- Generates a unit vector pointing in a random direction.
--- @return table A vector with x and y components set to a random direction
function randomvector()
    local angle = math.random() * 2 * math.pi
    return { x = math.cos(angle), y = math.sin(angle) }
end

--- Checks if a vector is within the screen bounds.
--- @param v table The vector to check
--- @return boolean True if the vector is within the screen bounds, false otherwise
function insideScreen(v)
    return v.x >= 0 and v.x <= 400 and v.y >= 0 and v.y <= 240
end
