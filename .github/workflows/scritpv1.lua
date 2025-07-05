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
	backBtn.Size = UDim2.new(0, 30, 0, 30)
	backBtn.Position = UDim2.new(1, -35, 0, 5)
	backBtn.Text = "←"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.ZIndex = 2
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

	-- 🔍 Barra de búsqueda
	local searchBox = Instance.new("TextBox")
	searchBox.PlaceholderText = "Buscar por nombre o clase..."
	searchBox.Size = UDim2.new(1, 0, 0, 30)
	searchBox.Position = UDim2.new(0, 0, 0, 35)
	searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	searchBox.TextColor3 = green
	searchBox.Font = Enum.Font.Code
	searchBox.TextSize = 18
	searchBox.ClearTextOnFocus = false
	searchBox.Text = ""
	searchBox.Parent = contentFrame

	local scroll = createScrollContainer()
	scroll.Position = UDim2.new(0, 0, 0, 70)
	scroll.Size = UDim2.new(1, 0, 1, -70)
	scroll.Parent = contentFrame

	local function refreshList(filterText)
		-- Elimina botones previos
		for _, child in pairs(scroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local lowerFilter = string.lower(filterText or "")

		for _, child in ipairs(obj:GetChildren()) do
			local className = child.ClassName
			local name = child.Name
			local full = className .. " " .. name
			if lowerFilter == "" or string.find(string.lower(full), lowerFilter, 1, true) then
				local button = Instance.new("TextButton")
				button.Size = UDim2.new(1, -10, 0, 28)
				button.Text = "[ " .. className .. " ] " .. name
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
	end

	-- Inicializar con todos los objetos
	refreshList("")

	-- Actualizar al escribir
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		refreshList(searchBox.Text)
	end)
end


