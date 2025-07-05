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

-- Estilos
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
title.Text = "== TERMINAL MENU =="
title.TextColor3 = green
title.Font = Enum.Font.Code
title.TextScaled = true
title.Parent = frame

-- Cerrar GUI
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 100, 0, 30)
closeBtn.Position = UDim2.new(1, -110, 0, 5)
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

-- Navegación stack
local navStack = {}

-- Registro de listeners para RemoteEvents específicos
local activeListeners = {}

-- Variables para listener global
local globalListenerActive = false
local globalConnections = {}
local globalRemoteCounters = {}
local globalDescendantConn = nil
local globalScroll = nil
local globalContentFrame = nil

local function clearContent()
	for _, child in pairs(contentFrame:GetChildren()) do
		child:Destroy()
	end
end

local function createScrollContainer()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Name = "ScrollContainer"

	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)

	return scroll
end

local function appendLine(container, text)
	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, -10, 0, 22)
	line.Text = text
	line.TextColor3 = green
	line.BackgroundTransparency = 1
	line.Font = Enum.Font.Code
	line.TextSize = 18
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Parent = container
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

	appendLine(scroll, "[ Propiedades de: " .. obj.Name .. " ]")

	local props = {"Name", "ClassName", "Parent", "Archivable"}

	for _, prop in pairs(props) do
		local success, value = pcall(function()
			local val = obj[prop]
			if typeof(val) == "Instance" then
				return val:GetFullName()
			elseif typeof(val) == "function" then
				return "[función]"
			else
				return tostring(val)
			end
		end)
		appendLine(scroll, prop .. ": " .. (success and tostring(value) or "[no accesible]"))
	end

	if obj:IsA("RemoteEvent") then
		appendLine(scroll, "== RemoteEvent: Escuchando OnClientEvent ==")

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
			appendLine(scroll, "[Ya escuchando este RemoteEvent]")
		else
			local connection = obj.OnClientEvent:Connect(function(...)
				counter += 1
				counterLabel.Text = "Llamadas recibidas: " .. counter
				if not argsExampleShown then
					appendLine(scroll, "--- Primera llamada ---")
					local args = {...}
					for i, arg in ipairs(args) do
						local val = typeof(arg) == "Instance" and arg:GetFullName() or tostring(arg)
						appendLine(scroll, "Arg[" .. i .. "]: " .. val)
					end
					argsExampleShown = true
				end
			end)
			activeListeners[obj] = connection
		end

		-- Panel para enviar llamada
		local sendFrame = Instance.new("Frame")
		sendFrame.Size = UDim2.new(1, 0, 0, 80)
		sendFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		sendFrame.BorderSizePixel = 0
		sendFrame.Position = UDim2.new(0, 0, 1, 5)
		sendFrame.Parent = scroll

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Text = "Enviar llamada (args separados por coma):"
		infoLabel.Size = UDim2.new(1, -10, 0, 20)
		infoLabel.Position = UDim2.new(0, 5, 0, 5)
		infoLabel.BackgroundTransparency = 1
		infoLabel.TextColor3 = green
		infoLabel.Font = Enum.Font.Code
		infoLabel.TextSize = 16
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.Parent = sendFrame

		local inputBox = Instance.new("TextBox")
		inputBox.PlaceholderText = 'ej: 123, "hola", true'
		inputBox.Size = UDim2.new(1, -10, 0, 30)
		inputBox.Position = UDim2.new(0, 5, 0, 30)
		inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		inputBox.TextColor3 = green
		inputBox.Font = Enum.Font.Code
		inputBox.TextSize = 18
		inputBox.ClearTextOnFocus = false
		inputBox.Parent = sendFrame

		local sendBtn = Instance.new("TextButton")
		sendBtn.Text = "Enviar llamada"
		sendBtn.Size = UDim2.new(0, 140, 0, 30)
		sendBtn.Position = UDim2.new(1, -145, 0, 35)
		sendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		sendBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		sendBtn.Font = Enum.Font.Code
		sendBtn.TextSize = 18
		sendBtn.Parent = sendFrame

		local function parseArgs(text)
			local args = {}
			local luaChunk = "return {" .. text .. "}"
			local func, err = loadstring(luaChunk)
			if func then
				local ok, result = pcall(func)
				if ok and type(result) == "table" then
					args = result
				else
					warn("Error ejecutando argumentos:", result)
				end
			else
				warn("Error parseando argumentos:", err)
			end
			return args
		end

		sendBtn.MouseButton1Click:Connect(function()
			local argsText = inputBox.Text
			if argsText == "" then
				warn("No se han ingresado argumentos.")
				return
			end
			local args = parseArgs(argsText)
			if #args == 0 then
				warn("No se pudieron parsear argumentos.")
				return
			end
			obj:FireServer(unpack(args))
			appendLine(scroll, "[ Llamada enviada con " .. #args .. " argumento(s) ]")
		end)
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
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -10, 0, 28)
		button.Text = "[ " .. child.ClassName .. " ] " .. child.Name
		button.TextColor3 = green
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		button.Font = Enum.Font.Code
		button.TextSize = 18
		button.AutoButtonColor = false
		button.Parent = scroll

		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = hover
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		button.MouseButton1Click:Connect(function()
			table.insert(navStack, function() showObjectContents(obj, label) end)
			if #child:GetChildren() > 0 then
				showObjectContents(child, child.Name)
			else
				showProperties(child)
			end
		end)
	end
