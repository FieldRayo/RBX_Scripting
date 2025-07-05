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
closeBtn.Position = UDim2.new(1, -110, 0, 0)
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
contentFrame.Position = UDim2.new(0, 10, 0.12, 30)
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

-- StackContainer para mostrar detalles
local function createStackContainer()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Name = "StackContainer"

	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)

	return scroll
end

-- Mostrar línea de texto
local function appendLine(container, text)
	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, -10, 0, 20)
	line.Text = text
	line.TextColor3 = green
	line.BackgroundTransparency = 1
	line.Font = Enum.Font.Code
	line.TextSize = 18
	line.TextWrapped = true
	line.LayoutOrder = os.time()
	line.Parent = container
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

	local container = createStackContainer()
	container.Position = UDim2.new(0, 0, 0, 35)
	container.Size = UDim2.new(1, 0, 1, -35)
	container.Parent = contentFrame

	local props = {
		"Name", "ClassName", "Parent", "Archivable",
		"IsA", "IsDescendantOf"
	}

	appendLine(container, "[ Propiedades de: " .. obj.Name .. " ]")

	for _, prop in pairs(props) do
		local success, value = pcall(function()
			local val = obj[prop]
			if typeof(val) == "Instance" then
				return val.Name
			elseif typeof(val) == "function" then
				return "[función]"
			else
				return tostring(val)
			end
		end)
		if success then
			appendLine(container, prop .. ": " .. tostring(value))
		else
			appendLine(container, prop .. ": [no accesible]")
		end
	end
end

-- Mostrar contenido de una carpeta o servicio
local function showObjectContents(obj, label)
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

	local scroll = Instance.new("ScrollingFrame", contentFrame)
	scroll.Size = UDim2.new(1, 0, 1, -35)
	scroll.Position = UDim2.new(0, 0, 0, 35)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Name = "StackContainer"

	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)

	for _, child in ipairs(obj:GetChildren()) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -10, 0, 28)
		button.Text = "[ " .. child.ClassName .. " ] " .. child.Name
		button.TextColor3 = green
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		button.Font = Enum.Font.Code
		button.TextSize = 18
		button.Parent = scroll
		button.AutoButtonColor = false

		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = hover
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		button.MouseButton1Click:Connect(function()
			-- Push función actual al stack antes de navegar
			table.insert(navStack, function() showObjectContents(obj, label) end)
			if #child:GetChildren() > 0 then
				showObjectContents(child, child.Name)
			else
				showProperties(child)
			end
		end)

		-- Si es RemoteEvent, agregar opción para llamarlo
		if child:IsA("RemoteEvent") then
			local callBtn = Instance.new("TextButton")
			callBtn.Size = UDim2.new(0, 70, 0, 20)
			callBtn.Position = UDim2.new(1, -80, 0, 4)
			callBtn.Text = "Call"
			callBtn.Font = Enum.Font.Code
			callBtn.TextSize = 14
			callBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
			callBtn.TextColor3 = green
			callBtn.Parent = button
			callBtn.AutoButtonColor = false

			callBtn.MouseEnter:Connect(function()
				callBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
			end)
			callBtn.MouseLeave:Connect(function()
				callBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
			end)

			callBtn.MouseButton1Click:Connect(function()
				-- Llamar el RemoteEvent sin parámetros (puedes modificar para pedir args)
				child:FireServer()
			end)
		end
	end
end

-- Variables y funciones para el listener global
local listening = false
local remoteCallsCount = {}
local remoteConnections = {}
local listenerContainer

local function disconnectAllRemotes()
	for _, conn in pairs(remoteConnections) do
		conn:Disconnect()
	end
	remoteConnections = {}
end

