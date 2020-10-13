function lovr.load()
    models = {}
    photos = {
        lovr.graphics.newMaterial(lovr.graphics.newTexture('country.jpg', { mipmaps = false })),
        lovr.graphics.newMaterial(lovr.graphics.newTexture('mountains.jpg', { mipmaps = false })),
        lovr.graphics.newMaterial(lovr.graphics.newTexture('windmill.jpg', { mipmaps = false }))
    }
    sphere = {
        position = lovr.math.newVec3(0, 1.1, -1),
        translater = 0,
        translateThreshold = 1.3,
        radius = .15,
        posRelativeToHead = lovr.math.newVec3(),
        yOverride = 1.1
    }
    currentPhoto = 1
    headOffset = lovr.math.newVec3(0, -0.5, -0.6)
    shader = lovr.graphics.newShader(bubbleShader())
end

-- App cycle
function lovr.update(dt)
    handlePhotoSelection()
    repositionSelectionSphere(dt)
end

function handlePhotoSelection()
    for i, hand in ipairs(lovr.headset.getHands()) do
        local handPos =  lovr.math.vec3(lovr.headset.getPose(hand))
        handInSphere = sphereDistanceTest(handPos, sphere.radius)
        if handInSphere then
            if lovr.headset.wasPressed(hand, 'trigger') then
                cyclePhoto()
            end
        end
    end
end

function repositionSelectionSphere(variator)
    local headPos = lovr.math.vec3(lovr.headset.getPose())
    local sphereNearHead = sphereDistanceTest(headPos, sphere.translateThreshold)
    if not sphereNearHead then
        local v = lovr.math.vec3(mat4(lovr.headset.getPose()):translate(headOffset))
        sphere.posRelativeToHead:set(v.x, sphere.yOverride, v.z)
        sphere.translater = math.min(sphere.translater + variator * .05, 1)
    end
end

-- Rendering
function lovr.draw()
    lovr.graphics.skybox(photos[currentPhoto]:getTexture())

    drawSphere()
    drawControllers()
end

function drawSphere()
    local color = handInSphere and 0xffffff or 0xd3d3d3
    local ease = quadraticEaseInOut(sphere.translater)
    lovr.graphics.setColor(color)
    lovr.graphics.setShader(shader)
    sphere.position:lerp(sphere.posRelativeToHead, ease)
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

-- Update and Draw helpers
function cyclePhoto()
    currentPhoto = nextPhoto()
end

function nextPhoto()
    return (currentPhoto % #photos) + 1
end

function sphereDistanceTest(pos, dist)
    local d = pos - sphere.position
    return (d.x * d.x + d.y * d.y + d.z * d.z) < (dist ^ 2)
end

function quadraticEaseInOut(val)
    return val < 0.5 and 2 * val * val or 1 - math.pow(-2 * val + 2, 2) / 2
end

-- Shader
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