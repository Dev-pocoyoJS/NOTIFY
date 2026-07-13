--[[
    MidNight Hub - Join Server
    HUB simples: cola o PlaceId (em claro) + Jobid (ofuscado em base64),
    desofusca e dá TeleportToPlaceInstance.

    Também funciona com o "Or run this script!" do embed do Discord, que
    seta _G.MHUB_SERVER_ID = {placeId, jobIdOfuscado} antes de carregar
    este arquivo.
]]

-- ================= Carrega a Midnight Library =================
if getgenv().Library then
    getgenv().Library:Unload()
end

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/nightmereki-lab/TESTS/refs/heads/main/Library.lua"
))()

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================= Base64 decode (Lua puro) =================
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Decode(data)
    data = string.gsub(data, "[^" .. B64_CHARS .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64_CHARS:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

-- ================= Decode só do Jobid (1 camada: base64) =================
local function decodeJobId(obfuscated)
    local ok, jobId = pcall(base64Decode, obfuscated)
    if not ok or not jobId or jobId == "" then return nil end
    return jobId
end

-- ================= Teleport =================
local function JoinServer(placeIdStr, obfuscatedJobId, statusLabel)
    local placeId = tonumber(placeIdStr)
    local jobId = decodeJobId(obfuscatedJobId)

    if not placeId or not jobId then
        if statusLabel then statusLabel:SetText("PlaceId ou Jobid inválido!") end
        warn("[MidNight Hub] PlaceId/Jobid inválido ou corrompido.")
        return
    end

    if statusLabel then statusLabel:SetText("Entrando no servidor...") end

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)

    if not ok then
        if statusLabel then statusLabel:SetText("Falha ao entrar no servidor.") end
        warn("[MidNight Hub] Erro no teleport: " .. tostring(err))
    end
end

-- ================= Interface =================
local Window = Library:CreateWindow({
    Name = "MidNight Hub",
    SubName = "BF Notifier",
    Logo = "rbxassetid://0", -- troque pelo seu logo
    WatermarkEnabled = true,
    WatermarkText = "MidNight Hub",
    SettingsTabEnabled = true,
})

local Page = Window:Page({
    Name = "Join Server",
    Icon = "rocket",
})

local Section = Page:Section({
    Name = "Entrar no Servidor",
})

local placeIdInput, jobIdInput -- referências pros Textbox, pra ler no botão

local statusLabel = Section:AddLabel("Cole o PlaceId e o Jobid do Discord")

placeIdInput = Section:AddTextbox({
    Name = "PlaceId",
    Flag = "mhub_place_id",
    Placeholder = "Ex: 2753915549",
    Default = "",
    Numeric = false,
    Finished = false,
})

jobIdInput = Section:AddTextbox({
    Name = "Jobid",
    Flag = "mhub_job_id",
    Placeholder = "Cole o Jobid ofuscado aqui...",
    Default = "",
    Numeric = false,
    Finished = false,
})

Section:AddButton({
    Name = "Join Server",
    Callback = function()
        local placeIdStr = placeIdInput:Get()
        local jobIdStr = jobIdInput:Get()
        if not placeIdStr or placeIdStr == "" or not jobIdStr or jobIdStr == "" then
            statusLabel:SetText("Preenche PlaceId e Jobid antes!")
            return
        end
        JoinServer(placeIdStr, jobIdStr, statusLabel)
    end,
})

-- Auto-join se o embed já injetou _G.MHUB_SERVER_ID = {placeId, jobidOfuscado}
-- (via o botão "Or run this script!" do Discord)
if getgenv().MHUB_SERVER_ID or _G.MHUB_SERVER_ID then
    local data = getgenv().MHUB_SERVER_ID or _G.MHUB_SERVER_ID
    if type(data) == "table" and data[1] and data[2] then
        JoinServer(data[1], data[2], statusLabel)
    end
end

print("[MidNight Hub] HUB carregado.")
