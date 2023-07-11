local addonName, frameInspect = ...
local _

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

--get templates
local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local onFocusTextureFrame = CreateFrame("frame", nil, UIParent)
onFocusTextureFrame:SetSize(1, 1)
onFocusTextureFrame:SetPoint("topleft", UIParent, "topleft", 0, 0)
onFocusTextureFrame:SetFrameStrata("TOOLTIP")
local onFocusTexture = onFocusTextureFrame:CreateTexture("FrameInspectFocusFrameTexture", "overlay", nil, 7)
onFocusTexture:SetColorTexture(.3, .7, .3, .3)
local onFocusText = onFocusTextureFrame:CreateFontString("FrameInspectFocusFrameString", "overlay", "GameFontNormal", 7)
onFocusText:SetPoint("bottom", onFocusTexture, "top", 0, 2)
onFocusText:SetText("F4: Inspect")

local onFocusBorder = CreateFrame("frame", "FrameInspectBorderFrame", UIParent)
onFocusBorder:EnableMouse(false)
onFocusBorder.Border = DF:CreateBorderFrame(onFocusBorder, "$parentBorder")

--store frames which got mouse disabled by pressing ALT
--when the mouse moves or inspecting is started, this list resets (enabling mouse on all frames again)
local currentMouseDisabledFrames = {}

local hideOnFocusTexture = function()
    onFocusText:Hide()
    onFocusTexture:Hide()
    onFocusBorder:Hide()
end

--move inspecting indicator textures into the new frame
function frameInspect.MoveInspectIndicators(frame, isChildren)
    if (not frame) then
        onFocusBorder:Hide()
        return
    end

    --if the object is abstract: animationGroup, animations
    if (not frame.GetPoint) then
        onFocusBorder:Hide()
        return
    end

    frame = frame.dframework and frame.widget or frame

    onFocusBorder:SetFrameStrata("TOOLTIP")
    onFocusBorder:ClearAllPoints()
    onFocusBorder:SetPoint("topleft", frame, "topleft", -2, 2)
    onFocusBorder:SetPoint("bottomright", frame, "bottomright", 2, -2)
    onFocusBorder.Border:SetBorderThickness(1)
    onFocusBorder.Border:SetBorderColor("green")
    onFocusBorder.Border:SetAlpha(0.5)
    onFocusBorder:Show()

    --[=[
    if (isChildren) then
        frameInspect.focusChild = frame
        frameInspect.UpdateInformationFrame()
    else
        if (frameInspect.focusChild) then
            frameInspect.focusChild =  nil
            frameInspect.ShowFocusTexture(frame, true)
            frameInspect.UpdateInformationFrame()
        end
    end
    --]=]
end

function frameInspect.ShowFocusTexture(object, noChildrenRefresh)
    if (not object) then
        onFocusText:Hide()
        onFocusTexture:Hide()
        return
    end

    onFocusTexture:ClearAllPoints()
    onFocusTexture:SetColorTexture(.3, .7, .3, .3)
    onFocusTexture:SetAllPoints()

    onFocusText:Show()
    onFocusTexture:Show()
end


function frameInspect.GetInspectingObject()
    return frameInspect.inspectingFrame
end

function frameInspect.GetPreviewingObject()
    return frameInspect.focusFrame
end

function frameInspect.StartInspectingObject(object, isChildren)
    frameInspect.ClearDisabledMouseFrames()
    frameInspect.inspectingFrame = object
    onFocusTexture:SetColorTexture(0, 0, 0, 0)
    onFocusText:SetText("")
    frameInspect.MoveInspectIndicators(object, isChildren)
    --doesn't need to update the information object as it is already updated from the preview

    if (isChildren) then
        frameInspect.MainFrame.childrenScrollBox.RefreshChildren(object)
    end
end

function frameInspect.StopInspectingFrame()
    frameInspect.inspectingFrame = false
    frameInspect.ClearInformationFrame()
    frameInspect.MainFrame.childrenScrollBox.RefreshChildren()
end

function frameInspect.StartPreviewingObject(object, isChildren)
    frameInspect.focusFrame = object
    frameInspect.UpdateInformationFrame(object)
    frameInspect.MoveInspectIndicators(object)
    frameInspect.ShowFocusTexture(object)

    --don't refresh children while previewing a children or it will preview until there's no more children to preview
    if (not isChildren) then
        frameInspect.MainFrame.childrenScrollBox.RefreshChildren(object)
    end
end

function frameInspect.InspectThisObject(object)
    frameInspect.StartPreviewingObject(object)
    frameInspect.StartInspectingObject(object)
end

function frameInspect.ClearDisabledMouseFrames()
    for index, frameTable in ipairs(currentMouseDisabledFrames) do
        local frame = frameTable.frame
        local originalAlpha = frameTable.originalAlpha
        frame:EnableMouse(true)
        frame:SetAlpha(originalAlpha)
    end
    wipe(currentMouseDisabledFrames)
end

