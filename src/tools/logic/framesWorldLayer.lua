local STORAGE_KEY = "$refined_place_it_frames_v1"
local ATTACHMENT_KEY = "$refined_place_it_building_attachment"
local CACHE_KEY = "$refined_place_it_frames_world_cache"
local WORLD_LAYER_TAG = "refined_place_it_frames_layer"

local COORD_BASE = 65536

local parentScript = script:getParent()
local ownerDraft = script:getDraft()
local ownerKind

if ownerDraft ~= nil then
    local okBuilding, isBuilding = pcall(ownerDraft.isBuilding, ownerDraft)
    local okRoad, isRoad = pcall(ownerDraft.isRoad, ownerDraft)

    if okBuilding and isBuilding then
        ownerKind = "building"
    elseif okRoad and isRoad then
        ownerKind = "road"
    end
end

if ownerKind == nil then
    script:addTag(WORLD_LAYER_TAG)
end

local cacheOwner = parentScript or script
local sharedCache = cacheOwner[CACHE_KEY]

if sharedCache == nil then
    sharedCache = {}
    cacheOwner[CACHE_KEY] = sharedCache
end

local function getStorage()
    local storage = Util.optStorage(City.getStorage(), STORAGE_KEY)
    storage.items = storage.items or {}
    storage.revision = math.floor(tonumber(storage.revision) or 0)
    return storage
end

local function resolveLiveFrame(draftId, frameIndex)
    local draft = Draft.getDraft(draftId)
    if draft == nil then
        return nil
    end

    frameIndex = math.max(1, math.floor(tonumber(frameIndex) or 1))
    local okCount, count = pcall(function ()
        return draft:getFrameCount()
    end)

    if okCount and count ~= nil and count > 0 then
        if frameIndex > count then
            return nil
        end

        local okFrame, frame = pcall(function ()
            return draft:getFrame(frameIndex)
        end)
        return okFrame and frame or nil
    end

    local okPreviewCount, previewCount = pcall(function ()
        return draft:getPreviewFrameCount()
    end)
    if not okPreviewCount or
       previewCount == nil or
       frameIndex > previewCount then
        return nil
    end

    local okPreview, frame = pcall(function ()
        return draft:getPreviewFrame(frameIndex)
    end)
    return okPreview and frame or nil
end

local function getBuildingAttachment(x, y)
    local storage = Tile.getBuildingStorage(x, y)
    if storage == nil then
        return 0
    end

    return math.max(
        0,
        math.floor(tonumber(storage[ATTACHMENT_KEY]) or 0)
    )
end

local function tileKey(x, y, level)
    return (math.floor(x) * COORD_BASE + math.floor(y)) *
        8 + math.floor(level or 0) + 4
end

