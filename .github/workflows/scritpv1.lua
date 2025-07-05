local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Eliminar GUI previa
local oldGui = playerGui:FindFirstChild("ConsoleMenu")
if oldGui then oldGui:Destroy() end

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ConsoleMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Colores y estilos
local green = Color3.fromRGB(0, 255, 0)
local bg = Color3.fromRGB(20, 20, 20)
local hover = Color3.fromRGB(50, 50, 50)

-- Marco principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.45, 0, 0.6, 0)
frame.Position = UDim2.new(0.275, 0, 0.2, 0)
frame.BackgroundColor3 = bg
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.1, 0)
title.BackgroundTransparency = 1
title.Text = "== LISTA DE REMOTE EVENTS =="
title.TextColor3 = green
title.Font = Enum.Font.Code
title.TextScaled = true
title.Parent = frame

-- Cerrar GUI
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 100, 0, 30)
closeBtn.Position = UDim2.new(1, -110, 0.02, 0)
closeBtn.Text = "X Cerrar"
closeBtn.Font = Enum.Font.Code
closeBtn.TextColor3 = green
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Contenedor principal para contenido
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 0.85, -40)
contentFrame.Position = UDim2.new(0, 10, 0.12, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Name = "Content"
contentFrame.Parent = frame

-- Navegación
local navStack = {}

local function clearContent()
	for _, child in pairs(contentFrame:GetChildren()) do
		child:Destroy()
	end
end

-- Crear scroll container
local function createScrollContainer()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Parent = contentFrame

	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)

	return scroll
end

-- Mostrar propiedades de un objeto
local function showProperties(obj)
	clearContent()

	local backBtn = Instance.new("TextButton", contentFrame)
	backBtn.Size = UDim2.new(1, 0, 0, 30)
	backBtn.Text = "< Regresar"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.MouseButton1Click:Connect(function()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	local container = createScrollContainer()
	container.Position = UDim2.new(0, 0, 0, 35)
	container.Size = UDim2.new(1, 0, 1, -35)

	-- Lista propiedades importantes y algunas extras
	local props = {
		"Name", "ClassName", "Parent", "Archivable",
		"MaxReplicationDistance", "EventId"
	}

	local function appendLine(text)
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(1, -10, 0, 22)
		line.Text = text
		line.TextColor3 = green
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.Code
		line.TextSize = 18
		line.TextWrapped = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Parent = container
	end

	appendLine("[ Propiedades de: ".. obj.Name .." ]")

	for _, prop in ipairs(props) do
		local success, value = pcall(function()
			return obj[prop]
		end)
		if success then
			appendLine(prop .. ": " .. tostring(value))
		else
			appendLine(prop .. ": [no accesible]")
		end
	end
end

-- Mostrar lista de RemoteEvents para seleccionar
local function showRemoteEventsList()
	clearContent()

	local backBtn = Instance.new("TextButton", contentFrame)
	backBtn.Size = UDim2.new(1, 0, 0, 30)
	backBtn.Text = "< Regresar"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.MouseButton1Click:Connect(function()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	local scroll = createScrollContainer()

	-- Buscar todos los RemoteEvents en el juego
	local remotes = {}
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("RemoteEvent") then
			table.insert(remotes, inst)
		end
	end

	if #remotes == 0 then
		local noRemotes = Instance.new("TextLabel")
		noRemotes.Size = UDim2.new(1, -10, 0, 30)
		noRemotes.Text = "No se encontraron RemoteEvents."
		noRemotes.TextColor3 = green
		noRemotes.BackgroundTransparency = 1
		noRemotes.Font = Enum.Font.Code
		noRemotes.TextSize = 20
		noRemotes.TextWrapped = true
		noRemotes.Parent = scroll
		return
	end

	-- Crear botones para cada RemoteEvent
	for i, remote in ipairs(remotes) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 28)
		btn.TextColor3 = green
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.Font = Enum.Font.Code
		btn.TextSize = 18
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Text = "[".. remote.ClassName .."] " .. remote.Name
		btn.AutoButtonColor = false
		btn.Parent = scroll

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = hover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		btn.MouseButton1Click:Connect(function()
			table.insert(navStack, showRemoteEventsList)
			showProperties(remote)
		end)
	end
end

-- Mostrar menú principal
local function showMainMenu()
	clearContent()

	local label = Instance.new("TextLabel", contentFrame)
	label.Size = UDim2.new(1, 0, 0, 40)
	label.Text = "MENU PRINCIPAL"
	label.TextColor3 = green
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextSize = 28

	local btn = Instance.new("TextButton", contentFrame)
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = green
	btn.Font = Enum.Font.Code
	btn.TextSize = 22
	btn.Text = "Lista de RemoteEvents"
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
		showRemoteEventsList()
	end)
end

-- Iniciar GUI mostrando menú principal
showMainMenu()