local listenKeyInputs = function(self, key)
    if (frameInspect.GetInspectingObject()) then
        if (key == "F4") then
            --stop the inspecting
            frameInspect.StopInspectingFrame()
        end
        return
    end

    local previewObject = frameInspect.GetPreviewingObject()
    if (previewObject) then
        if (key == "F4") then
            frameInspect.StartInspectingObject(previewObject)

        elseif (key == "LALT" and not frameInspect.IsFrameStackEnabled()) then
            previewObject:EnableMouse(false)
            local alpha = previewObject:GetAlpha()
            local newAlpha = alpha / 2
            previewObject:SetAlpha(newAlpha)

            currentMouseDisabledFrames[#currentMouseDisabledFrames+1] = {frame = previewObject, originalAlpha = alpha}

            --save mouse position to reset this when the mouse moves
            local mouseX, mouseY = GetCursorPosition()
            frameInspect.mouseX = mouseX
            frameInspect.mouseY = mouseY

            frameInspect.nextOnUpdateTick = GetTime() + 0.1
        end
    end
end

function frameInspect.CanInspectObject(object)
    if (object and object.GetName) then
        local objectName = object:GetName()
        if (objectName and objectName:find("FrameInspect")) then
            return false

        elseif (object == UIParent) then
            return false

        elseif (not objectName) then
            return true
        end
    else
        return false
    end
    return true
end

function frameInspect.IsNamePlate(frame)
    if (frame and frame.GetName) then
        local frameName = frame:GetName()
        if (frameName) then
            if (frameName:find("NamePlate")) then
                return true
            end
        else
            local frameParent = frame:GetParent()
            if (frameParent) then
                return frameInspect.IsNamePlate(frameParent)
            end
        end
    end
end

local getFrameUnderMouse = function()
    return GetMouseFocus()
end

--OnUpdate callback
local onUpdateRoutine = function(self, deltaTime)
    if (frameInspect.nextOnUpdateTick > GetTime()) then
        return
    end
    frameInspect.nextOnUpdateTick = GetTime() + 0.1

    --if not inspecting any frame, preview the object on mouse focus
    if (not frameInspect.GetInspectingObject()) then
        local objectUnderMousePointer

        local isFrameStackEnabled = frameInspect.IsFrameStackEnabled()
        if (isFrameStackEnabled) then
            local frameStackObject = _G.fsobj
            if (frameStackObject) then
                if (not frameStackObject:IsProtected()) then
                    local frameName = frameStackObject:GetName()
                    if (not frameName or not frameName:find("NamePlate")) then
                        objectUnderMousePointer = frameStackObject
                    else
                        objectUnderMousePointer = getFrameUnderMouse()
                    end
                else
                    objectUnderMousePointer = getFrameUnderMouse()
                end
            else
                objectUnderMousePointer = getFrameUnderMouse()
            end
        else
            objectUnderMousePointer = getFrameUnderMouse()
        end

        --if there's nothing on mouse focus, clear the information shown
        if (not objectUnderMousePointer or objectUnderMousePointer == UIParent or objectUnderMousePointer == WorldFrame) then
            frameInspect.ClearInformationFrame()
            frameInspect.ClearDisabledMouseFrames()
            frameInspect.ClearChildrenFrame()
            return
        end

        --don't inspect our own frames or nameplates
        local frameName = objectUnderMousePointer:GetName()
        if (frameName and (frameName:find("FrameInspect") or frameName:find("NamePlate"))) then
            frameInspect.ClearInformationFrame()
            frameInspect.ClearChildrenFrame()
            return
        end

        local currentPreviewObject = frameInspect.GetPreviewingObject()

        --change the preview object if there's a different object under the mouse focus
        if (objectUnderMousePointer ~= currentPreviewObject) then
            frameInspect.StartPreviewingObject(objectUnderMousePointer)
        else
            --no object under the mouse
            if (not currentPreviewObject or objectUnderMousePointer ~= currentPreviewObject) then
                frameInspect.ClearInformationFrame()
                frameInspect.ClearDisabledMouseFrames()
                frameInspect.ClearChildrenFrame()
                return
            end
        end

        --if the mouse moved while cycling among frames pressing ALT, reset the cycle
        local mouseX, mouseY = GetCursorPosition()
        if (frameInspect.mouseX ~= mouseX and frameInspect.mouseY ~= mouseY) then
            frameInspect.ClearDisabledMouseFrames()
        end
    end
end

--get the first anchor point point of a frame
local getAnchorData = function(frame, dataIndex)
    if (frameInspect.IsNamePlate(frame)) then
        if (dataIndex == 2) then
            return "-this object has no points-"
        end
        local data = {"", {}, "", 0, 0}
        return data[dataIndex]
    end

    if (frame:GetNumPoints() == 0) then
        local data = {"", {}, "", 0, 0}
        if (dataIndex == 2) then
            return "-this object has no points-"
        end
        return data[dataIndex]
    end

    local anchorSide, anchorFrame, anchorFrameSide, anchorOffsetX, anchorOffsetY = frame:GetPoint(1)
    anchorOffsetX = DF:TruncateNumber(anchorOffsetX, 3) --attempt to compare number with nil
    anchorOffsetY = DF:TruncateNumber(anchorOffsetY, 3)
    local data = {anchorSide, anchorFrame, anchorFrameSide, anchorOffsetX, anchorOffsetY}

    if (dataIndex == 2) then --anchorFrame is a table
        local frameName = data[dataIndex] and data[dataIndex]:GetName() or "-no name-"
        return frameName
    else
        return data[dataIndex]
    end
end

--set the first anchor point of the inspecting frame
local setAnchorData = function(value, dataIndex)
    local inspectingFrame = frameInspect.GetInspectingObject()
    if (not inspectingFrame) then
        return
    end

    local anchorSide, anchorFrame, anchorFrameSide, anchorOffsetX, anchorOffsetY = inspectingFrame:GetPoint(1)
    local data = {anchorSide, anchorFrame, anchorFrameSide, anchorOffsetX, anchorOffsetY}
    data[dataIndex] = value

    if (inspectingFrame:GetNumPoints() == 1) then
        inspectingFrame:ClearAllPoints()
    end

    inspectingFrame:SetPoint(unpack(data))
end

local getBackdropData = function(frame, dataIndex)
    local backdrop
    if (not frame.GetBackdrop) then
        backdrop = {}
    else
        backdrop = frame:GetBackdrop()
    end

    if (not backdrop) then
        backdrop = {}
    end

    if (dataIndex == 1) then
        return backdrop.bgFile or ""

    elseif (dataIndex == 2) then
        return backdrop.edgeFile or ""

    elseif (dataIndex == 3) then
        return backdrop.edgeSize or 0

    elseif (dataIndex == 4) then --color
        if (not frame.GetBackdrop) then
            return {0, 0, 0, 0}
        end
        local r, g, b, a = frame:GetBackdropColor()
        return {r, g, b, a}

    elseif (dataIndex == 5) then --color
        if (not frame.GetBackdrop) then
            return {0, 0, 0, 0}
        end
        local r, g, b, a = frame:GetBackdropBorderColor()
        return {r, g, b, a}
    end
end

local setBackdropData = function(value, dataIndex, r, g, b, a)
    local frame = frameInspect.GetInspectingObject()
    if (not frame.GetBackdrop) then
       Mixin(frame, BackdropTemplateMixin)
    end

    local backdrop = frame:GetBackdrop()
    if (not backdrop) then
        frame:SetBackdrop({bgFile = "", edgeFile = "", edgeSize = 0})
        backdrop = frame:GetBackdrop()
    end

    local bgR, bgG, bgB, bgA = frame:GetBackdropColor()
    local borderR, borderG, borderB, borderA = frame:GetBackdropBorderColor()

    if (dataIndex >= 1 and dataIndex <= 3) then
        if (dataIndex == 1) then
            backdrop.bgFile = value
            frame:SetBackdrop(backdrop)

        elseif (dataIndex == 2) then
            backdrop.edgeFile = value
            frame:SetBackdrop(backdrop)

        elseif (dataIndex == 3) then
            backdrop.edgeSize = value
            frame:SetBackdrop(backdrop)
        end

        frame:SetBackdropColor(bgR, bgG, bgB, bgA)
        frame:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    else
        if (dataIndex == 4) then
            frame:SetBackdropColor(r, g, b, a)

        elseif (dataIndex == 5) then
            frame:SetBackdropBorderColor(r, g, b, a)
        end
    end
end

local getTexCoord = function(texture, side)
    local atlasName = texture:GetAtlas()
    if (atlasName) then
        local atlasInfo = C_Texture.GetAtlasInfo(atlasName)
        if (side == "left") then
            return DF:TruncateNumber(atlasInfo.leftTexCoord, 6)
        elseif (side == "right") then
            return DF:TruncateNumber(atlasInfo.rightTexCoord, 6)
        elseif (side == "top") then
            return DF:TruncateNumber(atlasInfo.topTexCoord, 6)
        elseif (side == "bottom") then
            return DF:TruncateNumber(atlasInfo.bottomTexCoord, 6)
        end
    else
        local left, right, top, bottom = texture:GetTexCoord()
        if (side == "left") then
            return DF:TruncateNumber(left, 6)
        elseif (side == "right") then
            return DF:TruncateNumber(right, 6)
        elseif (side == "top") then
            return DF:TruncateNumber(top, 6)
        elseif (side == "bottom") then
            return DF:TruncateNumber(bottom, 6)
        end
    end
end

local setTexCoord = function(texture, side, value)
    local left, right, top, bottom = texture:GetTexCoord()
    if (side == "left") then
        texture:SetTexCoord(value, right, top, bottom)

    elseif (side == "right") then
        texture:SetTexCoord(left, value, top, bottom)

    elseif (side == "top") then
        texture:SetTexCoord(left, right, value, bottom)

    elseif (side == "bottom") then
        texture:SetTexCoord(left, right, top, value)
    end
end

local getFunctionName = function(functionObject)
    local mixinPath = frameInspect.GetMixinFunctionAddress(functionObject)
    if (mixinPath) then
        return mixinPath
    end

    local functionMap = frameInspect.GetFunctionMap()
    local functionGlobalName = functionMap[tostring(functionObject)]
    if (functionGlobalName) then
        return functionGlobalName
    end

    local address = tostring(functionObject)
    return address
end

function frameInspect.GetDefaultValue(line)
    return frameInspect.DefaultValues[line.name]
end

--when inspecting a new frame, save the value as default value for the line, maybe more stuff can be added here in the future
--color values are passed as table{r, g, b, a}
local canSetAsDefault = function(object, value, line, setAsDefault)
    if (setAsDefault) then
        if (value == nil) then
            value = "nil"
        end
        frameInspect.DefaultValues[line.name] = value
    end

    return value
end

function frameInspect.GetNamePath(object, path)
    local parentObject = object:GetParent()
    if (parentObject ~= _G.UIParent) then
        local parentKey = object:GetParentKey()
        if (parentKey) then
            path = parentKey .. "." .. path
            return frameInspect.GetNamePath(parentObject, path)
        end
    else
        path = (object:GetName() or "$parent") .. "." .. path
    end
    return path:gsub(".$", "")
end

local getObjectName = function(object)
    local name = object:GetName()
    if (not name) then
        local path = frameInspect.GetNamePath(object, "")
        if (path == "") then
            local parentObject = object:GetParent()
            local parentKey = object:GetParentKey()
            if (parentKey) then
                local parentName = parentObject:GetName()
                if (parentName) then
                    name = parentName .. "." .. parentKey
                else
                    name = "$parent." .. parentKey
                end
            end
        else
            return path
        end
    end
    return name or tostring(object) or "nil"
end

--to add new entry: add the information on the table below

--Frame Texture
local hasTextFilter = {EditBox = true, FontString = true}
local frameFilter = {Frame = true, Slider = true, Button = true, CheckButton = true, EditBox = true, Minimap = true, StatusBar = true, PlayerModel = true, ScrollFrame = true}
local textureFilter = {Texture = true, MaskTexture = true}
local fontStringFilter = {FontString = true}
local buttonFilter = {Button = true}
local sliderFilter = {Slider = true}
local notForAnimationFilter = {Frame = true, Slider = true, Button = true, CheckButton = true, EditBox = true, Minimap = true, StatusBar = true, PlayerModel = true, Texture = true, MaskTexture = true, ScrollFrame = true, FontString = true}
local animationGroupFilter = {AnimationGroup = true}
local animationFilter = {Rotation = true, Alpha = true, Translation = true, Scale = true}
local animationAlphaFilter = {Alpha = true}
local animationTranslationFilter = {Translation = true}
local animationRotationFilter = {Rotation = true}
local animationScaleFilter = {Scale = true}
local animationWithOriginFilter = {Scale = true, Rotation = true}

--all information displayed in the frame info (read only table)
frameInspect.PropertiesList = {
    {name = "Name", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, getObjectName(frame), line, setAsDefault) end,   funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},
    {name = "Object Type", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetObjectType() or "-Unknown-", line, setAsDefault) end,   funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},
    {name = "Parent", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetParent() and frame:GetParent():GetName() or "-parent has no name-", line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetParent(value) end, type = "text"},

    {name = "OnClick()", funcGet = function(frame, line, setAsDefault) return canSetAsDefault(frame, getFunctionName(frame:GetScript("OnClick")), line, setAsDefault) end, filter = buttonFilter, funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},

    {name = "Is Shown", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:IsShown(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetShown(value) end, type = "boolean", filter = notForAnimationFilter},

    {name = "Width", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, DF:TruncateNumber(frame:GetWidth(), 3), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetWidth(value) end, type = "number", filter = notForAnimationFilter, scaleBy = 5},
    {name = "Height", funcGet = function(frame, line, setAsDefault) return canSetAsDefault(frame, DF:TruncateNumber(frame:GetHeight(), 3), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetHeight(value) end, type = "number", filter = notForAnimationFilter, scaleBy = 5},
    {name = "Scale", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, DF:TruncateNumber(frame:GetScale(), 3), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetScale(value) end, type = "number", filter = notForAnimationFilter, scaleBy = 0.7, clamp = {0.1, 6}},
    {name = "Alpha", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, DF:TruncateNumber(frame:GetAlpha(), 3), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetAlpha(value) end, type = "number", filter = notForAnimationFilter, scaleBy = 0.7, clamp = {0, 1}},
    {name = "Alpha (Effective)", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, DF:TruncateNumber(frame:GetEffectiveAlpha(), 3), line, setAsDefault) end,   funcSet = function(value) --[[read only]] end, readOnly = true, type = "text", filter = frameFilter},
    {name = "Anchor Side", funcGet =  function(frame, line, setAsDefault) local value = getAnchorData(frame, 1) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setAnchorData(value, 1) end, type = "anchor", filter = notForAnimationFilter},
    {name = "Anchor Frame", funcGet =  function(frame, line, setAsDefault) local value = getAnchorData(frame, 2) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setAnchorData(value, 2) end, type = "text", filter = notForAnimationFilter},
    {name = "Anchor Frame Side", funcGet =  function(frame, line, setAsDefault) local value = getAnchorData(frame, 3) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setAnchorData(value, 3) end, type = "anchor", filter = notForAnimationFilter},
    {name = "Anchor Offset X", funcGet =  function(frame, line, setAsDefault) local value = getAnchorData(frame, 4) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setAnchorData(value, 4) end, type = "number", filter = notForAnimationFilter, scaleBy = 5},
    {name = "Anchor Offset Y", funcGet =  function(frame, line, setAsDefault) local value = getAnchorData(frame, 5) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setAnchorData(value, 5) end, type = "number", filter = notForAnimationFilter, scaleBy = 5},
    {name = "Strata", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetFrameStrata(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetFrameStrata(value) end, type = "text", filter = frameFilter},
    {name = "Level", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetFrameLevel(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetFrameLevel(value) end, type = "number", filter = frameFilter, isInteger = true, clamp = {0, 9999}},

    {name = "Backdrop Texture", funcGet =  function(frame, line, setAsDefault) local value = getBackdropData(frame, 1) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setBackdropData(value, 1) end, type = "text", filter = frameFilter},
    {name = "Backdrop Color", funcGet =  function(frame, line, setAsDefault) local value = getBackdropData(frame, 4) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(r, g, b, a) setBackdropData(false, 4, r, g, b, a) end, type = "color", filter = frameFilter},
    {name = "Border Texture", funcGet =  function(frame, line, setAsDefault) local value = getBackdropData(frame, 2) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setBackdropData(value, 2) end, type = "text", filter = frameFilter},
    {name = "Border Size", funcGet =  function(frame, line, setAsDefault) local value = getBackdropData(frame, 3) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(value) setBackdropData(value, 3) end, type = "number", filter = frameFilter, scaleBy = 0.8},
    {name = "Border Color", funcGet =  function(frame, line, setAsDefault) local value = getBackdropData(frame, 5) return canSetAsDefault(frame, value, line, setAsDefault) end, funcSet = function(r, g, b, a) setBackdropData(false, 5, r, g, b, a) end, type = "color", filter = frameFilter},

    {name = "Value", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetValue(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetValue(value) end, type = "text", filter = sliderFilter},
    {name = "Min Value", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, select(1, frame:GetMinMaxValues()), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetMinMaxValues(value, select(2, frameInspect.GetInspectingObject():GetMinMaxValues())) end, type = "text", filter = sliderFilter},
    {name = "Max Value", funcGet =  function(frame, line, setAsDefault) return canSetAsDefault(frame, select(2, frame:GetMinMaxValues()), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetMinMaxValues(select(1, frameInspect.GetInspectingObject():GetMinMaxValues()), value) end, type = "text", filter = sliderFilter},

    {name = "Text", funcGet = function(frame, line, setAsDefault) return canSetAsDefault(frame, frame:GetText(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetText(value) end, type = "text", filter = hasTextFilter},
    {name = "Font Size", funcGet = function(frame, line, setAsDefault) local _, fontHeight = frame:GetFont(); return canSetAsDefault(frame, fontHeight, line, setAsDefault) end, funcSet = function(value) local fontName, fontHeight, fontFlags = frameInspect.GetInspectingObject():GetFont() frameInspect.GetInspectingObject():SetFont(fontName, value, fontFlags) end, type = "number", filter = hasTextFilter},
    {name = "Font Name", funcGet = function(frame, line, setAsDefault) local fontName = frame:GetFont(); return canSetAsDefault(frame, fontName, line, setAsDefault) end, funcSet = function(value) local fontName, fontHeight, fontFlags = frameInspect.GetInspectingObject():GetFont() frameInspect.GetInspectingObject():SetFont(value, fontHeight, fontFlags) end, type = "text", filter = hasTextFilter},
    {name = "Font Flags", funcGet = function(frame, line, setAsDefault) local _, _, fontFlags = frame:GetFont(); fontFlags = fontFlags or "NONE" return canSetAsDefault(frame, fontFlags, line, setAsDefault) end, funcSet = function(value) local fontName, fontHeight, fontFlags = frameInspect.GetInspectingObject():GetFont() frameInspect.GetInspectingObject():SetFont(fontName, fontHeight, value) end, type = "text", filter = hasTextFilter},
    {name = "Font Color", funcGet =  function(frame, line, setAsDefault) local r, g, b, a = frame:GetTextColor() return canSetAsDefault(frame, {r, g, b, a}, line, setAsDefault) end, funcSet = function(r, g, b, a) frameInspect.GetInspectingObject():SetTextColor(r, g, b, a) end, type = "color", filter = hasTextFilter},

    {name = "Texture", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, texture:GetTextureFilePath(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetTexture(value) end, type = "text", filter = textureFilter},
    {name = "Atlas", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, texture:GetAtlas(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetAtlas(value) end, type = "text", filter = textureFilter},
    {name = "Draw Layer", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, texture:GetDrawLayer(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetDrawLayer(value) end, type = "text", filter = textureFilter},
    {name = "Sub Level", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, select(2, texture:GetDrawLayer()), line, setAsDefault) end, funcSet = function(value) local drawLayer = frameInspect.GetInspectingObject():GetDrawLayer(); frameInspect.GetInspectingObject():SetDrawLayer(drawLayer, value) end, type = "text", filter = textureFilter},
    {name = "TexCoord Left", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, getTexCoord(texture, "left"), line, setAsDefault) end, funcSet = function(value) setTexCoord(frameInspect.GetInspectingObject(), "left", value) end, type = "number", filter = textureFilter},
    {name = "TexCoord Right", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, getTexCoord(texture, "right"), line, setAsDefault) end, funcSet = function(value) setTexCoord(frameInspect.GetInspectingObject(), "right", value) end, type = "number", filter = textureFilter},
    {name = "TexCoord Top", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, getTexCoord(texture, "top"), line, setAsDefault) end, funcSet = function(value) setTexCoord(frameInspect.GetInspectingObject(), "top", value) end, type = "number", filter = textureFilter},
    {name = "TexCoord Bottom", funcGet = function(texture, line, setAsDefault) return canSetAsDefault(texture, getTexCoord(texture, "bottom"), line, setAsDefault) end, funcSet = function(value) setTexCoord(frameInspect.GetInspectingObject(), "bottom", value) end, type = "number", filter = textureFilter},

    --animation group
    {name = "Looping", funcGet = function(animationGroup, line, setAsDefault) return canSetAsDefault(animationGroup, animationGroup:GetLooping(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetLooping(value) end, type = "text", filter = animationGroupFilter},
    {name = "Loop State", funcGet = function(animationGroup, line, setAsDefault) return canSetAsDefault(animationGroup, animationGroup:GetLoopState(), line, setAsDefault) end, funcSet = function(value) --[[read only]] end, readOnly = true, type = "text", filter = animationGroupFilter},
    {name = "Duration", funcGet = function(animationGroup, line, setAsDefault) return canSetAsDefault(animationGroup, animationGroup:GetDuration(), line, setAsDefault) end, funcSet = function(value) --[[read only]] end, readOnly = true, type = "number", filter = animationGroupFilter},
    {name = "To Final Alpha", funcGet = function(animationGroup, line, setAsDefault) return canSetAsDefault(animationGroup, animationGroup:IsSetToFinalAlpha(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetToFinalAlpha(value) end, type = "boolean", filter = animationGroupFilter},
    {name = "Speed Multiplier", funcGet = function(animationGroup, line, setAsDefault) return canSetAsDefault(animationGroup, animationGroup:GetAnimationSpeedMultiplier(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetAnimationSpeedMultiplier(value) end, type = "number", filter = animationGroupFilter},

    --all animations
    {name = "Target", funcGet =  function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetTarget() and animation:GetTarget():GetName() or "-target has no name-", line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetTarget(value) end, type = "text", filter = animationFilter},
    {name = "Duration", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, DF:TruncateNumber(animation:GetDuration(), 3), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetDuration(value) end, type = "number", filter = animationFilter},
    {name = "Start Delay", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetStartDelay(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetStartDelay(value) end, type = "number", filter = animationFilter},
    {name = "End Delay", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetEndDelay(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetEndDelay(value) end, type = "number", filter = animationFilter},
    {name = "Smoothing", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetSmoothing(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():GetSmoothing(value) end, type = "text", filter = animationFilter},
    {name = "Order", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetOrder(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetOrder(value) end, type = "number", filter = animationFilter},

    --alpha animation
    {name = "From Alpha", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetFromAlpha(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetFromAlpha(value) end, type = "number", filter = animationAlphaFilter},
    {name = "To Alpha", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetToAlpha(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetToAlpha(value) end, type = "number", filter = animationAlphaFilter},

    --translation animation
    {name = "Offset X", funcGet = function(animation, line, setAsDefault) local x = animation:GetOffset() return canSetAsDefault(animation, DF:TruncateNumber(x, 6), line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() local _, y = animation:GetOffset() animation:SetOffset(value, y) end, type = "number", filter = animationTranslationFilter},
    {name = "Offset Y", funcGet = function(animation, line, setAsDefault) local _, y = animation:GetOffset() return canSetAsDefault(animation, DF:TruncateNumber(y, 6), line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() local x = animation:GetOffset() animation:SetOffset(x, value) end, type = "number", filter = animationTranslationFilter},

    --rotation animation
    {name = "Degrees", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, DF:TruncateNumber(animation:GetDegrees(), 6), line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() animation:SetDegrees(value) end, type = "number", filter = animationRotationFilter},
    {name = "Radians", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, DF:TruncateNumber(animation:GetRadians(), 6), line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() animation:SetRadians(value) end, type = "number", filter = animationRotationFilter},

    --scale animation
    {name = "From Scale", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetScaleFrom(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetScaleFrom(value) end, type = "number", filter = animationScaleFilter},
    {name = "To Scale", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, animation:GetScaleTo(), line, setAsDefault) end, funcSet = function(value) frameInspect.GetInspectingObject():SetScaleTo(value) end, type = "number", filter = animationScaleFilter},

    --scale and translation origin point
    {name = "Origin Point", funcGet = function(animation, line, setAsDefault) local origin, x, y = animation:GetOrigin() return canSetAsDefault(animation, origin, line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() local origin, x, y = animation:GetOrigin() animation:SetOrigin(value, x, y) end, type = "text", filter = animationWithOriginFilter},
    {name = "Origin X", funcGet =  function(animation, line, setAsDefault) local origin, x, y = animation:GetOrigin() return canSetAsDefault(animation, x, line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() local origin, x, y = animation:GetOrigin() animation:SetOrigin(origin, value, y) end, type = "number", filter = animationWithOriginFilter},
    {name = "Origin Y", funcGet =  function(animation, line, setAsDefault) local origin, x, y = animation:GetOrigin() return canSetAsDefault(animation, y, line, setAsDefault) end, funcSet = function(value) local animation = frameInspect.GetInspectingObject() local origin, x, y = animation:GetOrigin() animation:SetOrigin(origin, x, value) end, type = "number", filter = animationWithOriginFilter},

    --animation scripts
    {name = "OnPlay()", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, getFunctionName(animation:GetScript("OnPlay")), line, setAsDefault) end, filter = animationFilter, funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},
    {name = "OnFinished()", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, getFunctionName(animation:GetScript("OnFinished")), line, setAsDefault) end, filter = animationFilter, funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},
    {name = "OnUpdate()", funcGet = function(animation, line, setAsDefault) return canSetAsDefault(animation, getFunctionName(animation:GetScript("OnUpdate")), line, setAsDefault) end, filter = animationFilter, funcSet = function(value) --[[read only]] end, readOnly = true, type = "text"},
}

--this table store the text entries for each of the information declared above
frameInspect.FramesHoldingValues = {}
frameInspect.AllLines = {}

--run when the user press enter on a text entry, it'll apply all values of all text entries
function frameInspect.ApplyValues(line)
    local lineId = line.lineId
    if (lineId) then
        if (line:IsShown()) then
            local textEntry = line.textEntry
            local colorPicker = line.colorPicker
            local adjustmentSlider = line.adjustmentSlider
            local booleanDropdown = line.booleanDropdown
            local funcSet = line.funcSet

            --if no funcSet is found in this line, it means the line is not in use (line content filtered or more lines than content to show)
            if (funcSet) then
                if (line.type == "color") then
                    local r, g, b, a = colorPicker:GetColor()
                    funcSet(r, g, b, a)

                elseif (line.type == "boolean") then
                    local value =  line:GetCurrentValue()
                    funcSet(value)

                else
                    local value = textEntry.text
                    local isString = value
                    local isNumber = tonumber(isString)
                    line:SetCurrentValue(isNumber and isNumber or isString)
                    funcSet(line:GetCurrentValue())
                end
            end
        end
    else
        print("NO LINE ID FOUND TO function ApplyValues()")
    end
end

--when click on the far right button, reset a single value to its default value
function frameInspect.ResetDefault(line)
    local defaultValue = frameInspect.GetDefaultValue(line)

    --print(line.text:GetText(), defaultValue)

    if (line.type == "text") then
        line.textEntry.text = defaultValue

    elseif (line.type == "number") then
        line.textEntry.text = defaultValue

    elseif (line.type == "color") then
        local r, g, b, a = DF:ParseColors(defaultValue)
        line.textEntry.text = DF:FormatColor("commastring", r, g, b, a, 3)
        line.colorPicker:SetColor(r, g, b, a)

    elseif (line.type == "anchor") then
        line.textEntry.text = defaultValue
        line.anchorPointDropdown:Select(defaultValue)

    elseif (line.type == "boolean") then
        line.booleanDropdown:Select(defaultValue and 1 or 2, true) --select by index as selecting 'false' trigger another thing
    end

    line.funcSet(defaultValue)
end

--start inspecting the parent of the object being inspected, called when the button after the parent field is pressed
function frameInspect.BackToParent()
    --inspect the parent
    if (frameInspect.GetInspectingObject()) then
        local objectParent = frameInspect.GetInspectingObject():GetParent()
        if (frameInspect.CanInspectObject(objectParent)) then
            frameInspect.StartPreviewingObject(objectParent)
            frameInspect.StartInspectingObject(objectParent)
        end
    else
        frameInspect:Msg("no object currently under inspection.")
    end
end

--create the main frame where a frame attributes is shown
function frameInspect.CreateInformationFrame()
    --already created the screen frame
    if (frameInspect.bHasCreatedScreenPanel) then
        frameInspect.MainFrame:Show()
        return
    end

    --create the main frame
    local mainFrame = DF:CreateSimplePanel(UIParent, frameInspect.FrameSettings.width, frameInspect.FrameSettings.height, "Frame Inspect", "FrameInspectMainWindow", {NoTUISpecialFrame = true})
    mainFrame:SetPoint("center", UIParent, "center", 0, 0)
    mainFrame:SetFrameStrata("FULLSCREEN")
    frameInspect.MainFrame = mainFrame

    frameInspect.lockOnFrameLabel = DF:CreateLabel(mainFrame, "PRESS F4 TO LOCK/UNLOCK ON FRAME")
    frameInspect.lockOnFrameLabel.color = "white"
    frameInspect.lockOnFrameLabel.fontsize = 12
    frameInspect.lockOnFrameLabel:SetPoint("center", 0, 0)

    mainFrame:SetScript("OnKeyDown", listenKeyInputs)
    mainFrame:SetPropagateKeyboardInput(true)

    --disable the buil-in mouse integration of the simple panel, doing this to use LibWindow-1.1 as the window management
    mainFrame:SetScript("OnMouseDown", nil)
    mainFrame:SetScript("OnMouseUp", nil)

    mainFrame:SetScript("OnHide", function()
        if (frameInspect.GetInspectingObject()) then
            frameInspect.StopInspectingFrame()
        end
        frameInspect.ClearInformationFrame()
        frameInspect.StopInspecting()
    end)

    --register in the libWindow
    local LibWindow = LibStub("LibWindow-1.1")
    local config = frameInspect.GetConfig()
    LibWindow.RegisterConfig(mainFrame, config.main_frame)
    LibWindow.MakeDraggable(mainFrame)
    LibWindow.RestorePosition(mainFrame)

    --mainFrame:ClearAllPoints() --reset position
    --mainFrame:SetPoint("center", UIParent, "center", 0, 0)
    --LibWindow.SavePosition(mainFrame)

    --scale bar
    local scaleBar = DF:CreateScaleBar(mainFrame, config.frame_scale)
    mainFrame:SetScale(config.frame_scale.scale)

    --status bar
    local statusBar = DF:CreateStatusBar(mainFrame)
    statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormal")
    statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
    statusBar.text:SetText("An addon by Terciob | Built with Details! Framework")
    DF:SetFontSize(statusBar.text, 11)
    DF:SetFontColor(statusBar.text, "gray")

    --create the frame which show the children of the frame being inspected
    frameInspect.CreateChildrenFrame()

    local refreshPropertiesLinesScroll = function(self, data, offset, totalLines)
        --local data = frameInspect.FrameInfoLines
        local object = frameInspect.focusChild or frameInspect.focusFrame

        --reset the value of funcSet on all lines
        local allLines = frameInspect.MainFrame.PropertiesScrollBox:GetLines()
        for lineIndex = 1, #allLines do
            local line = allLines[lineIndex]
            line.textEntry.funcSet = nil
        end

        frameInspect.lockOnFrameLabel:Hide()

        --update the scroll
        local nextLineIndex = 1
        for i = 1, totalLines do
            local index = i + offset
            local lineInfo = data[index]
            if (lineInfo) then
                local filters = lineInfo.filter
                local passFilter = true
                if (filters) then
                    local objType = object:GetObjectType()
                    if (not filters[objType]) then
                        passFilter = false
                    end
                end

                if (passFilter) then
                    local line = self:GetLine(nextLineIndex)
                    nextLineIndex = nextLineIndex + 1
                    line.text:SetText(lineInfo.name)
                    line.type = lineInfo.type
                    line.name = lineInfo.name
                    line:SetLineInfo(lineInfo)

                    local textEntry = line.textEntry
                    local colorPicker = line.colorPicker
                    local adjustmentSlider = line.adjustmentSlider
                    local anchorPointDropdown = line.anchorPointDropdown

                    local funcGet = lineInfo.funcGet
                    local setDefaults = line.object ~= object
                    local value = funcGet(object, line, setDefaults)

                    line.colorPicker:Hide()
                    line.backToParentButton:Hide()
                    line.booleanDropdown:Hide()
                    line.anchorPointDropdown:Hide()
                    line.adjustmentSlider:Hide()

                    if (line.type == "text") then
                        if (type(value) == "table" and line.name == "Texture") then
                            --texture is a texture object
                            value = value:GetTexture()
                        end

                        textEntry.text = value or "nil"
                        textEntry:SetWidth(frameInspect.FrameSettings.width - frameInspect.FrameSettings.frame_info_text2_x - 30)

                        if (lineInfo.name == "Parent") then
                            line.backToParentButton:Show()
                            textEntry:SetWidth(frameInspect.FrameSettings.width - frameInspect.FrameSettings.frame_info_text2_x - 50)
                        end

                    elseif (line.type == "color") then
                        textEntry.text = DF:FormatColor("commastring", value)
                        textEntry:SetWidth(frameInspect.FrameSettings.frame_info_text2_width + 50)
                        colorPicker:SetColor(value)
                        colorPicker:Show()

                    elseif (line.type == "number") then
                        textEntry.text = value
                        textEntry:SetWidth(frameInspect.FrameSettings.frame_info_text2_width)
                        adjustmentSlider:Show()
                        adjustmentSlider:SetScaleFactor(lineInfo.scaleBy)

                    elseif (line.type == "anchor") then
                        textEntry.text = value
                        textEntry:SetWidth(frameInspect.FrameSettings.frame_info_text2_width)
                        anchorPointDropdown:Show()
                        anchorPointDropdown:Select(value:upper())

                    elseif (line.type == "boolean") then
                        line.booleanDropdown:Show()
                        line.booleanDropdown:Select(value and 1 or 2, true) --select by index as selecting 'false' trigger another thing
                        textEntry.text = value and "true" or "false"
                        textEntry:SetWidth(frameInspect.FrameSettings.frame_info_text2_width)
                    end

                    line:SetCurrentValue(value)
                    textEntry:SetCursorPosition(0)
                    textEntry.funcSet = lineInfo.funcSet
                    line.funcSet = lineInfo.funcSet
                    line.object = object

                    if (lineInfo.readOnly) then
                        textEntry:SetTemplate(DF:GetTemplate("dropdown", "FRAMEINSPECT_DISABLED_TEXTFIELD"))
                        textEntry.isReadOnly = true
                        colorPicker:Disable()
                        adjustmentSlider:Disable()
                    else
                        textEntry:SetTemplate(options_dropdown_template)
                        textEntry.isReadOnly = nil
                        colorPicker:Enable()
                        adjustmentSlider:Enable()
                    end
                end
            end
        end
    end

    --scroll containing the frame properties
    local propertiesScrollBox = DF:CreateScrollBox(mainFrame, "$parentScrollBox", refreshPropertiesLinesScroll, frameInspect.PropertiesList, frameInspect.FrameSettings.scroll_width, frameInspect.FrameSettings.scroll_height, frameInspect.FrameSettings.scroll_line_amount, frameInspect.FrameSettings.scroll_line_height)
    DF:ReskinSlider(propertiesScrollBox)
    propertiesScrollBox:SetPoint("topleft", mainFrame, "topleft", frameInspect.FrameSettings.frame_info_x-3, frameInspect.FrameSettings.scroll_y)
    mainFrame.PropertiesScrollBox = propertiesScrollBox

    local anchorPointOptions = {
        {value = "TOP", label = "TOP", onclick = function()end, icon = [[Interface\Buttons\Arrow-Up-Up]], texcoord = {0, 0.8125, 0.1875, 0.875}},
        {value = "BOTTOM", label = "BOTTOM", onclick = function()end, icon = [[Interface\Buttons\Arrow-Up-Up]], texcoord = {0, 0.875, 1, 0.1875}},
        {value = "LEFT", label = "LEFT", onclick = function()end, icon = [[Interface\CHATFRAME\UI-InChatFriendsArrow]], texcoord = {0.5, 0, 0, 0.8125}},
        {value = "RIGHT", label = "RIGHT", onclick = function()end, icon = [[Interface\CHATFRAME\UI-InChatFriendsArrow]], texcoord = {0, 0.5, 0, 0.8125}},
        {value = "TOPLEFT", label = "TOPLEFT", onclick = function()end, icon = [[Interface\Buttons\UI-AutoCastableOverlay]], texcoord = {0.796875, 0.609375, 0.1875, 0.375}},
        {value = "BOTTOMLEFT", label = "BOTTOMLEFT", onclick = function()end, icon = [[Interface\Buttons\UI-AutoCastableOverlay]], texcoord = {0.796875, 0.609375, 0.375, 0.1875}},
        {value = "TOPRIGHT", label = "TOPRIGHT", onclick = function()end, icon = [[Interface\Buttons\UI-AutoCastableOverlay]], texcoord = {0.609375, 0.796875, 0.1875, 0.375}},
        {value = "BOTTOMRIGHT", label = "BOTTOMRIGHT", onclick = function()end, icon = [[Interface\Buttons\UI-AutoCastableOverlay]], texcoord = {0.609375, 0.796875, 0.375, 0.1875}},
        {value = "CENTER", label = "CENTER", onclick = function()end, icon = [[Interface\Buttons\UI-AutoCastableOverlay]], texcoord = {0.609375, 0.796875, 0.375, 0.1875}},
    }

    local booleanOptions = {
        {value = true, label = "TRUE", onclick = function()end},
        {value = false, label = "FALSE", onclick = function()end},
    }

    local propertyLineMixin = {
        GetLineInfo = function(self)
            return self.lineInfo
        end,

        SetLineInfo = function(self, lineInfo)
            self.lineInfo = lineInfo
        end,

        ClampValue = function(self, value)
            local lineInfo = self:GetLineInfo()

            local clamp = lineInfo.clamp
            if (clamp) then
                value = Clamp(value, unpack(clamp))
            end

            if (lineInfo.isInteger) then
                local currentValue = self:GetCurrentValue()
                --if the line was previously used by another type of value
                if (type(currentValue) ~= "number") then
                    return floor(value)
                else
                    if (value < currentValue) then
                        value = floor(value)
                    else
                        value = ceil(value)
                    end
                end
            end

            return value
        end,

        SetCurrentValue = function(self, value)
            value = self:ClampValue(value)
            self.currentValue = value
        end,

        GetCurrentValue = function(self)
            return self.currentValue
        end,
    }

    --create a grid of information about the frame selected
    local createPropertyLine = function(self, lineId)
        local lineHeight = frameInspect.FrameSettings.scroll_line_height

        local line = CreateFrame("frame", "$parentLine" .. lineId, self, "BackdropTemplate")
        DF:Mixin(line, propertyLineMixin)
        line.lineId = lineId

        line:SetPoint("topleft", mainFrame, "topleft", frameInspect.FrameSettings.frame_info_x, (lineHeight * lineId * -1) + frameInspect.FrameSettings.frame_info_y)
        line:SetPoint("topright", mainFrame, "topright", -frameInspect.FrameSettings.frame_info_x, (lineHeight * lineId * -1) + frameInspect.FrameSettings.frame_info_y)
        line:SetHeight(lineHeight)

        line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
        if (lineId % 2 == 0) then
            line:SetBackdropColor(.2, .2, .2, 0.5)
        else
            line:SetBackdropColor(.3, .3, .3, 0.5)
        end

        --property name
        local text = line:CreateFontString("$parentText1", "artwork", "GameFontNormal")
        text:SetPoint("left", line, "left", 2, 0)
        DF:SetFontSize(text, 10)

        --reset to default value
        local resetDefaultButton = DF:CreateButton(line, function() frameInspect.ResetDefault(line) end, lineHeight, lineHeight, "", -1, _, _, _, "FrameInspectDefaultButton" .. lineId)
        resetDefaultButton:SetPoint("right", line, "right", -2, 0)
        resetDefaultButton:SetIcon([[Interface\BUTTONS\UI-RotationRight-Button-Up]], 20, 20, "overlay", {.2, .8, .2, .8}, false, false, false, false, true)

        --back to parent button
        local backToParentButton = DF:CreateButton(line, function() frameInspect.BackToParent() end, lineHeight, lineHeight, "", -1, _, _, _, "FrameInspectBackToParentButton" .. lineId)
        backToParentButton:SetPoint("right", resetDefaultButton, "left", -2, 0)
        backToParentButton:SetIcon([[Interface\GLUES\CharacterSelect\Glue-Char-Up]], 20, 20, "overlay", {.2, .8, .2, .8}, false, false, false, false, true)
        backToParentButton:Hide()

        --text entry for text values
        local textEntryCallback = function()
            if (line.textEntry.isReadOnly) then
                frameInspect.ResetDefault(line)
                return
            end

            if (line.type == "color") then
                local r, g, b, a = DF:ParseColors(line.textEntry.text)
                if (r and g and b and a) then
                    line.colorPicker:SetColor(r, g, b, a)
                    line:SetCurrentValue({r, g, b, a})
                end

            elseif (line.type == "number") then
                line:SetCurrentValue(tonumber(line.textEntry.text))

            elseif (line.type == "anchor") then
                for i = 1, #anchorPointOptions do
                    if (anchorPointOptions[i].label == line.textEntry.text:upper()) then
                        line.anchorPointDropdown:Select(i, true)
                    end
                end
                line:SetCurrentValue(line.textEntry.text)

            elseif (line.type == "boolean") then
                local text = line.textEntry.text
                text = text:lower()
                local value = text == "true" and true or false
                line.booleanDropdown:Select(value and 1 or 2, true) --select by index as selecting 'false' trigger another thing
                line:SetCurrentValue(value)

            else
                line:SetCurrentValue(line.textEntry.text)
            end

            frameInspect.ApplyValues(line)
        end

        local textEntry = DF:CreateTextEntry(line, textEntryCallback, frameInspect.FrameSettings.frame_info_text2_width, lineHeight, _, "FrameInspectTextEntry" .. lineId, _, options_dropdown_template)
        textEntry.lineId = lineId
        textEntry:SetPoint("left", line, "left", frameInspect.FrameSettings.frame_info_text2_x, 0)
        textEntry:SetJustifyH("left")
        textEntry:SetTextInsets(3, 3, 0, 0)
        frameInspect.FramesHoldingValues[lineId] = textEntry

        --adjustment slider for numbers
        local onSliderAdjustedValueChanged = function(scalarX, scalarY, isLiteral, thisLine)
            local line = thisLine
            local currentValue = line:GetCurrentValue()
            local adjustmentSlider = thisLine.adjustmentSlider

            --if isLiteral is true the value is always a -1 or 1
            --if not literal, it's a normalized value from -1 to 1
            if (isLiteral) then
                currentValue = currentValue + scalarX
                currentValue = floor(currentValue)
            else
                if (currentValue < 0) then
                    scalarX = scalarX * -1

                elseif(currentValue == 0) then
                    --if the current value is zero, it won't move
                    --set an initial value for the current value
                    if (scalarX < 0) then
                        currentValue = -0.05
                        scalarX = scalarX * -1
                    elseif (scalarX > 0) then
                        currentValue = 0.05
                    end
                end

                local valueToAdd = currentValue * 0.10 * scalarX --change a total of 10% each tick at full scalar value
                if (valueToAdd < 0 and valueToAdd > -0.005) then
                    valueToAdd = -0.005
                end

                currentValue = currentValue + valueToAdd
                currentValue = DF:TruncateNumber(currentValue, 3)
            end

            line:SetCurrentValue(currentValue)
            line.textEntry.text = line:GetCurrentValue()

            --print(GetTime(), currentValue) current value not updating correctly when moving the X axis
            frameInspect.ApplyValues(line)
        end

        function mainFrame.sliderAdjustmentCallback(self, scalarX, scalarY, isLiteral)
            if (line.name == "Anchor Offset X") then
                onSliderAdjustedValueChanged(scalarX, scalarY, isLiteral, line)

                --edit the other axis using the other scalar value
                if (not isLiteral) then
                    local allLines = frameInspect.MainFrame.PropertiesScrollBox:GetLines()
                    for lineIndex = 1, #allLines do
                        --attempt to find using the line name
                        local thisLine = allLines[lineIndex]
                        if (thisLine.name == "Anchor Offset Y") then
                            onSliderAdjustedValueChanged(scalarY, 0, isLiteral, thisLine)
                        end
                    end
                end

            elseif (line.name == "Anchor Offset Y") then
                onSliderAdjustedValueChanged(isLiteral and scalarX or scalarY, scalarX, isLiteral, line)

                --edit the other axis using the other scalar value
                if (not isLiteral) then
                    local allLines = frameInspect.MainFrame.PropertiesScrollBox:GetLines()
                    for lineIndex = 1, #allLines do
                        --attempt to find using the line name
                        local thisLine = allLines[lineIndex]
                        if (thisLine.name == "Anchor Offset X") then
                            onSliderAdjustedValueChanged(scalarX, 0, isLiteral, thisLine)
                        end
                    end
                end

            else
                onSliderAdjustedValueChanged(scalarX, scalarY, isLiteral, line)
            end
        end

        local adjustmentSlider = DF:CreateAdjustmentSlider(line, mainFrame.sliderAdjustmentCallback, {}, "$parentAdjustSlider")
        adjustmentSlider:SetPoint("left", textEntry.widget, "right", 10, 0)
        adjustmentSlider.lineId = lineId

        --color picker
        local colorPickerCallback = function(self, r, g, b, a)
            textEntry.text = DF:FormatColor("commastring", r, g, b, a, 3)
            frameInspect.ApplyValues(line)
        end

        local colorPicker = DF:CreateColorPickButton(line, "$parentColorPicker", _, colorPickerCallback, 1, DF:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
        colorPicker:SetSize(20, 20)
        colorPicker:SetPoint("left", textEntry.widget, "right", 10, 0)
        colorPicker.lineId = lineId

        --anchor selection dropdown
        local anchorPointCallback = function(_, _, anchorSide)
            textEntry.text = anchorSide
            frameInspect.ApplyValues(line)
        end
        local generatedAnchorOptions = {}
        for i = 1, #anchorPointOptions do
            local anchorPointOption = DF.table.copy({}, anchorPointOptions[i])
            anchorPointOption.onclick = anchorPointCallback
            generatedAnchorOptions[#generatedAnchorOptions+1] = anchorPointOption
        end

        local anchorPointDropdown = DF:CreateDropDown(line, function() return generatedAnchorOptions end, 1, 120, 20, nil, "$parentAnchorDropdown")
        anchorPointDropdown:SetTemplate(options_dropdown_template)
        anchorPointDropdown:SetPoint("left", textEntry.widget, "right", 10, 0)
        anchorPointDropdown.lineId = lineId

        --boolean selector
        local booleanSelectorCallback = function(_, _, value)
            textEntry.text = value and "true" or "false"
            line:SetCurrentValue(value)
            frameInspect.ApplyValues(line)
        end
        local generatedBooleanOptions = {}
        for i = 1, #booleanOptions do
            local booleanOption = DF.table.copy({}, booleanOptions[i])
            booleanOption.onclick = booleanSelectorCallback
            generatedBooleanOptions[#generatedBooleanOptions+1] = booleanOption
        end

        local booleanDropdown = DF:CreateDropDown(line, function() return generatedBooleanOptions end, 1, 120, 20, nil, "$parentBooleanDropdown")
        booleanDropdown:SetTemplate(options_dropdown_template)
        booleanDropdown:SetPoint("left", textEntry.widget, "right", 10, 0)
        booleanDropdown.lineId = lineId

        --register members
        line.text = text
        line.textEntry = textEntry
        line.resetDefaultButton  = resetDefaultButton
        line.backToParentButton  = backToParentButton
        line.adjustmentSlider  = adjustmentSlider
        line.colorPicker  = colorPicker
        line.anchorPointDropdown = anchorPointDropdown
        line.booleanDropdown = booleanDropdown

        frameInspect.AllLines[lineId] = line

        line:Hide()
        return line
    end

    --create the scrollbox lines
    for i = 1, frameInspect.FrameSettings.scroll_line_amount do
        propertiesScrollBox:CreateLine(createPropertyLine, i)
    end

    --create the mouse over routine
    frameInspect.nextOnUpdateTick = GetTime() + 0.1
    mainFrame:SetScript("OnUpdate", function(self, deltaTime)
        return onUpdateRoutine(self, deltaTime)
    end)

    frameInspect.bHasCreatedScreenPanel = true
end

--refresh the information shown about the object on preview or inspect
function frameInspect.UpdateInformationFrame(object)
    local dataToShow = {}

    if (not object) then
        print("deebug: there's no object to show")
        return
    end

    local objType = object:GetObjectType()

    for i = 1, #frameInspect.PropertiesList do
        local lineInfo = frameInspect.PropertiesList[i]
        local filters = lineInfo.filter
        local passFilter = true
        if (filters) then
            if (not filters[objType]) then
                passFilter = false
            end
        end

        if (passFilter) then
            dataToShow[#dataToShow+1] = lineInfo
        end
    end

    frameInspect.MainFrame.PropertiesScrollBox:SetData(dataToShow)
    frameInspect.MainFrame.PropertiesScrollBox:Refresh()
end

--when a frame lose inspectin focus, clear all information for it
function frameInspect.ClearInformationFrame()
    local allLines = frameInspect.MainFrame.PropertiesScrollBox:GetLines()
    local totalLines = #allLines

    for lineId = 1, totalLines do
        local line = allLines[lineId]
        line.textEntry.text = ""
        line.textEntry.funcSet = nil
        line.text:SetText("")
        line:Hide()
    end

    frameInspect.lockOnFrameLabel:Show()

    onFocusTexture:ClearAllPoints()
    frameInspect.focusFrame = false
    onFocusText:SetText("F4: Inspect")
    hideOnFocusTexture()
    wipe(frameInspect.DefaultValues)
end