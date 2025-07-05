-- Explorador Hacker - Interfaz GUI para explorar objetos del juego
-- Estilo hacker verde con soporte para RemoteEvents y navegación por servicios

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Limpiar GUI previa
local oldGui = playerGui:FindFirstChild("ExplorerTerminal")
if oldGui then oldGui:Destroy() end

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExplorerTerminal"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Estilo hacker
local green = Color3.fromRGB(0, 255, 0)
local bg = Color3.fromRGB(15, 15, 15)
local hover = Color3.fromRGB(40, 40, 40)

-- Marco principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.5, 0, 0.65, 0)
frame.Position = UDim2.new(0.25, 0, 0.175, 0)
frame.BackgroundColor3 = bg
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.1, 0)
title.BackgroundTransparency = 1
title.Text = "== EXPLORADOR DE JUEGO =="
title.TextColor3 = green
title.Font = Enum.Font.Code
title.TextScaled = true
title.Parent = frame

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 100, 0, 28)
closeBtn.Position = UDim2.new(1, -105, 10, 0)
closeBtn.Text = "X Cerrar"
closeBtn.Font = Enum.Font.Code
closeBtn.TextColor3 = green
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Contenedor principal
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 0.8, -40)
contentFrame.Position = UDim2.new(0, 10, 0.12, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Name = "Content"
contentFrame.Parent = frame

local navStack = {}
local activeListeners = {}

local function clearContent()
	for _, child in pairs(contentFrame:GetChildren()) do
		child:Destroy()
	end
end

local function createScrollContainer()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.Position = UDim2.new(0, 0, 0, 35)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 5
	scroll.Name = "ExplorerScroll"

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	return scroll
end

local function showProperties(obj)
	clearContent()

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(1, 0, 0, 30)
	backBtn.Text = "< Regresar"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.Parent = contentFrame
	backBtn.MouseButton1Click:Connect(function()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	local scroll = createScrollContainer()
	scroll.Parent = contentFrame

	local function appendLine(txt)
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(1, -10, 0, 22)
		line.Text = txt
		line.TextColor3 = green
		line.Font = Enum.Font.Code
		line.BackgroundTransparency = 1
		line.TextSize = 18
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Parent = scroll
	end

	appendLine("[ Propiedades de: " .. obj.Name .. " ]")
	local props = {"Name", "ClassName", "Parent", "Archivable"}

	for _, prop in pairs(props) do
		local success, value = pcall(function()
			return tostring(obj[prop])
		end)
		appendLine(prop .. ": " .. (success and value or "[no accesible]"))
	end

	if obj:IsA("RemoteEvent") then
		appendLine("== RemoteEvent: Escuchando OnClientEvent ==")

		local counter = 0
		local argsExampleShown = false
		local counterLabel = Instance.new("TextLabel")
		counterLabel.Size = UDim2.new(1, -10, 0, 22)
		counterLabel.TextColor3 = green
		counterLabel.Font = Enum.Font.Code
		counterLabel.BackgroundTransparency = 1
		counterLabel.TextSize = 18
		counterLabel.TextXAlignment = Enum.TextXAlignment.Left
		counterLabel.LayoutOrder = 999
		counterLabel.Text = "Llamadas recibidas: 0"
		counterLabel.Parent = scroll

		if activeListeners[obj] then
			appendLine("[Ya escuchando este RemoteEvent]")
			return
		end

		local connection = obj.OnClientEvent:Connect(function(...)
			counter += 1
			counterLabel.Text = "Llamadas recibidas: " .. counter
			if not argsExampleShown then
				appendLine("--- Primera llamada ---")
				local args = {...}
				for i, arg in ipairs(args) do
					local val = typeof(arg) == "Instance" and arg:GetFullName() or tostring(arg)
					appendLine("Arg[" .. i .. "]: " .. val)
				end
				argsExampleShown = true
			end
		end)

		activeListeners[obj] = connection
	end
end

local function showObjectContents(obj, label)
	clearContent()

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(1, 0, 0, 30)
	backBtn.Text = "< Regresar"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.Parent = contentFrame

	backBtn.MouseButton1Click:Connect(function()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	local scroll = createScrollContainer()
	scroll.Parent = contentFrame

	for _, child in ipairs(obj:GetChildren()) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 30)
		btn.Text = "[ " .. child.ClassName .. " ] " .. child.Name
		btn.Font = Enum.Font.Code
		btn.TextSize = 18
		btn.TextColor3 = green
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.Parent = scroll

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = hover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		btn.MouseButton1Click:Connect(function()
			table.insert(navStack, function() showObjectContents(obj, label) end)
			if #child:GetChildren() > 0 then
				showObjectContents(child, child.Name)
			else
				showProperties(child)
			end
		end)
	end
end

local function showMainMenu()
	clearContent()
	navStack = {}

	local services = {
		{label = "Workspace", ref = workspace},
		{label = "ReplicatedStorage", ref = game:GetService("ReplicatedStorage")},
		{label = "Players", ref = game:GetService("Players")},
		{label = "Lighting", ref = game:GetService("Lighting")},
		{label = "StarterGui", ref = game:GetService("StarterGui")},
		{label = "ServerStorage", ref = game:GetService("ServerStorage")},
		{label = "PlayerScripts", ref = player:WaitForChild("PlayerScripts")},
	}

	for i, svc in ipairs(services) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 36)
		btn.Position = UDim2.new(0, 10, 0, (i - 1) * 40)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = green
		btn.Text = "[ " .. i .. " ] " .. svc.label
		btn.Font = Enum.Font.Code
		btn.TextSize = 18
		btn.AutoButtonColor = false
		btn.Parent = contentFrame

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = hover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		btn.MouseButton1Click:Connect(function()
			table.insert(navStack, showMainMenu)
			showObjectContents(svc.ref, svc.label)
		end)
	end
end

showMainMenu()
