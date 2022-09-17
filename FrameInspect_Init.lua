--[=[
    done: 
        
    bugs:
        - (desativei mostrar texturas e fontstrings pra resolver os 2 problemas a cima primeiro) resolver novos bugs criados pois agora esta motrando texturas e fontstrings na lista de children
    next:
        - botão para escolher um novo parent
        - dropdown pra escolher a strata
        - adicionar drawlayer pra texturas e fontstrings
        - adicionar o level da draw layer pra texturas e fontstrings
        - criar o painel da direita mostrando as children do frame
--]=]




local addonName, frameInspect = ...

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local default_config = {
    --frame table for LibWindow
    main_frame = {},
    frame_scale = {scale = 1},
}

frameInspect.bIsInspecting = false
frameInspect.ValueTable = {} --store a list of widgets containing values of the frame info
frameInspect.DefaultValues = {} --store the original values of the frame

frameInspect.FrameSettings = {
    width = 450,
    height = 500,
    scroll_width = 424,
    scroll_height = 455,
    scroll_line_amount = 22,
    scroll_line_height = 20,
    scroll_y = -25,
    frame_info_x = 5, --where the frame info starts
    frame_info_y = -10,
    frame_info_text2_x = 130, --where the text entry starts  (x offset from the start of the line)
    frame_info_text2_width = 120, --size of the text entry

    children_width = 222,
    children_button_width = 190,
    children_scroll_width = 196,
    children_scroll_line_amount = 12,
    children_scroll_line_height = 40,
}

frameInspect.inspectingFrame = false
frameInspect.focusFrame = false

local settingsScrollBox = frameInspect.FrameSettings.settingsScrollBox
local codeEditorFrameSettings = frameInspect.FrameSettings.settingsCodeEditor
local buttonsFrameSettings = frameInspect.FrameSettings.settingsButtons
local optionsFrameSettings = frameInspect.FrameSettings.settingsOptionsFrame

function frameInspect.OnInit()
    DF:Embed(frameInspect)
end


function frameInspect.StartInspecting()
    frameInspect.CreateInformationFrame()
    frameInspect.bIsInspecting = true
end

function frameInspect.StopInspecting()
    frameInspect.MainFrame:Hide()
    frameInspect.bIsInspecting = false
end

SLASH_FRAMEINSPECT1 = "/finspect"
SLASH_FRAMEINSPECT2 = "/frameinspect"
SLASH_FRAMEINSPECT3 = "/fi"

function SlashCmdList.FRAMEINSPECT(msg, editbox)
    if (not frameInspect.bIsInspecting) then
        frameInspect.StartInspecting()
    else
        frameInspect.StopInspecting()
    end
end

local handleSavedVariablesFrame = CreateFrame("frame")
handleSavedVariablesFrame:RegisterEvent("ADDON_LOADED")
handleSavedVariablesFrame:RegisterEvent("PLAYER_LOGIN")
handleSavedVariablesFrame:RegisterEvent("PLAYER_LOGOUT")

handleSavedVariablesFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
        local thisAddonName = ...
        if (thisAddonName == addonName) then
            FrameInspectDB = FrameInspectDB or {}
            DF.table.deploy(FrameInspectDB, default_config)
        end

    elseif (event == "PLAYER_LOGIN") then
        frameInspect.OnInit()

    elseif (event == "PLAYER_LOGOUT") then

    end
end)

--return a table with the addon settings
function frameInspect.GetConfig()
    return FrameInspectDB
end

