function lovr.load()
    models = {}
    photos = {
        lovr.graphics.newMaterial(lovr.graphics.newTexture('country.jpg', { mipmaps = false })),
        lovr.graphics.newMaterial(lovr.graphics.newTexture('mountains.jpg', { mipmaps = false })),
        lovr.graphics.newMaterial(lovr.graphics.newTexture('windmill.jpg', { mipmaps = false }))
    }
    sphere = {
        position = lovr.math.newVec3(0, 1.2, -1),
        radius = .15
    }
    currentPhoto = 1
    headOffset = lovr.graphics.newVec3(0, -.5, -1)
    shader = lovr.graphics.newShader(bubbleShader())
end

function lovr.update(dt)
    handlePhotoSelection()
    local posRelativeToHead = mat4(lovr.headset.getPose()):translate(headOffset)
    sphere.position:set(posRelativeToHead)
end

function handlePhotoSelection()
    for i, hand in ipairs(lovr.headset.getHands()) do
        local p = lovr.math.vec3(lovr.headset.getPose(hand))
        local d = p - sphere.position
        inSphere = (d.x * d.x + d.y * d.y + d.z * d.z) < math.pow(sphere.radius, 2)
        if inSphere then
            if lovr.headset.wasPressed(hand, 'trigger') then
                cyclePhoto()
            end
        end
    end
end

function lovr.draw()
    lovr.graphics.skybox(photos[currentPhoto]:getTexture())

    drawSphere()
    drawControllers()
end

function drawSphere()
    local color = inSphere and 0xffffff or 0xd3d3d3
    lovr.graphics.setColor(color)
    lovr.graphics.setShader(shader)
    lovr.graphics.sphere(photos[nextPhoto()], sphere.position, sphere.radius)
    lovr.graphics.setShader()
    lovr.graphics.setColor(0xffffff)
end

function drawControllers()
    for i, hand in ipairs(lovr.headset.getHands()) do
        models[hand] = models[hand] or lovr.headset.newModel(hand)

        if models[hand] then
            local x, y, z, angle, ax, ay, az = lovr.headset.getPose(hand)
            models[hand]:draw(x, y, z, 1, angle, ax, ay, az)
        end
    end
end

function cyclePhoto()
    currentPhoto = nextPhoto()
end

function nextPhoto()
    return (currentPhoto % #photos) + 1
end

function bubbleShader()
    return [[
        out vec3 FragmentPos;
        out vec3 CameraPos;
        out vec3 Normal;
        vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
            Normal = (lovrNormalMatrix * lovrNormal).xyz;
            FragmentPos = (lovrModel * vertex).xyz;
            CameraPos = -lovrView[3].xyz * mat3(lovrView);
            return projection * transform * vertex;
        }
        ]], [[
        in vec3 Normal;
        in vec3 FragmentPos;
        in vec3 CameraPos;
        vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
            vec3 toCam = normalize(CameraPos - FragmentPos);
            float rimAmt = 1.0 - max(0.0, dot(normalize(Normal), toCam));
            rimAmt = pow(rimAmt, 3.5);
            return mix(texture(image, uv) * graphicsColor, vec4(1.), rimAmt);
        }
    ]]
end