local function startGlobalListener()
	if globalListenerActive then return end
	globalListenerActive = true
	clearContent()

	-- Botón para regresar
	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0, 30, 0, 30)
	backBtn.Position = UDim2.new(1, -35, 0, 5)
	backBtn.Text = "←"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.ZIndex = 3
	backBtn.Parent = contentFrame

	backBtn.MouseButton1Click:Connect(function()
		stopGlobalListener()
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	-- 🔍 Barra de búsqueda
	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -20, 0, 30)
	searchBox.Position = UDim2.new(0, 10, 0, 40)
	searchBox.PlaceholderText = "Buscar RemoteEvents por nombre..."
	searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	searchBox.TextColor3 = green
	searchBox.Font = Enum.Font.Code
	searchBox.TextSize = 18
	searchBox.ZIndex = 2
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = contentFrame

	-- Scroll para mostrar info
	local scroll = createScrollContainer()
	scroll.Position = UDim2.new(0, 10, 0, 80)
	scroll.Size = UDim2.new(1, -20, 1, -90)
	scroll.Parent = contentFrame
	globalScroll = scroll

	-- Función para ordenar y mostrar RemoteEvents
	local function refreshDisplay()
		local remotesArray = {}
		for remote, data in pairs(globalRemoteCounters) do
			table.insert(remotesArray, {
				remote = remote,
				count = data.count,
				label = data.label
			})
		end

		-- Ordenar de mayor a menor por cantidad de llamadas
		table.sort(remotesArray, function(a, b)
			return a.count > b.count
		end)

		-- Reorganizar en el UI
		for order, data in ipairs(remotesArray) do
			data.label.LayoutOrder = order
		end
	end

	-- Función para filtrar RemoteEvents
	local function filterRemotes(filterText)
		for remote, counterData in pairs(globalRemoteCounters) do
			local visible = true
			if filterText ~= "" then
				local remoteName = remote:GetFullName():lower()
				visible = remoteName:find(filterText:lower(), 1, true) ~= nil
			end
			counterData.label.Visible = visible
		end
		refreshDisplay() -- Reordenar después de filtrar
	end

	-- Actualizar filtro al escribir
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filterRemotes(searchBox.Text)
	end)

	-- Info label
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Text = "Listener Global - RemoteEvents (0 detectados)"
	infoLabel.Size = UDim2.new(1, -10, 0, 22)
	infoLabel.Position = UDim2.new(0, 0, 0, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = green
	infoLabel.Font = Enum.Font.Code
	infoLabel.TextSize = 18
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = scroll

	local function createDetailFrame(remote, count, callHistory)
		-- Frame principal
		local detailFrame = Instance.new("Frame")
		detailFrame.Size = UDim2.new(1, -20, 0, 200)
		detailFrame.Position = UDim2.new(0, 10, 0, 0)
		detailFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		detailFrame.BorderSizePixel = 0
		detailFrame.ZIndex = 3
		detailFrame.Name = "DetailFrame"

		-- Título
		local title = Instance.new("TextLabel")
		title.Text = "Detalles: "..remote:GetFullName()
		title.Size = UDim2.new(1, 0, 0, 30)
		title.BackgroundTransparency = 1
		title.TextColor3 = green
		title.Font = Enum.Font.Code
		title.TextSize = 18
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = detailFrame

		-- Información básica
		local infoText = string.format(
			"Llamadas totales: %d\nClase: %s\nRuta: %s",
			count,
			remote.ClassName,
			remote:GetFullName()
		)

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Text = infoText
		infoLabel.Size = UDim2.new(1, -10, 0, 60)
		infoLabel.Position = UDim2.new(0, 5, 0, 30)
		infoLabel.BackgroundTransparency = 1
		infoLabel.TextColor3 = green
		infoLabel.Font = Enum.Font.Code
		infoLabel.TextSize = 16
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.TextYAlignment = Enum.TextYAlignment.Top
		infoLabel.Parent = detailFrame

		-- Historial de llamadas (scroll)
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Size = UDim2.new(1, -10, 0, 100)
		scrollFrame.Position = UDim2.new(0, 5, 0, 95)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.ScrollBarThickness = 6
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollFrame.Parent = detailFrame

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 5)
		layout.Parent = scrollFrame

		-- Llenar historial
		if #callHistory > 0 then
			for i, call in ipairs(callHistory) do
				local callText = string.format(
					"Llamada #%d: %d args (hace %d seg)",
					i, #call.args, os.time() - call.time
				)

				local callLabel = Instance.new("TextLabel")
				callLabel.Text = callText
				callLabel.Size = UDim2.new(1, 0, 0, 20)
				callLabel.BackgroundTransparency = 1
				callLabel.TextColor3 = green
				callLabel.Font = Enum.Font.Code
				callLabel.TextSize = 14
				callLabel.TextXAlignment = Enum.TextXAlignment.Left
				callLabel.Parent = scrollFrame
			end
		else
			local noHistory = Instance.new("TextLabel")
			noHistory.Text = "No hay historial de llamadas"
			noHistory.Size = UDim2.new(1, 0, 0, 20)
			noHistory.BackgroundTransparency = 1
			noHistory.TextColor3 = Color3.fromRGB(150, 150, 150)
			noHistory.Font = Enum.Font.Code
			noHistory.TextSize = 14
			noHistory.Parent = scrollFrame
		end

		-- Botón para cerrar
		local closeBtn = Instance.new("TextButton")
		closeBtn.Text = "Cerrar"
		closeBtn.Size = UDim2.new(0, 80, 0, 25)
		closeBtn.Position = UDim2.new(1, -85, 1, -30)
		closeBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
		closeBtn.TextColor3 = green
		closeBtn.Font = Enum.Font.Code
		closeBtn.TextSize = 16
		closeBtn.Parent = detailFrame

		closeBtn.MouseButton1Click:Connect(function()
			detailFrame:Destroy()
		end)

		return detailFrame
	end

	-- Modificación en updateRemoteCounter:
	local function updateRemoteCounter(remote)
		local name = remote:GetFullName()
		local callHistory = {}

		if not globalRemoteCounters[remote] then
			-- Crear botón principal
			local remoteButton = Instance.new("TextButton")
			remoteButton.Size = UDim2.new(1, -10, 0, 28)
			remoteButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			remoteButton.AutoButtonColor = false
			remoteButton.Text = ""
			remoteButton.ZIndex = 2
			remoteButton.LayoutOrder = #globalScroll:GetChildren() + 1
			remoteButton.Parent = globalScroll

			-- Label para mostrar la info
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.TextColor3 = green
			label.Font = Enum.Font.Code
			label.TextSize = 18
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = "[0] " .. name
			label.ZIndex = 3
			label.Parent = remoteButton

			-- Configurar datos
			local counterData = {
				count = 0,
				button = remoteButton,
				label = label,
				history = callHistory,
				visible = true,
				baseLayoutOrder = remoteButton.LayoutOrder
			}

			globalRemoteCounters[remote] = counterData

			-- Efecto hover
			remoteButton.MouseEnter:Connect(function()
				remoteButton.BackgroundColor3 = hover
			end)

			remoteButton.MouseLeave:Connect(function()
				remoteButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end)

			-- Manejar clic
			remoteButton.MouseButton1Click:Connect(function()
				-- Cerrar detalles previos
				for _, child in pairs(globalScroll:GetChildren()) do
					if child.Name == "DetailFrame" then
						child:Destroy()
					end
				end

				-- Crear nuevo panel de detalles
				local details = createDetailFrame(remote, counterData.count, callHistory)
				details.LayoutOrder = counterData.baseLayoutOrder + 0.5 -- Insertar justo debajo
				details.Parent = globalScroll

				-- Ajustar LayoutOrder de otros elementos
				for _, data in pairs(globalRemoteCounters) do
					if data.baseLayoutOrder > counterData.baseLayoutOrder then
						data.button.LayoutOrder = data.baseLayoutOrder + 1
					end
				end

				-- Forzar actualización del scroll
				globalScroll.CanvasSize = UDim2.new(0, 0, 0, #globalScroll:GetChildren() * 35)
				wait()
				globalScroll.CanvasPosition = Vector2.new(0, details.AbsolutePosition.Y - globalScroll.AbsolutePosition.Y)
			end)

			-- Conectar evento
			local conn = remote.OnClientEvent:Connect(function(...)
				counterData.count += 1
				counterData.label.Text = "["..counterData.count.."] "..name

				-- Registrar llamada
				table.insert(callHistory, 1, {
					args = {...},
					time = os.time()
				})

				if #callHistory > 5 then
					table.remove(callHistory, 6)
				end

				refreshDisplay()
			end)

			table.insert(globalConnections, conn)
		end
	end

	-- Detectar remotes ya existentes
	for _, inst in pairs(game:GetDescendants()) do
		if inst:IsA("RemoteEvent") then
			updateRemoteCounter(inst)
		end
	end

	-- Escuchar nuevos remotes agregados
	globalDescendantConn = game.DescendantAdded:Connect(function(inst)
		if inst:IsA("RemoteEvent") then
			updateRemoteCounter(inst)
		end
	end)
end

local function showGlobalListenerToggle()
	clearContent()

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0, 30, 0, 30)
	backBtn.Position = UDim2.new(1, -35, 0, 5)
	backBtn.Text = "←"
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.TextColor3 = green
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 18
	backBtn.ZIndex = 2
	backBtn.Parent = contentFrame

	backBtn.MouseButton1Click:Connect(function()
		if globalListenerActive then
			stopGlobalListener()
		end
		if #navStack > 0 then
			local last = table.remove(navStack)
			last()
		end
	end)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 200, 0, 40)
	toggleBtn.Position = UDim2.new(0.5, -100, 0.5, -20)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	toggleBtn.TextColor3 = green
	toggleBtn.Font = Enum.Font.Code
	toggleBtn.TextSize = 20
	toggleBtn.Text = globalListenerActive and "Desactivar Listener Global" or "Activar Listener Global"
	toggleBtn.Parent = contentFrame

	toggleBtn.MouseEnter:Connect(function()
		toggleBtn.BackgroundColor3 = hover
	end)
	toggleBtn.MouseLeave:Connect(function()
		toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end)

	toggleBtn.MouseButton1Click:Connect(function()
		if globalListenerActive then
			stopGlobalListener()
			toggleBtn.Text = "Activar Listener Global"
		else
			startGlobalListener()
			toggleBtn.Text = "Desactivar Listener Global"
		end
	end)
