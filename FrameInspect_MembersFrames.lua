
local addonName, frameInspect = ...
local _

--load Details! Framework
---@type detailsframework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

---@class membersdata
---@field key string|number|table
---@field value any
---@field valueType string
---@field priority number

local CONST_MEMBER_NAME_COLOR = "orange"

function frameInspect.ClearMemberFrame()
    local mainFrame = frameInspect.MainFrame
    local childrenFrame = mainFrame.childrenScrollBox

    childrenFrame:SetData({})
    childrenFrame:Refresh()
end

function frameInspect.CreateMembersFrame()
    local mainFrame = frameInspect.MainFrame

    --right panel (show members for the frame)
    local childrenFrame = CreateFrame("button", "$parentMembersFrame", mainFrame, "BackdropTemplate")
    childrenFrame:SetSize(frameInspect.FrameSettings.children_width, frameInspect.FrameSettings.height)
    childrenFrame:SetPoint("topleft", mainFrame, "topright", 0, 0)
    childrenFrame:SetFrameStrata("FULLSCREEN")
    childrenFrame:SetBackdrop(mainFrame:GetBackdrop())
    childrenFrame:SetBackdropColor(mainFrame:GetBackdropColor())
    childrenFrame:SetBackdropBorderColor(mainFrame:GetBackdropBorderColor())
    frameInspect.MembersFrame = childrenFrame

    local widgetsTab = DF:CreateTabButton(mainFrame, "$parentMembersTab")
    widgetsTab:SetPoint("left", mainFrame.widgetsTab, "right", 2, 0)
    widgetsTab:SetSize(80, 20)
    widgetsTab:SetText("Members")
    widgetsTab:SetScript("OnClick", function()
        frameInspect.ShowMembersFrame()
    end)
    mainFrame.membersTab = widgetsTab

    widgetsTab:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true, insets = {left = 1, right = 1, top = 1, bottom = 1}})
    widgetsTab:SetBackdropColor(0.1, 0.1, 0.1, 1)

    widgetsTab.LeftTexture:SetVertexColor(0.1, 0.1, 0.1)
    widgetsTab.MiddleTexture:SetVertexColor(0.1, 0.1, 0.1)
    widgetsTab.RightTexture:SetVertexColor(0.1, 0.1, 0.1)
    widgetsTab.SelectedTexture:SetVertexColor(1, 1, 1, 0.5)
    widgetsTab.SelectedTexture:SetScale(1.2)

    local rightClickHelpText = DF:CreateLabel(childrenFrame, "right click: back to parent", 14, "white", "GameFontNormal")
    rightClickHelpText:SetPoint("bottom", childrenFrame, "bottom", 0, 5)

    childrenFrame:SetScript("OnClick", function(self, mouseButton)
        if (mouseButton == "RightButton") then
            --go up
            frameInspect.BackToParent()
        end
    end)

    --end part

    local refreshChildrenScroll = function(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            ---@type membersdata
            local memberTable = data[index]
            if (memberTable) then
                local line = self:GetLine(i)
                line.childObject = memberTable

                if (memberTable.valueType == "table") then
                    line.icon:SetTexture([[Interface\AddOns\FrameInspect\Images\icon_table.tga]], nil, nil, "TRILINEAR")
                    line.memberName.text = memberTable.key
                    line.valueText.text = "table"

                elseif (memberTable.valueType == "boolean") then
                    line.icon:SetTexture([[Interface\AddOns\FrameInspect\Images\icon_bool.tga]], nil, nil, "TRILINEAR")
                    line.memberName.text = memberTable.key
                    line.valueText.text = memberTable.value and "True" or "False"

                elseif (memberTable.valueType == "string") then
                    line.icon:SetTexture([[Interface\AddOns\FrameInspect\Images\icon_string.tga]], nil, nil, "TRILINEAR")
                    line.memberName.text = memberTable.key
                    line.valueText.text = memberTable.value

                elseif (memberTable.valueType == "number") then
                    line.icon:SetTexture([[Interface\AddOns\FrameInspect\Images\icon_number.tga]], nil, nil, "TRILINEAR")
                    line.memberName.text = memberTable.key
                    line.valueText.text = tostring(memberTable.value)

                elseif (memberTable.valueType == "function") then
                    line.icon:SetTexture([[Interface\AddOns\FrameInspect\Images\icon_function.tga]], nil, nil, "TRILINEAR")
                    line.memberName.text = memberTable.key
                    line.valueText.text = "function"
                end

                line.icon.texcoord = {0, 1, 0, 1}
            end
        end
    end

    --scroll containing the frames showing the frame's children
    local childrenScrollBox = DF:CreateScrollBox(childrenFrame, "$parentMembersScrollBox", refreshChildrenScroll, {}, frameInspect.FrameSettings.children_scroll_width, frameInspect.FrameSettings.scroll_height+42, frameInspect.FrameSettings.children_scroll_line_amount, frameInspect.FrameSettings.children_scroll_line_height)
    DF:ReskinSlider(childrenScrollBox)
    childrenScrollBox:SetPoint("topleft", childrenFrame, "topleft", frameInspect.FrameSettings.frame_info_x-3, 0)
    mainFrame.membersScrollBox = childrenScrollBox
    childrenScrollBox:SetScript("OnMouseDown", function(self, mouseButton)
        if (mouseButton == "RightButton") then
            --go up
            frameInspect.BackToParent()
        end
    end)

    childrenScrollBox:Hide()

    function childrenScrollBox.RefreshChildren(object)
        childrenScrollBox.frameUnderInspection = object

        if (object) then
            local members = {}

            for key, value in pairs (object) do
                local valueType = type(value)
                if (valueType == "table") then
                    if (not value.GetObjectType) then
                        DF.table.addunique(members, {key = key, value = value, valueType = valueType, priority = 2})
                    end

                elseif (valueType == "function" or valueType == "number" or valueType == "string" or valueType == "boolean") then
                    local priority = (valueType == "function" and 1) or (valueType == "string" and 3) or (valueType == "number" and 4) or (valueType == "boolean" and 5)
                    DF.table.addunique(members, {key = key, value = value, valueType = valueType, priority = priority})
                end
            end

            childrenFrame.currentParent = object

            table.sort(members, function(a, b)
                return a.priority > b.priority
            end)

            childrenScrollBox:SetData(members)
            childrenScrollBox:Refresh()
        else
            --no object is under inspection, clear the children scroll
            childrenScrollBox:SetData({})
            childrenScrollBox:Refresh()
        end
    end

    local createChildrenFrame = function(self, lineId)
        local lineHeight = frameInspect.FrameSettings.children_scroll_line_height

        local line = CreateFrame("button", "$parentLine" .. lineId, self, "BackdropTemplate")
        --line:SetScript("OnClick", onClickLine)
        --line:SetScript("OnEnter", onEnterLine)
        --line:SetScript("OnLeave", onleaveLine)
        --line:RegisterForClicks("LeftButtonDown", "RightButtonDown")
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

        --value
        --local valueText = DF:CreateLabel(line, "", 10, "silver", "GameFontNormal", "valueText", "$parentValueText", "artwork")
        local valueTextEntry = DF:CreateTextEntry(line, function()end, frameInspect.FrameSettings.children_button_width - 4 - lineHeight, 18, "valueText", "$parentValueText")
        valueTextEntry:SetPoint("left", icon, "right", 2, -9)
        valueTextEntry:SetTemplate(DF:GetTemplate("dropdown", "FRAMEINSPECT_MEMBERS_TEXTFIELD"))
        do
            local highlightTexture = DF:CreateImage(valueTextEntry.widget, "white", 1, 1, "highlight", {0, 1, 0, 1}, "highlight", "$parentHighlight")
            highlightTexture:SetAllPoints(line)
            highlightTexture.alpha = 0.1
        end

        --member name
        local memberNameTextEntry = DF:CreateTextEntry(line, function()end, frameInspect.FrameSettings.children_button_width - 4 - lineHeight, 18, "memberName", "$parentMemberName")
        memberNameTextEntry:SetPoint("left", icon, "right", 2, 9)
        memberNameTextEntry:SetTemplate(DF:GetTemplate("dropdown", "FRAMEINSPECT_MEMBERS_TEXTFIELD"))
        do
            local highlightTexture = DF:CreateImage(memberNameTextEntry.widget, "white", 1, 1, "highlight", {0, 1, 0, 1}, "highlight", "$parentHighlight")
            highlightTexture:SetAllPoints(line)
            highlightTexture.alpha = 0.1
        end

        --highlight texture
        local highlightTexture = DF:CreateImage(line, "white", 1, 1, "highlight", {0, 1, 0, 1}, "highlight", "$parentHighlight")
        highlightTexture:SetAllPoints()
        highlightTexture.alpha = 0.1

        return line
    end

    --create the scrollbox lines
    for i = 1, frameInspect.FrameSettings.children_scroll_line_amount do
        childrenScrollBox:CreateLine(createChildrenFrame)
    end

end