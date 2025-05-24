-----------------------------------------------
------------------- Vectors -------------------
-----------------------------------------------

--- Creates a vector with x and y components.
--- If no components are provided, defaults to (0, 0).
--- @param x number (optional) The x-component of the vector
--- @param y number (optional) The y-component of the vector
--- @return table A vector table with x and y components
function vector(x, y)
    return { x = x or 0, y = y or 0 }
end

--- Calculates the length (magnitude) of a vector.
--- If the length has already been calculated, it returns the cached value.
--- @param v table The vector whose length is to be calculated
--- @return number The length of the vector
function vectorLength(v)
    if v.length == nil then
        v.length = math.sqrt(v.x * v.x + v.y * v.y)
    end
    return v.length
end

--- Calculates the squared length of a vector.
--- This is useful for performance when you only need to compare lengths.
--- If the squared length has already been calculated, it returns the cached value.
--- @param v table The vector whose squared length is to be calculated
--- @return number The squared length of the vector
function vectorLengthSquared(v)
    if v.lengthSquared == nil then
        v.lengthSquared = v.x * v.x + v.y * v.y
    end
    return v.lengthSquared
end

--- Normalizes a vector to have a length of 1.
--- If the vector's length is zero, it returns a zero vector.
--- @param v table The vector to normalize
--- @return table A new vector with the same direction as v but with a length of 1
function normalize(v)
    local length = vectorLength(v)
    if length == 0 then
        return vector(0, 0) -- Return a zero vector if the input is a zero vector
    end
    return { x = v.x / length, y = v.y / length }
end

--- Adds two vectors together.
--- @param a table The first vector
--- @param b table The second vector
--- @return table A new vector that is the sum of a and b
function addvector(a, b)
    return { x = a.x + b.x, y = a.y + b.y }
end

--- Subtracts vector b from vector a.
--- @param a table The vector to subtract from
--- @param b table The vector to subtract
--- @return table A new vector that is the result of the subtraction
function subvector(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

--- Multiplies a vector by a scalar.
--- @param a table The vector to multiply
--- @param scalar number The scalar to multiply the vector by
--- @return table A new vector that is the result of the multiplication
function multvector(a, scalar)
    return { x = a.x * scalar, y = a.y * scalar }
end

--- Divides a vector by a scalar.
--- @param a table The vector to divide
--- @param scalar number The scalar to divide the vector by
--- @return table A new vector that is the result of the division
--- @throws an error if scalar is zero
function divvector(a, scalar)
    if scalar == 0 then
        error("Division by zero is not allowed")
    end
    return { x = a.x / scalar, y = a.y / scalar }
end

--- Constraints a vector's components to be within a specified range.
--- @param v table The vector to clamp
--- @param min number The minimum value for both x and y components
--- @param max number The maximum value for both x and y components
--- @return table A new vector with clamped components
function clampvector(v, min, max)
    return {
        x = math.max(min, math.min(max, v.x)),
        y = math.max(min, math.min(max, v.y))
    }
end

--- Checks if a vector is within the screen bounds.
--- @param v table The vector to check
--- @return boolean True if the vector is within the screen bounds, false otherwise
function insideScreen(v)
    return v.x >= 0 and v.x <= 400 and v.y >= 0 and v.y <= 240
end