end

local function showMainMenu()
	clearContent()
	navStack = {}

	local services = {
		{label = "Workspace", ref = workspace},
		{label = "ReplicatedStorage", ref = game:GetService("ReplicatedStorage")},
		{label = "Players", ref = game:GetService("Players")},
		{label = "StarterPack", ref = game:GetService("StarterPack")},
		{label = "Lighting", ref = game:GetService("Lighting")},
		{label = "ServerScriptService", ref = game:GetService("ServerScriptService")},
	}

	for i, svc in ipairs(services) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -20, 0, 35)
		button.Position = UDim2.new(0, 10, 0, (i - 1) * 40)
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		button.TextColor3 = green
		button.Text = "[ " .. i .. " ] " .. svc.label
		button.Font = Enum.Font.Code
		button.TextSize = 20
		button.Parent = contentFrame

		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = hover
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)

		button.MouseButton1Click:Connect(function()
			table.insert(navStack, showMainMenu)
			showObjectContents(svc.ref, svc.label)
		end)
	end

	-- Botón para listener global
	local listenerBtn = Instance.new("TextButton")
	listenerBtn.Size = UDim2.new(1, -20, 0, 35)
	listenerBtn.Position = UDim2.new(0, 10, 0, #services * 40 + 10)
	listenerBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	listenerBtn.TextColor3 = green
	listenerBtn.Text = "[*] Listener Global Remotes"
	listenerBtn.Font = Enum.Font.Code
	listenerBtn.TextSize = 20
	listenerBtn.Parent = contentFrame

	listenerBtn.MouseEnter:Connect(function()
		listenerBtn.BackgroundColor3 = hover
	end)
	listenerBtn.MouseLeave:Connect(function()
		listenerBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end)

	listenerBtn.MouseButton1Click:Connect(function()
		table.insert(navStack, showMainMenu)
		showGlobalListenerToggle()
	end)
end

showMainMenu()