local function updateRemoteCounter(remote, scroll, navStack)

	local name = remote:GetFullName()
	remoteCallsCount[remote] = remoteCallsCount[remote] or 0
	local count = remoteCallsCount[remote]

	-- Buscar si ya existe el label en scroll
	local counterData = scroll:FindFirstChild(remote.Name)
	if counterData then
		counterData.Text = string.format("[%d] %s", count, name)
		return
	end

	-- Crear nuevo botón para RemoteEvent
	local label = Instance.new("TextButton")
	label.Name = remote.Name
	label.Size = UDim2.new(1, -10, 0, 22)
	label.TextColor3 = green
	label.Font = Enum.Font.Code
	label.BackgroundTransparency = 1
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.format("[%d] %s", count, name)
	label.AutoButtonColor = false
	label.Parent = scroll

	label.MouseEnter:Connect(function()
		label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end)
	label.MouseLeave:Connect(function()
		label.BackgroundTransparency = 1
	end)

	label.MouseButton1Click:Connect(function()
		-- Mostrar info detallada del RemoteEvent
		table.insert(navStack, function()
			-- Regresar al listener mostrando el scroll actualizado
			showGlobalListenerToggle()
		end)
		showProperties(remote)
	end)
end

-- Escuchar RemoteEvents y actualizar contador
local function startGlobalListener()
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

	-- Contenedor para el listener
	listenerContainer = Instance.new("Frame", contentFrame)
	listenerContainer.Size = UDim2.new(1, 0, 1, -40)
	listenerContainer.Position = UDim2.new(0, 0, 0, 35)
	listenerContainer.BackgroundColor3 = Color3.fromRGB(30,30,30)
	listenerContainer.BorderSizePixel = 0

	local filterLabels = {
		{Text = "Sin llamadas (0)", Filter = function(c) return c == 0 end},
		{Text = "Llamadas 1-10", Filter = function(c) return c > 0 and c <= 10 end},
		{Text = "Llamadas > 10", Filter = function(c) return c > 10 end},
	}

	local selectedFilter = 1

	local filterButtons = {}

	local filterFrame = Instance.new("Frame", listenerContainer)
	filterFrame.Size = UDim2.new(1, 0, 0, 35)
	filterFrame.BackgroundTransparency = 1

	for i, fdata in ipairs(filterLabels) do
		local fb = Instance.new("TextButton", filterFrame)
		fb.Size = UDim2.new(0, 120, 1, 0)
		fb.Position = UDim2.new((i-1)*0.33, 0, 0, 0)
		fb.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		fb.TextColor3 = green
		fb.Font = Enum.Font.Code
		fb.TextSize = 18
		fb.Text = fdata.Text
		fb.AutoButtonColor = false

		if i == selectedFilter then
			fb.BackgroundColor3 = hover
		end

		fb.MouseEnter:Connect(function()
			fb.BackgroundColor3 = hover
		end)
		fb.MouseLeave:Connect(function()
			if i ~= selectedFilter then
				fb.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end)

		fb.MouseButton1Click:Connect(function()
			selectedFilter = i
			for _, btn in pairs(filterButtons) do
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
			fb.BackgroundColor3 = hover
			refreshListenerScroll()
		end)

		filterButtons[i] = fb
	end

	local scroll = Instance.new("ScrollingFrame", listenerContainer)
	scroll.Size = UDim2.new(1, 0, 1, -35)
	scroll.Position = UDim2.new(0, 0, 0, 35)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Name = "ListenerScroll"

	local layout = Instance.new("UIListLayout", scroll)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)

	local function refreshListenerScroll()
		scroll:ClearAllChildren()
		for remote, count in pairs(remoteCallsCount) do
			local passesFilter = false
			if selectedFilter == 1 then
				passesFilter = (count == 0)
			elseif selectedFilter == 2 then
				passesFilter = (count > 0 and count <= 10)
			else
				passesFilter = (count > 10)
			end
			if passesFilter then
				local name = remote:GetFullName()
				local label = Instance.new("TextButton")
				label.Size = UDim2.new(1, -10, 0, 22)
				label.TextColor3 = green
				label.Font = Enum.Font.Code
				label.BackgroundTransparency = 1
				label.TextSize = 18
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Text = string.format("[%d] %s", count, name)
				label.AutoButtonColor = false
				label.Parent = scroll

				label.MouseEnter:Connect(function()
					label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				end)
				label.MouseLeave:Connect(function()
					label.BackgroundTransparency = 1
				end)

				label.MouseButton1Click:Connect(function()
					table.insert(navStack, function()
						showGlobalListenerToggle()
					end)
					showProperties(remote)
				end)
			end
		end
	end

	-- Detectar RemoteEvents actuales y futuros
	local function listenToRemote(remote)
		if remoteConnections[remote] then return end -- Ya conectado

		remoteCallsCount[remote] = 0

		local conn = remote.OnClientEvent:Connect(function(...)
		    remoteCallsCount[remote] = remoteCallsCount[remote] + 1
		    refreshListenerScroll()
		end)
		remoteConnections[remote] = conn
	end

	-- Inicializar escuchas
	local function initListener()
		-- Limpiar conexiones previas
		disconnectAllRemotes()
		remoteCallsCount = {}

		-- Buscar RemoteEvents en todo el juego (puedes agregar servicios extra si quieres)
		local function scanForRemotes(obj)
			for _, child in pairs(obj:GetChildren()) do
				if child:IsA("RemoteEvent") then
					listenToRemote(child)
				end
				scanForRemotes(child)
			end
		end
		scanForRemotes(game)

		-- Detectar RemoteEvents añadidos después
		game.DescendantAdded:Connect(function(desc)
			if desc:IsA("RemoteEvent") then
				listenToRemote(desc)
				refreshListenerScroll()
			end
		end)
		refreshListenerScroll()
	end

	initListener()
