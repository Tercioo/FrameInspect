local addonName, frameInspect = ...
local _

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local CONST_MEMBER_NAME_COLOR = "orange"

local getMemberNameInParentFrame = function(parentFrame, child)
    for memberName, value in pairs(parentFrame) do
        if (value == child) then
            return "." .. memberName, CONST_MEMBER_NAME_COLOR
        end
    end

    local parentObjectType = parentFrame:GetObjectType()
    if (parentObjectType == "StatusBar") then
        local childObjectType = child:GetObjectType()
        if (childObjectType == "Texture") then
            if (parentFrame:GetStatusBarTexture() == child) then
                return "StatusBar Texture", "olive"
            end
        end
    end

    local childName = child:GetName()
    if (childName) then
        return "_G." .. childName, CONST_MEMBER_NAME_COLOR
    end

    local memoryAddress = tostring(child)
    memoryAddress = memoryAddress:gsub("table%: ", "")
    return memoryAddress, CONST_MEMBER_NAME_COLOR
end

function frameInspect.ClearChildrenFrame()
    local mainFrame = frameInspect.MainFrame
    local childrenFrame = mainFrame.childrenScrollBox

    childrenFrame:SetData({})
    childrenFrame:Refresh()
end

function frameInspect.CreateChildrenFrame()
    local mainFrame = frameInspect.MainFrame

    --right panel (show children for the frame)
    local childrenFrame = CreateFrame("button", "$parentChildrenFrame", mainFrame, "BackdropTemplate")
    childrenFrame:SetSize(frameInspect.FrameSettings.children_width, frameInspect.FrameSettings.height)
    childrenFrame:SetPoint("topleft", mainFrame, "topright", 0, 0)
    childrenFrame:SetFrameStrata("FULLSCREEN")
    childrenFrame:SetBackdrop(mainFrame:GetBackdrop())
    childrenFrame:SetBackdropColor(mainFrame:GetBackdropColor())
    childrenFrame:SetBackdropBorderColor(mainFrame:GetBackdropBorderColor())

    local rightClickHelpText = DF:CreateLabel(childrenFrame, "right click: back to parent", 11, "white", "GameFontNormal")
    rightClickHelpText:SetPoint("bottom", childrenFrame, "bottom", 0, 5)

    childrenFrame:SetScript("OnClick", function(self, mouseButton)
        if (mouseButton == "RightButton") then
            --go up
            frameInspect.BackToParent()
        end
    end)

    local objectTypeIsAnimation = function(objectType)
        return objectType == "Alpha" or objectType == "Scale" or objectType == "Translation" or objectType ==  "Rotation"
    end

    local refreshChildrenScroll = function(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local object = data[index]
            if (object) then
                local line = self:GetLine(i)
                local objectType = object:GetObjectType()

                line.icon.texture = {0, 1, 0, 1}
                local memberName, memberColor
                if (objectTypeIsAnimation(objectType)) then
                    memberName, memberColor = getMemberNameInParentFrame(object:GetTarget():GetParent(), object:GetTarget())
                else
                    memberName, memberColor = getMemberNameInParentFrame(self.frameUnderInspection, object)
                end

                line.valueText.text = ""
                line.memberName.text = memberName
                line.memberName.color = memberColor

                line.currentParent = childrenFrame.currentParent

                line.hiddenText:SetShown(object.IsShown and not object:IsShown())
                line.icon.texcoord = {0, 1, 0, 1}

                if (line.icon.currentPlayingAnimationPreview) then
                    line.icon.currentPlayingAnimationPreview:Stop()
                    line.icon.currentPlayingAnimationPreview = nil
                end

                if (objectType == "Texture") then
                    local setFromAtlas = false
                    local atlasName = object:GetAtlas()
                    if (atlasName) then
                        local atlasInfo = C_Texture.GetAtlasInfo(atlasName)
                        if (atlasInfo) then
                            line.icon:SetAtlas(atlasName)
                            line.valueText:SetTextTruncated(atlasName, frameInspect.FrameSettings.children_scroll_line_max_texture_name_length)
                            setFromAtlas = true
                        end
                    end

                    if (not setFromAtlas) then
                        line.icon.texture = object:GetTexture()
                        line.icon:SetTexCoord(object:GetTexCoord())
                        line.valueText:SetTextTruncated(object:GetTexture(), frameInspect.FrameSettings.children_scroll_line_max_texture_name_length)
                    end

                elseif (objectType == "FontString") then
                    line.valueText.text = object:GetText()
                    line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_string]]

                elseif (objectType == "EditBox") then
                    line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_editbox]]
                    line.valueText.text = object:GetText()

                elseif (objectType == "Button") then
                    line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_button]]

                elseif (objectType == "AnimationGroup") then
                    line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_animation_group]]

                elseif (objectType == "Alpha") then --Animation
                    line.valueText.text = "Alpha"
                    local returnValue = line.icon:SetAnimation(object)
                    if (not returnValue) then
                        line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_animation_alpha]]
                    end

                elseif (objectType == "Translation") then --Animation
                    line.valueText.text = "Translation"
                    local returnValue = line.icon:SetAnimation(object)
                    if (not returnValue) then
                        line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_animation_translation]]
                    end

                elseif (objectType == "Rotation") then --Animation
                    line.valueText.text = "Rotation"
                    local returnValue = line.icon:SetAnimation(object)
                    if (not returnValue) then
                        line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_animation_rotation]]
                    end

                elseif (objectType == "Scale") then --Animation
                    line.valueText.text = "Scale"
                    local returnValue = line.icon:SetAnimation(object)
                    if (not returnValue) then
                        line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_animation_scale]]
                    end
                else
                    line.icon.texture = [[Interface\AddOns\FrameInspect\Images\icon_frame]]

                end

                line.childObject = object
            end
        end
    end

    --scroll containing the frames showing the frame's children
    local childrenScrollBox = DF:CreateScrollBox(childrenFrame, "$parentChildrenScrollBox", refreshChildrenScroll, {}, frameInspect.FrameSettings.children_scroll_width, frameInspect.FrameSettings.scroll_height+42, frameInspect.FrameSettings.children_scroll_line_amount, frameInspect.FrameSettings.children_scroll_line_height)
    DF:ReskinSlider(childrenScrollBox)
    childrenScrollBox:SetPoint("topleft", childrenFrame, "topleft", frameInspect.FrameSettings.frame_info_x-3, 0)
    mainFrame.childrenScrollBox = childrenScrollBox
    childrenScrollBox:SetScript("OnMouseDown", function(self, mouseButton)
        if (mouseButton == "RightButton") then
            --go up
            frameInspect.BackToParent()
        end
    end)

    local ignoredObjectTypes = {
        --["AnimationGroup"] = true,
        --["Animation"] = true,
        ["Font"] = true,
    }

    function childrenScrollBox.RefreshChildren(object)
        childrenScrollBox.frameUnderInspection = object

        if (object) then
            local objects = {}

            if (object.GetChildren) then
                local children = {object:GetChildren()}
                DF.table.append(objects, children)
            end

            if (object.GetRegions) then
                local regions = {object:GetRegions()} --textures, fontstrings, etc...
                DF.table.append(objects, regions)
            end

            if (object.GetAnimations) then
                local animations = {object:GetAnimations()}
                DF.table.append(objects, animations)
            end

            for memberName, memberValue in pairs(object) do
                if (type(memberValue) == "table") then
                    if (memberValue.GetObjectType) then
                        local objType = memberValue:GetObjectType()
                        if (not ignoredObjectTypes[objType]) then
                            local childName = memberValue:GetName()
                            if (not childName or not childName:find("FrameInspect")) then
                                DF.table.addunique(objects, memberValue)
                            end
                        end
                    end
                end
            end

            childrenFrame.currentParent = object
            childrenScrollBox:SetData(objects)
            childrenScrollBox:Refresh()
        else
            --no object is under inspection, clear the children scroll
            childrenScrollBox:SetData({})
            childrenScrollBox:Refresh()
        end
    end

    local onClickMouseXPos = 0
    local onClickMouseYPos = 0
    local onEnterTime = 0
    local onLeaveTime = 0

    local onClickLine = function(line, mouseButton)
        if (mouseButton == "LeftButton") then
            --inspect the children
            childrenScrollBox.lastSelectionTime = GetTime()
            frameInspect.StartInspectingObject(line.childObject, true)
            onClickMouseXPos, onClickMouseYPos = GetCursorPosition()

        elseif (mouseButton == "RightButton") then
            --go up
            frameInspect.BackToParent()
        end
    end
    local onEnterLine = function(line)
        if (frameInspect.CanInspectObject(line.childObject)) then
            local mouseX, mouseY = GetCursorPosition()

            --check if the mouse cursor ha moved since the latest click, this prevent to immediately start preview after clicked to inspect a children
            if (mouseX ~= onClickMouseXPos and mouseY ~= onClickMouseYPos) then
                --for some reason it's calling twice when entering, might be because of refreshing a second time the children list on start preview
                if (onEnterTime ~= GetTime()) then
                    frameInspect.StartPreviewingObject(line.childObject, true)
                    onEnterTime = GetTime()
                end
            end
        end

        local animationHub = line.icon.currentPlayingAnimationPreview
        if (animationHub) then
            animationHub:Play()
        end
    end
    local onleaveLine = function(line)
        --check if the OnLeave wasn't triggered by hidding the button because the child selected has no children
        if (childrenScrollBox.lastSelectionTime ~= GetTime()) then
            --start previewing the parent on next tick
            onLeaveTime = GetTime()
            --ensure to not start previewing the parent object if the cursor entered another line
            DF.Schedules.RunNextTick(function()
                if (onEnterTime < onLeaveTime) then
                    frameInspect.StartPreviewingObject(childrenFrame.currentParent)
                end
            end)
        end

        local animationHub = line.icon.currentPlayingAnimationPreview
        if (animationHub) then
            animationHub:Stop()
        end
    end

    --animationObject is the animation created from animationGroup:CreateAnimation()
    --self is the icon shown in the one of the frames of the childrenScrollBox
    local iconMethod_SetAndPlayAnimation = function(self, animationObject)
        --set the texture
        local animationTarget = animationObject:GetTarget()
        local targetAnimationObjectType = animationTarget and animationTarget.GetObjectType and animationTarget:GetObjectType()
        if (not targetAnimationObjectType or targetAnimationObjectType ~= "Texture") then
            return
        end

        local atlas = animationTarget:GetAtlas()
        if (atlas) then
            self:SetAtlas(atlas)
        else
            local texturePath = animationTarget:GetTexture()
            local left, right, top, bottom = animationTarget:GetTexCoord()
            self:SetTexture(texturePath)
            self:SetTexCoord(left, right, top, bottom)
        end

        local stringAddress = tostring(animationObject) --avoid setting the object to avoid affect weaktables and taint issues
        local animationHub = self.animations[stringAddress]
        if (not animationHub) then
            animationHub = self:CreateAnimationGroup()
            self.animations[stringAddress] = animationHub
            animationHub:SetLooping("REPEAT")

            --create the animation, an animation object always return its animationType when querying its objectType
            local animationType = animationObject:GetObjectType()
            local animation = animationHub:CreateAnimation(animationType)
            animationHub.animation = animation
            animationHub.animationType = animationType
        end

        local animation = animationHub.animation

        if (animationHub.animationType == "Alpha") then
            animation:SetFromAlpha(animationObject:GetFromAlpha())
            animation:SetToAlpha(animationObject:GetToAlpha())

        elseif (animationHub.animationType == "Rotation") then
            animation:SetOrigin(animationObject:GetOrigin())
            if (animationObject:GetDegrees() and animationObject:GetDegrees() ~= 0) then
                animation:SetDegrees(animationObject:GetDegrees())
            end
            if (animationObject:GetRadians() and animationObject:GetRadians() ~= 0) then
                animation:SetRadians(animationObject:GetRadians())
            end

        elseif (animationHub.animationType == "Scale") then
            animation:SetOrigin(animationObject:GetOrigin())
			animation:SetScaleFrom(animation:GetScaleFrom())
			animation:SetScaleTo(animation:GetScaleTo())

        elseif (animationHub.animationType == "Translation") then
            animation:SetOffset(animationObject:GetOffset())
        end

        animation:SetDuration(animationObject:GetDuration())
        --some animations isn't playing...
        --animationHub:Play()
        self.currentPlayingAnimationPreview = animationHub
        return animationHub
    end

    local createChildrenFrame = function(self, lineId)
        local lineHeight = frameInspect.FrameSettings.children_scroll_line_height

        local line = CreateFrame("button", "$parentLine" .. lineId, self, "BackdropTemplate")
        line:SetScript("OnClick", onClickLine)
        line:SetScript("OnEnter", onEnterLine)
        line:SetScript("OnLeave", onleaveLine)
        line:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        line:Hide()
        line.lineId = lineId

        line:SetPoint("topleft", childrenFrame, "topleft", frameInspect.FrameSettings.frame_info_x, (lineHeight * (lineId-1) * -1) -2)
        line:SetSize(frameInspect.FrameSettings.children_button_width, lineHeight)

        line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
        if (lineId % 2 == 0) then
            line:SetBackdropColor(.2, .2, .2, 0.5)
        else
            line:SetBackdropColor(.3, .3, .3, 0.5)
        end

        --icon to preview the texture
        local icon = DF:CreateImage(line, "", lineHeight-2, lineHeight-2, "artwork", {0, 1, 0, 1}, "icon", "$parentIcon")
        icon:SetPoint("left", line, "left", 2, 0)
        icon.animations = {}
        icon.SetAnimation = iconMethod_SetAndPlayAnimation

        --value
        local valueText = DF:CreateLabel(line, "", 10, "silver", "GameFontNormal", "valueText", "$parentValueText", "artwork")
        valueText:SetPoint("left", icon, "right", 2, 7)

        --member name
        local memberName = DF:CreateLabel(line, "", 10, CONST_MEMBER_NAME_COLOR, "GameFontNormal", "memberName", "$parentMemberName", "artwork")
        memberName:SetPoint("left", icon, "right", 2, -8)

        --is hidden text
        local isHiddenText = DF:CreateLabel(line, "hidden", 10, "gray", "GameFontNormal", "hiddenText", "$parentHiddenText", "artwork")
        isHiddenText:SetPoint("left", line, "right", -10, -22)
        isHiddenText.rotation = 90
        isHiddenText.alpha = 0.6

        --highlight texture
        local highlightTexture = DF:CreateImage(line, "white", 1, 1, "highlight", {0, 1, 0, 1}, "highlight", "$parentHighlight")
        highlightTexture:SetAllPoints()
        highlightTexture.alpha = 0.1
        return line
    end

    --create the scrollbox lines
    for i = 1, frameInspect.FrameSettings.children_scroll_line_amount do
        childrenScrollBox:CreateLine(createChildrenFrame, i)
    end
end