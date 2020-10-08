function lovr.load()
    models = {}
    photos = {
        lovr.graphics.newTexture('country.jpg'),
        lovr.graphics.newTexture('mountains.jpg'),
        lovr.graphics.newTexture('windmill.jpg')
    }
    sphere = {
        position = lovr.math.newVec3(0, 1.2, -1),
        radius = .15
    }
    currentPhoto = 1
end

function lovr.update(dt)
    for i, hand in ipairs(lovr.headset.getHands()) do
        local p = lovr.math.vec3(lovr.headset.getPose(hand))
        local d = p - sphere.position
        inSphere = (d.x * d.x + d.y * d.y + d.z * d.z) < math.pow(sphere.radius, 2)
        if inSphere then
            if lovr.headset.wasPressed(hand, 'trigger') then
                swapPhoto()
            end
        end
    end
end

function lovr.draw()
    lovr.graphics.skybox(photos[currentPhoto])

    local color = inSphere and 0xffffff or 0xd3d3d3
    lovr.graphics.setColor(color)
    lovr.graphics.sphere(sphere.position.x, sphere.position.y, sphere.position.z, sphere.radius)
    lovr.graphics.setColor(0xffffff)

    for i, hand in ipairs(lovr.headset.getHands()) do
        models[hand] = models[hand] or lovr.headset.newModel(hand)

        if models[hand] then
            local x, y, z, angle, ax, ay, az = lovr.headset.getPose(hand)
            models[hand]:draw(x, y, z, 1, angle, ax, ay, az)
        end
    end
end

function swapPhoto()
    currentPhoto = (currentPhoto % #photos) + 1
end