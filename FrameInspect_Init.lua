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
_G.FrameInspect = {}

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

    children_width = 242,
    children_button_width = 210,
    children_scroll_width = 216,
    children_scroll_line_amount = 12,
    children_scroll_line_height = 40,
    children_scroll_line_max_texture_name_length = 155,
}

frameInspect.inspectingFrame = false
frameInspect.focusFrame = false

DetailsFramework:InstallTemplate("dropdown", "FRAMEINSPECT_DISABLED_TEXTFIELD", {
	backdropcolor = {.3, .3, .3, .8},
}, "OPTIONS_DROPDOWN_TEMPLATE")

DF:InstallTemplate("dropdown", "FRAMEINSPECT_MEMBERS_TEXTFIELD", {
	backdrop = {
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		tileSize = 64,
		tile = true
	},

	backdropcolor = {0, 0, 0, .2},
	onentercolor = {0, 0, 0, .4},
	backdropbordercolor = {0, 0, 0, 0.2},
	onenterbordercolor = {0, 0, 0, 0.3},
})

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

local toggleWindow = function(bVisibility)
    if (type(bVisibility) == "boolean") then
        if (bVisibility) then
            frameInspect.StartInspecting()
        else
            frameInspect.StopInspecting()
        end
        return
    end

    if (not frameInspect.bIsInspecting) then
        frameInspect.StartInspecting()
    else
        frameInspect.StopInspecting()
    end
end

function SlashCmdList.FRAMEINSPECT(msg, editbox)
    toggleWindow()
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
        frameInspect.CreateMaps()
        frameInspect.OnInit()

    elseif (event == "PLAYER_LOGOUT") then

    end
end)

--[=[ /fstack sometimes does not trigger CVAR_UPDATE update
local handleRegularEventsFrame = CreateFrame("frame")
handleRegularEventsFrame:RegisterEvent("CVAR_UPDATE")
handleRegularEventsFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "CVAR_UPDATE") then
        frameInspect.frameStackIsEnabled = false
        local cVarName, value = ...
        print(cVarName, value)
        if (value == "1") then
            frameInspect.frameStackIsEnabled = true
        end
    end
end)--]=]

function frameInspect.IsFrameStackEnabled()
    local isEnabled = GetCVar("fstack_enabled") == "1"
    return isEnabled
end

--return a table with the addon settings
function frameInspect.GetConfig()
    return FrameInspectDB
end

function _G.FrameInspect.Inspect(UIElement)
    if (UIElement) then
        if (UIElement.GetObjectType) then
            toggleWindow(true)
            frameInspect.InspectThisObject(UIElement)
        end
    end
end

function frameInspect.CreateMaps()
    local mixinMap = {}
    local functionMap = {}

    for memberName, value in pairs(_G) do
        if (type(memberName) == "string") then
            if (memberName:match("Mixin$") and type(value) == "table") then
                local thisMixinTable = {}
                mixinMap[memberName] = thisMixinTable
                for mixinMemberName, object in pairs(value) do
                    if (type(mixinMemberName) == "string" and type(object) == "function") then
                        --don't assign the object itself to avoid a taint
                        thisMixinTable[mixinMemberName] = tostring(object)
                    end
                end

            elseif (type(value) == "function") then
                local address = tostring(value)
                functionMap[address] = memberName
            end
        end
    end

    frameInspect.mixinMap = mixinMap
    frameInspect.functionMap = functionMap
end

function frameInspect.GetMixinMap()
    return frameInspect.mixinMap
end

function frameInspect.GetFunctionMap()
    return frameInspect.functionMap
end

function frameInspect.GetMixinFunctionAddress(functionObject)
    local address = tostring(functionObject)
    if (address) then
        for mixinName, mixinTable in pairs(frameInspect.mixinMap) do
            for mixinMemberName, functionAddress in pairs(mixinTable) do
                if (address == functionAddress) then
                    return mixinName .. "." .. mixinMemberName
                end
            end
        end
    end
end