end

local function showGlobalListenerToggle()
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

	local toggleBtn = Instance.new("TextButton", contentFrame)
	toggleBtn.Size = UDim2.new(1, 0, 0, 40)
	toggleBtn.Position = UDim2.new(0, 0, 0, 35)
	toggleBtn.TextColor3 = green
	toggleBtn.Font = Enum.Font.Code
	toggleBtn.TextSize = 20
	toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	toggleBtn.AutoButtonColor = false

	local statusLabel = Instance.new("TextLabel", toggleBtn)
	statusLabel.Size = UDim2.new(0.5, 0, 1, 0)
	statusLabel.Position = UDim2.new(0, 10, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Code
	statusLabel.TextSize = 20
	statusLabel.TextColor3 = green
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	local listenerActive = false

	local function updateStatus()
		statusLabel.Text = "Listener Global: " .. (listenerActive and "ON" or "OFF")
		toggleBtn.BackgroundColor3 = listenerActive and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(40, 10, 10)
	end

	updateStatus()

	toggleBtn.MouseButton1Click:Connect(function()
		listenerActive = not listenerActive
		updateStatus()

		if listenerActive then
			startGlobalListener()
		else
			disconnectAllRemotes()
			clearContent()
			appendLine(contentFrame, "Listener Global detenido.")
		end
	end)
end

-- Mostrar menú principal
local function showMainMenu()
	clearContent()

	local titleLabel = Instance.new("TextLabel", contentFrame)
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Text = "MENU PRINCIPAL"
	titleLabel.TextColor3 = green
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextSize = 28

	local buttonsData = {
		{Name = "Explorer", Func = function()
			table.insert(navStack, showMainMenu)
			showObjectContents(game, "Game")
		end},
		{Name = "Listener Global RemoteEvents", Func = function()
			table.insert(navStack, showMainMenu)
			showGlobalListenerToggle()
		end},
	}

	local layout = Instance.new("UIListLayout", contentFrame)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 15)

	for i, btnData in ipairs(buttonsData) do
		local btn = Instance.new("TextButton", contentFrame)
		btn.Size = UDim2.new(1, -20, 0, 40)
		btn.Position = UDim2.new(0, 10, 0, 50 + (i-1)*50)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = green
		btn.Font = Enum.Font.Code
		btn.TextSize = 22
		btn.Text = btnData.Name
		btn.AutoButtonColor = false

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = hover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		btn.MouseButton1Click:Connect(btnData.Func)
	end
end

-- Iniciar menú
showMainMenu()