local function addToBucket(buckets, key, item)
    local bucket = buckets[key]
    if bucket == nil then
        bucket = {}
        buckets[key] = bucket
    end
    bucket[#bucket + 1] = item
end

local function buildCache(storage)
    local cache = {
        cityId = tostring(City.getId()),
        revision = storage.revision,
        buildings = {},
        roads = {},
    }

    for _, item in ipairs(storage.items) do
        local drawItem = {
            draftId = item.draftId,
            frameIndex = item.frameIndex,
            x = item.x,
            y = item.y,
            level = item.level or 0,
            targetKind = item.targetKind,
            anchorX = item.anchorX,
            anchorY = item.anchorY,
            attachmentId = item.attachmentId or 0,
            offsetX = item.offsetX or 0,
            offsetY = item.offsetY or 0,
            scaleX = item.scaleX or 1,
            scaleY = item.scaleY or 1,
            alpha = item.alpha or 1,
            zOrder = math.max(
                1,
                math.min(8, math.floor(tonumber(item.zOrder) or 1))
            ),
            emissive = item.emissive == true,
            tintR = item.tintR or 255,
            tintG = item.tintG or 255,
            tintB = item.tintB or 255,
        }

        if drawItem.targetKind == "building" then
            addToBucket(
                cache.buildings,
                drawItem.attachmentId,
                drawItem
            )
        else
            addToBucket(
                cache.roads,
                tileKey(drawItem.x, drawItem.y, drawItem.level),
                drawItem
            )
        end
    end

    for _, bucket in pairs(cache.buildings) do
        table.sort(bucket, function (a, b)
            return (a.zOrder or 1) < (b.zOrder or 1)
        end)
    end
    for _, bucket in pairs(cache.roads) do
        table.sort(bucket, function (a, b)
            return (a.zOrder or 1) < (b.zOrder or 1)
        end)
    end

    sharedCache.cache = cache
    return cache
end

local function ensureCache(storage)
    local cache = sharedCache.cache
    local cityId = tostring(City.getId())

    if cache == nil or
       cache.cityId ~= cityId or
       cache.revision ~= storage.revision then
        cache = buildCache(storage)
    end

    return cache
end

local function getDaytimeMultiplier()
    local shadeR, shadeG, shadeB = Drawing.getDaytimeColor()
    local nightMix = math.max(
        0,
        math.min(1, (255 - shadeB) / 99)
    )

    return
        math.max(0, math.min(255, math.floor(
            shadeR * (1 + 0.064 * nightMix) + 0.5
        ))),
        math.max(0, math.min(255, math.floor(
            shadeG * (1 + 0.038 * nightMix) + 0.5
        ))),
        math.max(0, math.min(255, math.floor(
            shadeB * (1 - 0.077 * nightMix) + 0.5
        )))
end

local function drawBucket(bucket, anchorX, anchorY)
    if bucket == nil or #bucket == 0 then
        return
    end

    local restoreScaleX, restoreScaleY = Drawing.getScale()
    local drawR, drawG, drawB = getDaytimeMultiplier()
    local rotation = math.floor(tonumber(City.getRotation()) or 0) % 4

    for _, item in ipairs(bucket) do
        local frame = resolveLiveFrame(item.draftId, item.frameIndex)
        if frame ~= nil then
            local deltaX = item.x - anchorX
            local deltaY = item.y - anchorY

            if rotation == 1 then
                deltaX, deltaY = deltaY, -deltaX
            elseif rotation == 2 then
                deltaX, deltaY = -deltaX, -deltaY
            elseif rotation == 3 then
                deltaX, deltaY = -deltaY, deltaX
            end

            local scaleX = item.scaleX == 0 and 1 or item.scaleX
            local scaleY = item.scaleY == 0 and 1 or item.scaleY

            Drawing.setTile(
                anchorX,
                anchorY,
                ((deltaX + deltaY) * 16) / scaleX + item.offsetX,
                ((deltaX - deltaY) * 8) / scaleY + item.offsetY,
                scaleX,
                scaleY
            )

            if item.emissive then
                Drawing.setColor(item.tintR, item.tintG, item.tintB)
            else
                Drawing.setColor(
                    math.floor(drawR * item.tintR / 255 + 0.5),
                    math.floor(drawG * item.tintG / 255 + 0.5),
                    math.floor(drawB * item.tintB / 255 + 0.5)
                )
            end

            Drawing.setAlpha(item.alpha)
            Drawing.drawImage(frame, 0, 0)
        end
    end

    Drawing.setScale(restoreScaleX, restoreScaleY)
    Drawing.setColor(255, 255, 255)
    Drawing.setAlpha(1)
    Drawing.setAdditive(0)
end

function script:draw(x, y, level)
    if ownerKind == nil then
        return
    end

    local storage = getStorage()
    local cache = ensureCache(storage)

    if ownerKind == "building" then
        if not Tile.isBuilding(x, y) then
            return
        end

        local anchorX, anchorY = Tile.getBuildingXY(x, y)
        if anchorX ~= x or anchorY ~= y then
            return
        end

        local attachmentId = getBuildingAttachment(anchorX, anchorY)
        if attachmentId > 0 then
            drawBucket(
                cache.buildings[attachmentId],
                anchorX,
                anchorY
            )
        end
        return
    end

    level = math.floor(tonumber(level) or 0)
    if Tile.isBuilding(x, y) or not Tile.hasRoad(x, y, level) then
        return
    end

    drawBucket(
        cache.roads[tileKey(x, y, level)],
        x,
        y
    )
end

function script:event(x, y, level, event)
    if parentScript == nil then
        return
    end

    local removeEvent = Script.EVENT_REMOVE or 6
    if event ~= removeEvent and event ~= 6 then
        return
    end

    local handler = parentScript.onFramesTargetRemoved
    if type(handler) == "function" then
        pcall(handler, x, y, level, ownerKind)
    end
end
