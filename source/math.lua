function vector(x, y)
    return { x = x or 0, y = y or 0 }
end

function addvector(a, b)
    return { x = a.x + b.x, y = a.y + b.y }
end

function subvector(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

function multvector(a, scalar)
    return { x = a.x * scalar, y = a.y * scalar }
end

function divvector(a, scalar)
    return { x = a.x / scalar, y = a.y / scalar }
end

function clampvector(v, min, max)
    return {
        x = math.max(min, math.min(max, v.x)),
        y = math.max(min, math.min(max, v.y))
    }
end

function insideScreen(v)
    return v.x >= 0 and v.x <= 400 and v.y >= 0 and v.y <= 240
end