end

local function stopGlobalListener()
	-- Desconectar todos
	for _, conn in pairs(globalConnections) do
		conn:Disconnect()
	end
	globalConnections = {}
	globalRemoteCounters = {}
	if globalDescendantConn then
		globalDescendantConn:Disconnect()
		globalDescendantConn = nil
	end
	globalListenerActive = false
	globalScroll = nil
	globalContentFrame = nil
end

local function startGlobalListener()
	if globalListenerActive then return end
	globalListenerActive = true
	clearContent()

	-- Botón para regresar
	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(1, 0, 0, 30)
	backBtn.Text = "< Regresar"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.Parent = contentFrame
	backBtn.MouseButton1Click:Connect(function()
		stopGlobalListener()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	-- Scroll para mostrar info
	local scroll = createScrollContainer()
	scroll.Parent = contentFrame
	globalScroll = scroll

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 22)
	infoLabel.Text = "[ Listener global ON - Detectando RemoteEvents ]"
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = green
	infoLabel.Font = Enum.Font.Code
	infoLabel.TextSize = 18
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = scroll

	local function addRemote(remote)
		if globalRemoteCounters[remote] then return end -- Ya agregado
		globalRemoteCounters[remote] = 0

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 28)
		btn.Text = "[RemoteEvent] " .. remote.Name
		btn.TextColor3 = green
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.Font = Enum.Font.Code
		btn.TextSize = 18
		btn.AutoButtonColor = false
		btn.Parent = scroll

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = hover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		btn.MouseButton1Click:Connect(function()
			-- Al hacer click, mostrar propiedades y activar listener del RemoteEvent
			table.insert(navStack, startGlobalListener)
			showProperties(remote)
		end)

		local conn = remote.OnClientEvent:Connect(function(...)
			globalRemoteCounters[remote] += 1
			btn.Text = "[RemoteEvent] " .. remote.Name .. " - Llamadas: " .. globalRemoteCounters[remote]
		end)
		table.insert(globalConnections, conn)
	end

	-- Buscar todos los RemoteEvents existentes y conectarlos
	for _, inst in pairs(game:GetDescendants()) do
		if inst:IsA("RemoteEvent") then
			addRemote(inst)
		end
	end

	-- Conectar para detectar RemoteEvents nuevos que se agreguen
	globalDescendantConn = game.DescendantAdded:Connect(function(inst)
		if inst:IsA("RemoteEvent") then
			addRemote(inst)
		end
	end)
end

-- Mostrar menú principal con botones para opciones
local function showMainMenu()
	clearContent()

	local globalBtn = Instance.new("TextButton")
	globalBtn.Size = UDim2.new(1, 0, 0, 40)
	globalBtn.Text = "Listener Global de RemoteEvents"
	globalBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	globalBtn.TextColor3 = green
	globalBtn.Font = Enum.Font.Code
	globalBtn.TextSize = 20
	globalBtn.Parent = contentFrame

	globalBtn.MouseEnter:Connect(function()
		globalBtn.BackgroundColor3 = hover
	end)
	globalBtn.MouseLeave:Connect(function()
		globalBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	end)

	globalBtn.MouseButton1Click:Connect(function()
		table.insert(navStack, showMainMenu)
		startGlobalListener()
	end)
end

-- Inicializar menú
showMainMenu()
