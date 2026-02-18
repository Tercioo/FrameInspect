
local addonName, frameInspect = ...
local _

--load Details! Framework
---@type detailsframework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

function frameInspect.ShowRunWindow(parent)
    ---@type df_luaeditor
    local codeEditor = DF:NewSpecialLuaEditorEntry(parent, parent:GetWidth(), 60, "CodeEditor", "$parentCodeEditor", false, true)
    codeEditor:SetPoint("topleft", parent, "bottomleft", 0, 0)
    codeEditor:SetPoint("topright", parent, "bottomright", 0, 0)
    codeEditor.scroll:SetBackdrop(nil)
    codeEditor.editbox:SetBackdrop(nil)
    codeEditor:SetBackdrop(nil)
    DF:ReskinSlider(codeEditor.scroll)

    if (not codeEditor.__background) then
        codeEditor.__background = codeEditor:CreateTexture(nil, "background")
    end

    codeEditor:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
    codeEditor:SetBackdropBorderColor(0, 0, 0, 1)

    local r, g, b, a = DF:GetDefaultBackdropColor()
    codeEditor.__background:SetColorTexture(r, g, b, 0.94)
    codeEditor.__background:SetVertexColor(r, g, b, 0.94)
    codeEditor.__background:SetAlpha(0.8)
    codeEditor.__background:SetVertTile(true)
    codeEditor.__background:SetHorizTile(true)
    codeEditor.__background:SetAllPoints()

    --fontstring in the bottomleft with .5.5.5 color and .5 alpha saying "Press Shift+Enter to run code"
    local infoLabel = DF:CreateLabel(codeEditor, "Press Shift+Enter to run code, self is the inspecting object", 10, "silver")
    infoLabel:SetPoint("bottomleft", codeEditor, "bottomleft", 5, 5)
    infoLabel:SetAlpha(0.7)

    codeEditor.editbox:HookScript("OnEnterPressed", function()
        --don't lose the focus of the editor when shift pressed
        if (_G.IsShiftKeyDown()) then
            local code = codeEditor:GetText()
            code = DF:Trim(code)
            FrameInspectInspectingObject = frameInspect.GetInspectingObject()
            code = "local self = FrameInspectInspectingObject;\n" .. code

            local eachLine = DF:SplitTextInLines(code)
            local lastLine = eachLine[#eachLine]

            --if the two latest character are () then add a return in front
            local len = #lastLine
            if (len > 2) then
                local lastTwo = lastLine:sub(len - 1, len)
                if (lastTwo == "()") then
                    lastLine = "return " .. lastLine
                end
            end

            --rebuild the code with the modified last line
            eachLine[#eachLine] = lastLine
            code = table.concat(eachLine, "\n")

            --compile the code
            local func, err = loadstring(code)
            if (not func) then
                print("|cFFFF0000FrameInspect: error compiling code:|r " .. err)
                return
            end

            --execute the compiled code
            local success, runtimeError = pcall(func)
            if (not success) then
                print("|cFFFF0000FrameInspect: error running code:|r " .. runtimeError)
            end

            print(runtimeError)
        else
            codeEditor.editbox:Insert("\n")
        end
    end)
end