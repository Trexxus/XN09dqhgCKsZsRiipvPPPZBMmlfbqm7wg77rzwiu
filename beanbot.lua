local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local plrs = game:GetService("Players")
local stats = game:GetService("Stats")

local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1

local library = {
    connections = {},
    accents = {},
    drawings = {},
    hidden = {},
    pointers = {},
    flags = {},
    preloaded_images = {},
    loaded = false
}

makefolder("beanbot")
makefolder("beanbot/Da Hood")
makefolder("beanbot/Da Hood/configs")

local esp_stuff = {}

local r6_dummy = game:GetObjects("rbxassetid://9474737816")[1]
r6_dummy.Head.Face:Destroy()

for i, v in pairs(r6_dummy:GetChildren()) do
    v.Transparency = v.Name == "HumanoidRootPart" and 1 or 0.88
    v.Material = "Neon"
    v.Color = Color3.fromRGB(255, 0, 0)
    v.CanCollide = false
    v.Anchored = false
end

local utility = {}

do
    function utility:Draw(class, offset, properties, hidden)
        hidden = hidden or false

        local draw = Drawing.new(class)
        local fakeDraw = {}
        rawset(fakeDraw, "__OBJECT_EXIST", true)
        setmetatable(fakeDraw, {
            __index = function(self, key)
                if rawget(fakeDraw, "__OBJECT_EXIST") then
                    return draw[key]
                end
            end,
            __newindex = function(self, key, value)
                if rawget(fakeDraw, "__OBJECT_EXIST") then
                    draw[key] = value
                    if key == "Position" then
                        for _, v in pairs(rawget(fakeDraw, "children")) do
                            v.Position = fakeDraw.Position + v.GetOffset()
                        end
                    end
                end
            end
        })
        rawset(fakeDraw, "Remove", function()
            if rawget(fakeDraw, "__OBJECT_EXIST") then
                draw:Remove()
                rawset(fakeDraw, "__OBJECT_EXIST", false)
            end
        end)
        rawset(fakeDraw, "GetType", function()
            return class
        end)
        rawset(fakeDraw, "GetOffset", function()
            return offset or Vector2.new()
        end)
        rawset(fakeDraw, "SetOffset", function(noffset)
            offset = noffset or Vector2.new()

            fakeDraw.Position = properties.Parent.Position + fakeDraw.GetOffset()
        end)
        rawset(fakeDraw, "children", {})
        rawset(fakeDraw, "Lerp", function(instanceTo, instanceTime)
            if not rawget(fakeDraw, "__OBJECT_EXIST") then return end

            local currentTime = 0
            local currentIndex = {}
            local connection
            
            for i,v in pairs(instanceTo) do
                currentIndex[i] = fakeDraw[i]
            end
            
            local function lerp()
                for i,v in pairs(instanceTo) do
                    fakeDraw[i] = ((v - currentIndex[i]) * currentTime / instanceTime) + currentIndex[i]
                end
            end
            
            connection = rs.RenderStepped:Connect(function(delta)
                if currentTime < instanceTime then
                    currentTime = currentTime + delta
                    lerp()
                else
                    connection:Disconnect()
                end
            end)

            table.insert(library.connections, connection)
        end)

        local customProperties = {
            ["Parent"] = function(object)
                table.insert(rawget(object, "children"), fakeDraw)
            end
        }

        if class == "Square" then
            fakeDraw.Thickness = 1
            fakeDraw.Filled = true
        end

        fakeDraw.Visible = library.loaded
        if properties ~= nil then
            for key, value in pairs(properties) do
                if customProperties[key] == nil then
                    fakeDraw[key] = value
                else
                    customProperties[key](value)
                end
            end
            if properties.Parent then
                fakeDraw.Position = properties.Parent.Position + fakeDraw.GetOffset()
            end
            if properties.Parent and properties.From then
                fakeDraw.From = properties.Parent.Position + fakeDraw.GetOffset()
            end
            if properties.Parent and properties.To then
                fakeDraw.To = properties.Parent.Position + fakeDraw.GetOffset()
            end
        end

        if not library.loaded and not hidden then
            fakeDraw.Transparency = 0
        end

        if not hidden then
            table.insert(library.drawings, {fakeDraw, properties["Transparency"] or 1})
        else
            table.insert(library.hidden, {fakeDraw, properties["Transparency"] or 1})
        end

        return fakeDraw
    end

    function utility:ScreenSize()
        return workspace.CurrentCamera.ViewportSize
    end

    function utility:RoundVector(vector)
        return Vector2.new(math.floor(vector.X), math.floor(vector.Y))
    end

    function utility:MouseOverDrawing(object)
        local values = {object.Position, object.Position + object.Size}
        local mouseLocation = uis:GetMouseLocation()
        return mouseLocation.X >= values[1].X and mouseLocation.Y >= values[1].Y and mouseLocation.X <= values[2].X and mouseLocation.Y <= values[2].Y
    end

    function utility:MouseOverPosition(values)
        local mouseLocation = uis:GetMouseLocation()
        return mouseLocation.X >= values[1].X and mouseLocation.Y >= values[1].Y and mouseLocation.X <= values[2].X and mouseLocation.Y <= values[2].Y
    end

    function utility:Image(object, link)
        local data = library.preloaded_images[link] or game:HttpGet(link)
        if library.preloaded_images[link] == nil then
            library.preloaded_images[link] = data
        end
        object.Data = data
    end

    function utility:Connect(connection, func)
        local con = connection:Connect(func)
        table.insert(library.connections, con)
        return con
    end

    function utility:Combine(t1, t2)
        local t3 = {}
        for i, v in pairs(t1) do
            table.insert(t3, v)
        end
        for i, v in pairs(t2) do
            table.insert(t3, v)
        end
        return t3
    end

    function utility:GetTextSize(text, font, size)
        local textlabel = Drawing.new("Text")
        textlabel.Size = size
        textlabel.Font = font
        textlabel.Text = text
        local bounds = textlabel.TextBounds
        textlabel:Remove()
        return bounds
    end

    function utility:RemoveItem(tbl, item)
        local newtbl = {}
        for i, v in pairs(tbl) do
            if v ~= item then
                table.insert(newtbl, v)
            end
        end
        return newtbl
    end

    function utility:CopyTable(tbl)
        local newtbl = {}
        for i, v in pairs(tbl) do
            newtbl[i] = v
        end
        return newtbl
    end

    function utility.EspAddPlayer(plr)
        esp_stuff[plr] = {
            Box = utility:Draw("Square", Vector2.new(), {Visible = false, Filled = false, ZIndex = 2}, true),
            BoxOutline = utility:Draw("Square", Vector2.new(), {Visible = false, Filled = false, Thickness = 3, ZIndex = 1}, true),
            Health = utility:Draw("Square", Vector2.new(), {Visible = false, ZIndex = 2}, true),
            HealthOutline = utility:Draw("Square", Vector2.new(), {Visible = false, ZIndex = 1}, true),
            Name = utility:Draw("Text", Vector2.new(), {Size = 13, Font = 2, Text = plr.Name, Outline = true, Center = true, Visible = false, ZIndex = 1}, true),
        }
    end

    function utility.EspRemovePlayer(plr)
        if esp_stuff[plr] then
            for i, v in pairs(esp_stuff[plr]) do
                v.Remove()
            end
            esp_stuff[plr] = nil
        end
    end
end

for _, plr in pairs(game.Players:GetPlayers()) do
    utility.EspAddPlayer(plr)
end

utility:Connect(game.Players.PlayerAdded, utility.EspAddPlayer)
utility:Connect(game.Players.PlayerRemoving, utility.EspRemovePlayer)


function library:New(args)
    args = args or {}

    local name = args.name or args.Name or "bbot ui"
    local accent1 = args.accent1 or args.Accent1 or Color3.fromRGB(127, 72, 163)
    local accent2 = args.accent2 or args.Accent2 or Color3.fromRGB(87, 32, 123)

    local window = {name = name, tabs = {}, visible = false, fading = false, togglekey = "Insert", dragging = false, startPos = nil, content = {dropdown = nil, colorpicker = nil, keybind = nil}}

    local window_frame = utility:Draw("Square", nil, {
        Color = Color3.fromRGB(35, 35, 35),
        Size = Vector2.new(496, 596),
        Position = utility:RoundVector(utility:ScreenSize() / 2) - Vector2.new(248, 298)
    })

    utility:Draw("Square", Vector2.new(-1, -1), {
        Color = Color3.fromRGB(20, 20, 20),
        Size = window_frame.Size + Vector2.new(2, 2),
        Filled = false,
        Parent = window_frame
    })

    utility:Draw("Square", Vector2.new(-2, -2), {
        Color = Color3.fromRGB(0, 0, 0),
        Size = window_frame.Size + Vector2.new(4, 4),
        Filled = false,
        Parent = window_frame
    })

    table.insert(library.accents, utility:Draw("Square", Vector2.new(0, 1), {
        Color = accent1,
        Size = Vector2.new(window_frame.Size.X, 1),
        Parent = window_frame
    }))

    table.insert(library.accents, utility:Draw("Square", Vector2.new(0, 2), {
        Color = accent2,
        Size = Vector2.new(window_frame.Size.X, 1),
        Parent = window_frame
    }))

    utility:Draw("Square", Vector2.new(0, 3), {
        Color = Color3.fromRGB(20, 20, 20),
        Size = Vector2.new(window_frame.Size.X, 1),
        Parent = window_frame
    })

    local title = utility:Draw("Text", Vector2.new(4, 6), {
        Color = Color3.fromRGB(255, 255, 255),
        Outline = true,
        Size = 13,
        Font = 2,
        Text = name,
        Parent = window_frame
    })

    local tabs_frame = utility:Draw("Square", Vector2.new(8, 23), {
        Color = Color3.fromRGB(35, 35, 35),
        Size = Vector2.new(480, 566),
        Parent = window_frame
    })

    utility:Draw("Square", Vector2.new(-1, -1), {
        Color = Color3.fromRGB(20, 20, 20),
        Size = tabs_frame.Size + Vector2.new(2, 2),
        Filled = false,
        Parent = tabs_frame
    })

    utility:Draw("Square", Vector2.new(-2, -2), {
        Color = Color3.fromRGB(0, 0, 0),
        Size = tabs_frame.Size + Vector2.new(4, 4),
        Filled = false,
        Parent = tabs_frame
    })

    table.insert(library.accents, utility:Draw("Square", Vector2.new(0, 1), {
        Color = accent1,
        Size = Vector2.new(tabs_frame.Size.X, 1),
        Parent = tabs_frame
    }))

    table.insert(library.accents, utility:Draw("Square", Vector2.new(0, 2), {
        Color = accent2,
        Size = Vector2.new(tabs_frame.Size.X, 1),
        Parent = tabs_frame
    }))

    utility:Draw("Square", Vector2.new(0, 3), {
        Color = Color3.fromRGB(20, 20, 20),
        Size = Vector2.new(tabs_frame.Size.X, 1),
        Parent = tabs_frame
    })

    local tab_content = utility:Draw("Square", Vector2.new(1, 37), {
        Color = Color3.fromRGB(35, 35, 35),
        Size = Vector2.new(478, 528),
        Parent = tabs_frame
    })

    utility:Draw("Square", Vector2.new(-1, -1), {
        Color = Color3.fromRGB(20, 20, 20),
        Size = tab_content.Size + Vector2.new(2, 2),
        Filled = false,
        Parent = tab_content
    })

    utility:Connect(uis.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverPosition({window_frame.Position, window_frame.Position + Vector2.new(window_frame.Size.X, 22)}) and window_frame.Visible and not window.fading then
            window.dragging = true
            window.startPos = uis:GetMouseLocation() - window_frame.Position
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode.Name == window.togglekey then
                window:Toggle()
            end
        end
    end)

    utility:Connect(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end)

    utility:Connect(rs.RenderStepped, function()
        if window.dragging then
            window_frame.Position = uis:GetMouseLocation() - window.startPos
        end
    end)

    function window:Toggle()
        if window.fading then return end
        window:CloseContent()
        if window_frame.Visible then
            for i, v in pairs(library.drawings) do
                v[1].Lerp({Transparency = 0}, 0.25)
                delay(0.25, function()
                    v[1].Visible = false
                end)
            end
            window.fading = true
            delay(0.25, function()
                window.fading = false
            end)
        else
            local lerp_tick = tick()
            for i, v in pairs(library.drawings) do
                v[1].Visible = true
                v[1].Lerp({Transparency = v[2]}, 0.25)
            end
            local connection connection = utility:Connect(rs.RenderStepped, function()
                if tick()-lerp_tick < 1/4 then
                    window:UpdateTabs()
                else
                    connection:Disconnect()
                end
            end)
            window.fading = true
            delay(0.25, function()
                window.fading = false
                window:UpdateTabs()
            end)
        end
        window.visible = not window.visible
    end

    function window:Tab(args)
        args = args or {}

        local name = args.name or args.Name or "Tab"

        local tab = {name = name, sections = {}, sectionOffsets = {left = 0, right = 0}, open = false, instances = {}}

        if #window.tabs >= 5 then return end

        local tab_frame = utility:Draw("Square", Vector2.new(1 + (96 * #window.tabs), 5), {
            Color = Color3.fromRGB(30, 30, 30),
            Size = Vector2.new(94, 30),
            Parent = tabs_frame
        })

        local outline = utility:Draw("Square", Vector2.new(-1, -1), {
            Color = Color3.fromRGB(20, 20, 20),
            Size = tab_frame.Size + Vector2.new(2, 2),
            Filled = false,
            Parent = tab_frame
        })

        local tab_gradient = utility:Draw("Image", Vector2.new(), {
            Size = tab_frame.Size,
            Visible = false,
            Transparency = 0.65,
            Parent = tab_frame
        })

        local tab_title = utility:Draw("Text", Vector2.new(47, 7), {
            Color = Color3.fromRGB(255, 255, 255),
            Outline = true,
            Size = 13,
            Font = 2,
            Text = name,
            Center = true,
            Parent = tab_frame
        })

        local outline_hider = utility:Draw("Square", Vector2.new(0, 30), {
            Color = Color3.fromRGB(35, 35, 35),
            Size = Vector2.new(tab_frame.Size.X, 2),
            Visible = false,
            Parent = tab_frame
        })

        utility:Image(tab_gradient, "https://i.imgur.com/5hmlrjX.png")

        utility:Connect(uis.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverDrawing(tab_frame) and not window.fading then
                window:SetTab(name)
            end
        end)

        tab.instances = {tab_frame, outline, tab_gradient, tab_title, outline_hider}

        table.insert(window.tabs, tab)

        function tab:Show()
            window:CloseContent()

            tab_frame.Color = Color3.fromRGB(50, 50, 50)
            tab_gradient.Visible = true
            outline_hider.Visible = true

            for i, v in pairs(tab.sections) do
                for i2, v2 in pairs(v.instances) do
                    v2.Visible = true
                end
            end
        end

        function tab:Hide()
            window:CloseContent()

            tab_frame.Color = Color3.fromRGB(30, 30, 30)
            tab_gradient.Visible = false
            outline_hider.Visible = false

            for i, v in pairs(tab.sections) do
                for i2, v2 in pairs(v.instances) do
                    v2.Visible = false
                end
            end
        end

        function tab:GetSecionPosition(side)
            local default = Vector2.new(side == "left" and 9 or side == "right" and 245, 9 + tab.sectionOffsets[side])
            return default
        end

        function tab:Section(args)
            args = args or {}

            local name = args.name or args.Name or "section"
            local side = (args.side or args.Side or "left"):lower()

            local section = {name = name, side = side, offset = 0, instances = {}}

            local section_frame = utility:Draw("Square", tab:GetSecionPosition(side), {
                Color = Color3.fromRGB(35, 35, 35),
                Size = Vector2.new(226, 15),
                Parent = tab_content
            })

            local section_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                Color = Color3.fromRGB(20, 20, 20),
                Size = section_frame.Size + Vector2.new(2, 2),
                Filled = false,
                Parent = section_frame
            })

            local section_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                Color = Color3.fromRGB(0, 0, 0),
                Size = section_frame.Size + Vector2.new(4, 4),
                Filled = false,
                Parent = section_frame
            })

            local section_title = utility:Draw("Text", Vector2.new(4, 4), {
                Color = Color3.fromRGB(255, 255, 255),
                Outline = true,
                Size = 13,
                Font = 2,
                Text = name,
                Parent = section_frame
            })

            local section_accent1 = utility:Draw("Square", Vector2.new(0, 1), {
                Color = accent1,
                Size = Vector2.new(section_frame.Size.X, 1),
                Parent = section_frame
            })

            table.insert(library.accents, section_accent1)
        
            local section_accent2 = utility:Draw("Square", Vector2.new(0, 2), {
                Color = accent2,
                Size = Vector2.new(section_frame.Size.X, 1),
                Parent = section_frame
            })

            table.insert(library.accents, section_accent2)
        
            local section_inline2 = utility:Draw("Square", Vector2.new(0, 3), {
                Color = Color3.fromRGB(20, 20, 20),
                Size = Vector2.new(section_frame.Size.X, 1),
                Parent = section_frame
            })

            tab.sectionOffsets[side] = tab.sectionOffsets[side] + 27

            section.instances = {section_frame, section_inline, section_outline, section_title, section_accent1, section_accent2, section_inline2}

            table.insert(tab.sections, section)

            function section:Update()
                task.wait()
                section_frame.Size = Vector2.new(226, 28 + section.offset)
                section_inline.Size = section_frame.Size + Vector2.new(2, 2)
                section_outline.Size = section_frame.Size + Vector2.new(4, 4)
            end

            function section:Toggle(args)
                args = args or {}

                local name = args.name or args.Name or "toggle"
                local default = args.default or args.Default or args.def or args.Def or false
                local callback = args.callback or args.Callback or function() end
                local flag = args.flag or args.Flag or ""
                local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. name

                local toggle = {name = name, state = false, colorpicker = {}, keybind = {}}

                local toggle_frame = utility:Draw("Square", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(50, 50, 50),
                    Size = Vector2.new(8, 8),
                    Parent = section_frame
                })

                table.insert(library.accents, toggle_frame)

                local toggle_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = toggle_frame.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = toggle_frame
                })

                local toggle_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                    Color = Color3.fromRGB(30, 30, 30),
                    Size = toggle_frame.Size + Vector2.new(4, 4),
                    Filled = false,
                    Parent = toggle_frame
                })

                local toggle_gradient = utility:Draw("Image", Vector2.new(), {
                    Size = toggle_frame.Size,
                    Transparency = 0.8,
                    Parent = toggle_frame
                })

                local toggle_title = utility:Draw("Text", Vector2.new(15, -3), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Parent = toggle_frame
                })

                utility:Image(toggle_gradient, "https://i.imgur.com/5hmlrjX.png")

                function toggle:Set(value)
                    toggle.state = value
                    toggle_frame.Color = toggle.state == true and accent1 or Color3.fromRGB(50, 50, 50)

                    if flag ~= "" then
                        library.flags[flag] = toggle.state
                    end

                    callback(toggle.state)
                end

                function toggle:Get()
                    return toggle.state
                end

                function toggle:Keybind(args)
                    if #toggle.colorpicker > 0 then return end

                    args = args or {}

                    local kname = args.name or args.Name or args.kname or args.Kname or toggle.name
                    local default = (args.default or args.Default or args.def or args.Def or "..."):upper()
                    local kpointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. toggle.name .. "_keybind"
                    local callback = args.callback or args.Callback or function() end

                    local keybind = {name = kname, value = default, binding = false, mode = "Toggle", content = {}}

                    local keybind_frame = utility:Draw("Square", Vector2.new(171, -1), {
                        Color = Color3.fromRGB(25, 25, 25),
                        Size = Vector2.new(40, 12),
                        Parent = toggle_frame
                    })

                    local keybind_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                        Color = Color3.fromRGB(0, 0, 0),
                        Size = keybind_frame.Size + Vector2.new(2, 2),
                        Filled = false,
                        Parent = keybind_frame
                    })
    
                    local keybind_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                        Color = Color3.fromRGB(30, 30, 30),
                        Size = keybind_frame.Size + Vector2.new(4, 4),
                        Filled = false,
                        Parent = keybind_frame
                    })

                    local keybind_value = utility:Draw("Text", Vector2.new(21, -1), {
                        Color = Color3.fromRGB(255, 255, 255),
                        Outline = true,
                        Size = 13,
                        Font = 2,
                        Text = default,
                        Center = true,
                        Parent = keybind_frame
                    })

                    local shortenedInputs = {["Insert"] = "INS", ["Home"] = "HOME", ["LeftAlt"] = "LALT", ["LeftControl"] = "LC", ["LeftShift"] = "LS", ["RightAlt"] = "RALT", ["RightControl"] = "RC", ["RightShift"] = "RS", ["CapsLock"] = "CAPS", ["Delete"] = "DEL", ["PageUp"] = "PUP", ["PageDown"] = "PDO", ["Space"] = "SPACE"}

                    function keybind:Set(value)
                        keybind.value = value
                        keybind_value.Text = keybind.value
                        callback(keybind.value)
                    end

                    function keybind:Get()
                        return keybind.value
                    end

                    utility:Connect(uis.InputBegan, function(input)
                        if not keybind.binding then
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                if not window:MouseOverContent() and not window.fading and tab.open then
                                    if #keybind.content > 0 then
                                        window:CloseContent()
                                        keybind.content = {}
                                    end
                                    if utility:MouseOverDrawing(keybind_frame) then
                                        keybind.binding = true
                                        keybind_value.Text = "..."
                                    end
                                elseif #keybind.content > 0 and window:MouseOverContent() and not window.fading and tab.open then
                                    for i, v in pairs({"Always", "Hold", "Toggle"}) do
                                        if utility:MouseOverPosition({keybind.content[1].Position + Vector2.new(0, 15 * (i - 1)), keybind.content[1].Position + Vector2.new(keybind.content[1].Size.X, 15 * i )}) then
                                            keybind.mode = v
                                            keybind.content[4 + i].Color = accent1
                                        else
                                            keybind.content[4 + i].Color = Color3.fromRGB(255, 255, 255)
                                        end
                                    end
                                end
                            elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == keybind.value then
                                if #keybind.content > 0 then
                                    window:CloseContent()
                                    keybind.content = {}
                                end
                                if keybind.mode == "Toggle" then
                                    toggle:Set(not toggle.state)
                                else
                                    toggle:Set(true)
                                end
                                if library.loaded then
                                    if toggle.state then
                                        window.keybinds:Add(string.format("[%s] " .. section.name .. ": " .. keybind.name, shortenedInputs[keybind.value] or keybind.value:upper()))
                                    else
                                        window.keybinds:Remove(string.format("[%s] " .. section.name .. ": " .. keybind.name, shortenedInputs[keybind.value] or keybind.value:upper()))
                                    end
                                end
                            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                                if utility:MouseOverDrawing(keybind_frame) and not window:MouseOverContent() and not window.fading and tab.open then
                                    local keybind_open_frame = utility:Draw("Square", Vector2.new(45, -17), {
                                        Color = Color3.fromRGB(50, 50, 50),
                                        Size = Vector2.new(68, 45),
                                        Parent = keybind_frame
                                    })

                                    local keybind_open_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                        Color = Color3.fromRGB(20, 20, 20),
                                        Size = keybind_open_frame.Size + Vector2.new(2, 2),
                                        Filled = false,
                                        Parent = keybind_open_frame
                                    })

                                    local keybind_open_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Size = keybind_open_frame.Size + Vector2.new(4, 4),
                                        Filled = false,
                                        Parent = keybind_open_frame
                                    })

                                    local keybind_open_gradient = utility:Draw("Image", Vector2.new(), {
                                        Size = keybind_open_frame.Size,
                                        Transparency = 0.65,
                                        Parent = keybind_open_frame
                                    })

                                    utility:Image(keybind_open_gradient, "https://i.imgur.com/5hmlrjX.png")

                                    keybind.content = {keybind_open_frame, keybind_open_inline, keybind_open_outline, keybind_open_gradient}

                                    for i, v in pairs({"Always", "Hold", "Toggle"}) do
                                        local mode = utility:Draw("Text", Vector2.new(34, (15 * (i-1))), {
                                            Color = keybind.mode == v and accent1 or Color3.fromRGB(255, 255, 255),
                                            Outline = true,
                                            Size = 13,
                                            Font = 2,
                                            Text = v,
                                            Center = true,
                                            Parent = keybind_open_frame
                                        })

                                        table.insert(keybind.content, mode)
                                    end

                                    window.content.keybind = keybind.content
                                end 
                            end
                        else
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                if input.KeyCode.Name ~= "Escape" and input.KeyCode.Name ~= "Backspace" then
                                    keybind.binding = false
                                    keybind.value = input.KeyCode.Name
                                    keybind_value.Text = shortenedInputs[keybind.value] or keybind.value:upper()
                                else
                                    keybind.binding = false
                                    keybind_value.Text = shortenedInputs[keybind.value] or keybind.value:upper()
                                end
                            end
                        end
                    end)

                    utility:Connect(uis.InputEnded, function(input)
                        if not keybind.binding and input.UserInputType == Enum.UserInputType.Keyboard and keybind.mode == "Hold" and input.KeyCode.Name == keybind.value then
                            toggle:Set(false)
                            if library.loaded then
                                window.keybinds:Remove(string.format("[%s] " .. section.name .. ": " .. keybind.name, shortenedInputs[keybind.value] or keybind.value:upper()))
                            end
                        end
                    end)

                    toggle.keybind = keybind

                    library.pointers[pointer] = keybind

                    section.instances = utility:Combine(section.instances, {keybind_frame, keybind_inline, keybind_outline, keybind_value})
                end

                function toggle:Colorpicker(args)
                    if #toggle.keybind > 0 then return end

                    args = args or {}

                    local cname = args.name or args.Name or "colorpicker"
                    local default = args.default or args.Default or args.def or args.Def or Color3.fromRGB(255, 0, 0)
                    local flag = args.flag or args.Flag or ""
                    local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. toggle.name .. "_colorpicker"
                    local callback = args.callback or args.Callback or function() end

                    local colorpicker = {name = cname, value = {default:ToHSV()}, tempvalue = {}, brightness = {100, 0}, holding = {hue = false, brightness = false, color = false}, content = {}}

                    if flag ~= "" then
                        library.flags[flag] = default
                    end

                    local colorpicker_color = utility:Draw("Square", Vector2.new(section_frame.Size.X - 45, -1), {
                        Color = default,
                        Size = Vector2.new(24, 10),
                        Parent = toggle_frame
                    })

                    local colorpciker_inline1 = utility:Draw("Square", Vector2.new(), {
                        Color = Color3.fromRGB(0, 0, 0),
                        Size = colorpicker_color.Size,
                        Transparency = 0.3,
                        Filled = false,
                        Parent = colorpicker_color
                    })

                    local colorpciker_inline2 = utility:Draw("Square", Vector2.new(1, 1), {
                        Color = Color3.fromRGB(0, 0, 0),
                        Size = colorpicker_color.Size - Vector2.new(2, 2),
                        Transparency = 0.3,
                        Filled = false,
                        Parent = colorpicker_color
                    })

                    local colorpicker_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                        Color = Color3.fromRGB(0, 0, 0),
                        Size = colorpicker_color.Size + Vector2.new(2, 2),
                        Filled = false,
                        Parent = colorpicker_color
                    })

                    function colorpicker:Set(value)
                        if typeof(value) == "Color3" then
                            value = {value:ToHSV()}
                        end

                        colorpicker.value = value
                        colorpicker_color.Color = Color3.fromHSV(unpack(colorpicker.value))

                        if flag ~= "" then
                            library.flags[flag] = Color3.fromHSV(unpack(colorpicker.value))
                        end

                        callback(Color3.fromHSV(unpack(colorpicker.value)))
                    end

                    function colorpicker:Get()
                        return Color3.fromHSV(unpack(colorpicker.value))
                    end

                    utility:Connect(uis.InputBegan, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if #colorpicker.content == 0 and utility:MouseOverDrawing(colorpicker_color) and not window:MouseOverContent() and not window.fading and tab.open then
                                colorpicker.tempvalue = colorpicker.value
                                colorpicker.brightness[2] = 0
                                
                                local colorpicker_open_frame = utility:Draw("Square", Vector2.new(12, 5), {
                                    Color = Color3.fromRGB(35, 35, 35),
                                    Size = Vector2.new(276, 207),
                                    Parent = colorpicker_color
                                })

                                local colorpicker_open_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(20, 20, 20),
                                    Size = colorpicker_open_frame.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_frame.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_accent1 = utility:Draw("Square", Vector2.new(0, 1), {
                                    Color = accent1,
                                    Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                    Parent = colorpicker_open_frame
                                })

                                table.insert(library.accents, colorpicker_open_accent1)
                            
                                local colorpicker_open_accent2 = utility:Draw("Square", Vector2.new(0, 2), {
                                    Color = accent2,
                                    Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                    Parent = colorpicker_open_frame
                                })

                                table.insert(library.accents, colorpicker_open_accent2)
                            
                                local colorpicker_open_inline2 = utility:Draw("Square", Vector2.new(0, 3), {
                                    Color = Color3.fromRGB(20, 20, 20),
                                    Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_title = utility:Draw("Text", Vector2.new(5, 6), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Outline = true,
                                    Size = 13,
                                    Font = 2,
                                    Text = colorpicker.name,
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_apply = utility:Draw("Text", Vector2.new(232, 187), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Outline = true,
                                    Size = 13,
                                    Font = 2,
                                    Text = "[ Apply ]",
                                    Center = true,
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_color = utility:Draw("Square", Vector2.new(10, 23), {
                                    Color = Color3.fromHSV(colorpicker.value[1], 1, 1),
                                    Size = Vector2.new(156, 156),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_color_image = utility:Draw("Image", Vector2.new(), {
                                    Size = colorpicker_open_color.Size,
                                    Parent = colorpicker_open_color
                                })

                                local colorpicker_open_color_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_color.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_color
                                })

                                local colorpicker_open_color_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(30, 30, 30),
                                    Size = colorpicker_open_color.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_color
                                })

                                local colorpicker_open_brightness_image = utility:Draw("Image", Vector2.new(10, 189), {
                                    Size = Vector2.new(156, 10),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_brightness_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_brightness_image.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_brightness_image
                                })

                                local colorpicker_open_brightness_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(30, 30, 30),
                                    Size = colorpicker_open_brightness_image.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_brightness_image
                                })

                                local colorpicker_open_hue_image = utility:Draw("Image", Vector2.new(176, 23), {
                                    Size = Vector2.new(10, 156),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_hue_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_hue_image.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_hue_image
                                })

                                local colorpicker_open_hue_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(30, 30, 30),
                                    Size = colorpicker_open_hue_image.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_hue_image
                                })

                                local colorpicker_open_newcolor_title = utility:Draw("Text", Vector2.new(196, 23), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Outline = true,
                                    Size = 13,
                                    Font = 2,
                                    Text = "New color",
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_newcolor_image = utility:Draw("Image", Vector2.new(197, 37), {
                                    Size = Vector2.new(71, 36),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_newcolor_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_newcolor_image.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_newcolor_image
                                })

                                local colorpicker_open_newcolor_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(30, 30, 30),
                                    Size = colorpicker_open_newcolor_image.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_newcolor_image
                                })

                                local colorpicker_open_newcolor = utility:Draw("Square", Vector2.new(2, 2), {
                                    Color = Color3.fromHSV(unpack(colorpicker.value)),
                                    Size = colorpicker_open_newcolor_image.Size - Vector2.new(4, 4),
                                    Transparency = 0.4,
                                    Parent = colorpicker_open_newcolor_image
                                })

                                local colorpicker_open_oldcolor_title = utility:Draw("Text", Vector2.new(196, 76), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Outline = true,
                                    Size = 13,
                                    Font = 2,
                                    Text = "Old color",
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_oldcolor_image = utility:Draw("Image", Vector2.new(197, 91), {
                                    Size = Vector2.new(71, 36),
                                    Parent = colorpicker_open_frame
                                })

                                local colorpicker_open_oldcolor_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_oldcolor_image.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_oldcolor_image
                                })

                                local colorpicker_open_oldcolor_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                    Color = Color3.fromRGB(30, 30, 30),
                                    Size = colorpicker_open_oldcolor_image.Size + Vector2.new(4, 4),
                                    Filled = false,
                                    Parent = colorpicker_open_oldcolor_image
                                })

                                local colorpicker_open_oldcolor = utility:Draw("Square", Vector2.new(2, 2), {
                                    Color = Color3.fromHSV(unpack(colorpicker.value)),
                                    Size = colorpicker_open_oldcolor_image.Size - Vector2.new(4, 4),
                                    Transparency = 0.4,
                                    Parent = colorpicker_open_oldcolor_image
                                })

                                local colorpicker_open_color_holder = utility:Draw("Square", Vector2.new(colorpicker_open_color_image.Size.X - 5, 0), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Size = Vector2.new(5, 5),
                                    Filled = false,
                                    Parent = colorpicker_open_color_image
                                })

                                local colorpicker_open_color_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_color_holder.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_color_holder
                                })

                                local colorpicker_open_hue_holder = utility:Draw("Square", Vector2.new(-1, 0), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Size = Vector2.new(12, 3),
                                    Filled = false,
                                    Parent = colorpicker_open_hue_image
                                })

                                colorpicker_open_hue_holder.Position = Vector2.new(colorpicker_open_hue_image.Position.X-1, colorpicker_open_hue_image.Position.Y + colorpicker.tempvalue[1] * colorpicker_open_hue_image.Size.Y)

                                local colorpicker_open_hue_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_hue_holder.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_hue_holder
                                })

                                local colorpicker_open_brightness_holder = utility:Draw("Square", Vector2.new(colorpicker_open_brightness_image.Size.X, -1), {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Size = Vector2.new(3, 12),
                                    Filled = false,
                                    Parent = colorpicker_open_brightness_image
                                })

                                colorpicker_open_brightness_holder.Position = Vector2.new(colorpicker_open_brightness_image.Position.X + colorpicker_open_brightness_image.Size.X * (colorpicker.brightness[1] / 100), colorpicker_open_brightness_image.Position.Y-1)

                                local colorpicker_open_brightness_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Size = colorpicker_open_brightness_holder.Size + Vector2.new(2, 2),
                                    Filled = false,
                                    Parent = colorpicker_open_brightness_holder
                                })

                                utility:Image(colorpicker_open_color_image, "https://i.imgur.com/wpDRqVH.png")
                                utility:Image(colorpicker_open_brightness_image, "https://tr.rbxcdn.com/cf80cdea88fd9bbdb4037ab352260726/420/420/Image/Png")
                                utility:Image(colorpicker_open_hue_image, "https://i.imgur.com/iEOsHFv.png")
                                utility:Image(colorpicker_open_newcolor_image, "https://images-ext-1.discordapp.net/external/Nc7u8ZAc9yYabSDkX2zn48MdXjh0BL3KswXDknMm97w/https/media.discordapp.net/attachments/942749250897477662/980791504954093588/unknown.png")
                                utility:Image(colorpicker_open_oldcolor_image, "https://images-ext-1.discordapp.net/external/Nc7u8ZAc9yYabSDkX2zn48MdXjh0BL3KswXDknMm97w/https/media.discordapp.net/attachments/942749250897477662/980791504954093588/unknown.png")

                                colorpicker.content = {colorpicker_open_frame, colorpicker_open_inline, colorpicker_open_outline, colorpicker_open_accent1, colorpicker_open_accent2, colorpicker_open_inline2, colorpicker_open_title, colorpicker_open_apply,
                                colorpicker_open_color, colorpicker_open_color_image, colorpicker_open_color_inline, colorpicker_open_color_outline, colorpicker_open_brightness_image, colorpicker_open_brightness_inline, colorpicker_open_brightness_outline,
                                colorpicker_open_hue_image, colorpicker_open_hue_inline, colorpicker_open_hue_outline, colorpicker_open_newcolor_title, colorpicker_open_newcolor_image, colorpicker_open_newcolor_inline, colorpicker_open_newcolor_outline,
                                colorpicker_open_newcolor, colorpicker_open_oldcolor_title, colorpicker_open_oldcolor_image, colorpicker_open_oldcolor_inline, colorpicker_open_oldcolor_outline, colorpicker_open_oldcolor, colorpicker_open_hue_holder_outline,
                                colorpicker_open_brightness_holder_outline, colorpicker_open_color_holder_outline, colorpicker_open_color_holder, colorpicker_open_hue_holder, colorpicker_open_brightness_holder}

                                window.content.colorpicker = colorpicker.content

                            elseif #colorpicker.content > 0 and not window:MouseOverContent() and not window.fading and tab.open then
                                window:CloseContent()
                                colorpicker.content = {}
                                for i, v in pairs(colorpicker.holding) do
                                    colorpicker.holding[i] = false
                                end
                            elseif #colorpicker.content > 0 and window:MouseOverContent() and not window.fadign and tab.open then
                                if utility:MouseOverDrawing(colorpicker.content[10]) then
                                    local colorx = math.clamp(uis:GetMouseLocation().X - colorpicker.content[10].Position.X, 0, colorpicker.content[10].Position.X) /colorpicker.content[10].Size.X
                                    local colory = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y
                                    local s = colorx
                                    local v = (colorpicker.brightness[1] / 100) - colory

                                    colorpicker.brightness[2] = colory

                                    colorpicker.tempvalue = {colorpicker.tempvalue[1], s, v}

                                    local minPos = Vector2.new(colorpicker.content[10].Position.X, colorpicker.content[10].Position.Y)
                                    local maxPos = Vector2.new(colorpicker.content[10].Position.X + colorpicker.content[10].Size.X - 5, colorpicker.content[10].Position.Y + colorpicker.content[10].Size.Y - 5)
                                    local holderPos = uis:GetMouseLocation()
                                    if holderPos.X > maxPos.X then
                                        holderPos = Vector2.new(maxPos.X, holderPos.Y)
                                    end 
                                    if holderPos.Y > maxPos.Y then
                                        holderPos = Vector2.new(holderPos.X, maxPos.Y)
                                    end
                                    if holderPos.X < minPos.X then
                                        holderPos = Vector2.new(minPos.X, holderPos.Y)
                                    end 
                                    if holderPos.Y < minPos.Y then
                                        holderPos = Vector2.new(holderPos.X, minPos.Y)
                                    end
                                    colorpicker.content[32].Position = holderPos

                                    colorpicker.holding.color = true
                                elseif utility:MouseOverDrawing(colorpicker.content[16]) then
                                    local hue = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[16].Position.Y, 0, colorpicker.content[16].Size.Y) / colorpicker.content[16].Size.Y

                                    colorpicker.tempvalue = {hue, colorpicker.tempvalue[2], colorpicker.tempvalue[3]}

                                    colorpicker.content[33].Position = Vector2.new(colorpicker.content[16].Position.X-1, colorpicker.content[16].Position.Y + colorpicker.tempvalue[1] * colorpicker.content[16].Size.Y)

                                    colorpicker.content[9].Color = Color3.fromHSV(colorpicker.tempvalue[1], 1, 1)

                                    colorpicker.holding.hue = true
                                elseif utility:MouseOverDrawing(colorpicker.content[13]) then
                                    local percent = math.clamp(uis:GetMouseLocation().X - colorpicker.content[13].Position.X, 0, colorpicker.content[13].Size.X) / colorpicker.content[13].Size.X

                                    colorpicker.brightness[1] = 100 * percent

                                    colorpicker.tempvalue[3] = (colorpicker.brightness[1] / 100) - colorpicker.brightness[2]

                                    colorpicker.content[34].Position = Vector2.new(colorpicker.content[13].Position.X + colorpicker.content[13].Size.X * (colorpicker.brightness[1] / 100), colorpicker.content[13].Position.Y-1)

                                    colorpicker.holding.brightness = true
                                elseif utility:MouseOverPosition({colorpicker.content[8].Position - Vector2.new(colorpicker.content[8].TextBounds.X / 2, 0), colorpicker.content[8].Position + Vector2.new(colorpicker.content[8].TextBounds.X / 2, 13)}) then
                                    colorpicker:Set(colorpicker.tempvalue)
                                    colorpicker.tempvalue = colorpicker.value
                                    colorpicker.content[28].Color = Color3.fromHSV(unpack(colorpicker.value))
                                end
                                colorpicker.content[23].Color = Color3.fromHSV(unpack(colorpicker.tempvalue))
                            end
                        end
                    end)

                    utility:Connect(uis.InputChanged, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement and #colorpicker.content > 0 then
                            if colorpicker.holding.color then
                                local colorx = math.clamp(uis:GetMouseLocation().X - colorpicker.content[10].Position.X, 0, colorpicker.content[10].Position.X) /colorpicker.content[10].Size.X
                                local colory = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y
                                local s = colorx
                                local v = (colorpicker.brightness[1] / 100) - colory

                                colorpicker.brightness[2] = colory

                                colorpicker.tempvalue = {colorpicker.tempvalue[1], s, v}

                                local minPos = Vector2.new(colorpicker.content[10].Position.X, colorpicker.content[10].Position.Y)
                                local maxPos = Vector2.new(colorpicker.content[10].Position.X + colorpicker.content[10].Size.X - 5, colorpicker.content[10].Position.Y + colorpicker.content[10].Size.Y - 5)
                                local holderPos = uis:GetMouseLocation()
                                if holderPos.X > maxPos.X then
                                    holderPos = Vector2.new(maxPos.X, holderPos.Y)
                                end 
                                if holderPos.Y > maxPos.Y then
                                    holderPos = Vector2.new(holderPos.X, maxPos.Y)
                                end
                                if holderPos.X < minPos.X then
                                    holderPos = Vector2.new(minPos.X, holderPos.Y)
                                end 
                                if holderPos.Y < minPos.Y then
                                    holderPos = Vector2.new(holderPos.X, minPos.Y)
                                end
                                colorpicker.content[32].Position = holderPos
                            elseif colorpicker.holding.hue then
                                local hue = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[16].Position.Y, 0, colorpicker.content[16].Size.Y) / colorpicker.content[16].Size.Y

                                colorpicker.tempvalue = {hue, colorpicker.tempvalue[2], colorpicker.tempvalue[3]}

                                colorpicker.content[33].Position = Vector2.new(colorpicker.content[16].Position.X-1, colorpicker.content[16].Position.Y + colorpicker.tempvalue[1] * colorpicker.content[16].Size.Y)

                                colorpicker.content[9].Color = Color3.fromHSV(colorpicker.tempvalue[1], 1, 1)
                            elseif colorpicker.holding.brightness then
                                local percent = math.clamp(uis:GetMouseLocation().X - colorpicker.content[13].Position.X, 0, colorpicker.content[13].Size.X) / colorpicker.content[13].Size.X
                                    
                                local colory = math.clamp(colorpicker.content[31].Position.Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y

                                colorpicker.brightness[1] = 100 * percent

                                colorpicker.tempvalue[3] = (colorpicker.brightness[1] / 100) - colorpicker.brightness[2]

                                colorpicker.content[34].Position = Vector2.new(colorpicker.content[13].Position.X + colorpicker.content[13].Size.X * (colorpicker.brightness[1] / 100), colorpicker.content[13].Position.Y-1)
                            end
                            colorpicker.content[23].Color = Color3.fromHSV(unpack(colorpicker.tempvalue))
                        end
                    end)

                    utility:Connect(uis.InputEnded, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and #colorpicker.content > 0 then
                            for i, v in pairs(colorpicker.holding) do
                                colorpicker.holding[i] = false
                            end
                        end
                    end)
                    
                    toggle.colorpicker = colorpicker

                    library.pointers[pointer] = colorpicker

                    section.instances = utility:Combine(section.instances, {colorpicker_title, colorpicker_color, colorpciker_inline1, colorpciker_inline2, colorpicker_outline})
                
                    return colorpicker
                end

                toggle:Set(default)

                utility:Connect(uis.InputBegan, function(input)
                    local positions = {Vector2.new(section_frame.Position.X, toggle_frame.Position.Y - 3), Vector2.new(section_frame.Position.X + section_frame.Size.X, toggle_frame.Position.Y + 10)}

                    if toggle.keybind.name ~= nil or toggle.colorpicker.name ~= nil then
                        positions = {Vector2.new(section_frame.Position.X, toggle_frame.Position.Y - 3), Vector2.new(section_frame.Position.X + section_frame.Size.X - 50, toggle_frame.Position.Y + 10)}
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverPosition(positions) and not window:MouseOverContent() and not window.fading and tab.open then
                        toggle:Set(not toggle.state)
                    end
                end)

                section.offset = section.offset + 17

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 19

                section:Update()

                library.pointers[pointer] = toggle

                section.instances = utility:Combine(section.instances, {toggle_frame, toggle_inline, toggle_outline, toggle_gradient, toggle_title})
            
                return toggle
            end

            function section:Button(args)
                args = args or {}

                local name = args.name or args.Name or "button"
                local callback = args.callback or args.Callback or function() end

                local button = {name = name, pressed = false}

                local button_frame = utility:Draw("Square", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(50, 50, 50),
                    Size = Vector2.new(210, 18),
                    Parent = section_frame
                })

                local button_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = button_frame.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = button_frame
                })

                local button_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                    Color = Color3.fromRGB(30, 30, 30),
                    Size = button_frame.Size + Vector2.new(4, 4),
                    Filled = false,
                    Parent = button_frame
                })

                local button_gradient = utility:Draw("Image", Vector2.new(), {
                    Size = button_frame.Size,
                    Transparency = 0.8,
                    Parent = button_frame
                })

                local button_title = utility:Draw("Text", Vector2.new(105, 1), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Center = true,
                    Parent = button_frame
                })

                utility:Image(button_gradient, "https://i.imgur.com/5hmlrjX.png")

                utility:Connect(uis.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverPosition({Vector2.new(section_frame.Position.X, button_frame.Position.Y - 2), Vector2.new(section_frame.Position.X + section_frame.Size.X, button_frame.Position.Y + 20)}) and not window:MouseOverContent() and not window.fading and tab.open then
                        button.pressed = true
                        button_frame.Color = Color3.fromRGB(40, 40, 40)
                        callback()
                    end
                end)

                utility:Connect(uis.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and button.pressed then
                        button.pressed = false
                        button_frame.Color = Color3.fromRGB(50, 50, 50)
                    end
                end)

                section.offset = section.offset + 23

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 25

                section:Update()

                section.instances = utility:Combine(section.instances, {button_frame, button_inline, button_outline, button_gradient, button_title})
            end

            function section:SubButtons(args)
                args = args or {}
                local buttons_table = args.buttons or args.Buttons or {{"button 1", function() end}, {"button 2", function() end}}

                local buttons = {{}, {}}

                for i = 1, 2 do
                    local button_frame = utility:Draw("Square", Vector2.new(8 + (110 * (i-1)), 25 + section.offset), {
                        Color = Color3.fromRGB(50, 50, 50),
                        Size = Vector2.new(100, 18),
                        Parent = section_frame
                    })
    
                    local button_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                        Color = Color3.fromRGB(0, 0, 0),
                        Size = button_frame.Size + Vector2.new(2, 2),
                        Filled = false,
                        Parent = button_frame
                    })
    
                    local button_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                        Color = Color3.fromRGB(30, 30, 30),
                        Size = button_frame.Size + Vector2.new(4, 4),
                        Filled = false,
                        Parent = button_frame
                    })
    
                    local button_gradient = utility:Draw("Image", Vector2.new(), {
                        Size = button_frame.Size,
                        Transparency = 0.8,
                        Parent = button_frame
                    })
    
                    local button_title = utility:Draw("Text", Vector2.new(50, 1), {
                        Color = Color3.fromRGB(255, 255, 255),
                        Outline = true,
                        Size = 13,
                        Font = 2,
                        Text = buttons_table[i][1],
                        Center = true,
                        Parent = button_frame
                    })

                    utility:Image(button_gradient, "https://i.imgur.com/5hmlrjX.png")

                    buttons[i] = {button_frame, button_inline, button_outline, button_gradient, button_title}

                    section.instances = utility:Combine(section.instances, buttons[i])
                end

                utility:Connect(uis.InputBegan, function(input)
                    for i = 1, 2 do
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverDrawing(buttons[i][1]) and not window:MouseOverContent() and not window.fading and tab.open then
                            buttons[i][1].Color = Color3.fromRGB(30, 30, 30)
                            buttons_table[i][2]()
                        end
                    end
                end)

                utility:Connect(uis.InputEnded, function(input)
                    for i = 1, 2 do
                        buttons[i][1].Color = Color3.fromRGB(50, 50, 50)
                    end
                end)

                section.offset = section.offset + 23

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 25

                section:Update()
            end

            function section:Slider(args)
                args = args or {}

                local name = args.name or args.Name or "slider"
                local min = args.minimum or args.Minimum or args.min or args.Min or -25
                local max = args.maximum or args.Maximum or args.max or args.Max or 25
                local default = args.default or args.Default or args.def or args.Def or min
                local decimals = 1 / (args.decimals or args.Decimals or 1)
                local ending = args.ending or args.Ending or args.suffix or args.Suffix or args.suf or args.Suf or ""
                local callback = args.callback or args.Callback or function() end
                local flag = args.flag or args.Flag or ""
                local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. name

                local slider = {name = name, value = def, sliding = false}

                local slider_title = utility:Draw("Text", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Parent = section_frame
                })

                local slider_frame = utility:Draw("Square", Vector2.new(0, 16), {
                    Color = Color3.fromRGB(50, 50, 50),
                    Size = Vector2.new(210, 10),
                    Parent = slider_title
                })

                local slider_bar = utility:Draw("Square", Vector2.new(), {
                    Color = accent1,
                    Size = Vector2.new(0, slider_frame.Size.Y),
                    Parent = slider_frame
                })

                table.insert(library.accents, slider_bar)

                local slider_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = slider_frame.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = slider_frame
                })

                local slider_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                    Color = Color3.fromRGB(30, 30, 30),
                    Size = slider_frame.Size + Vector2.new(4, 4),
                    Filled = false,
                    Parent = slider_frame
                })

                local slider_gradient = utility:Draw("Image", Vector2.new(), {
                    Size = slider_frame.Size,
                    Transparency = 0.8,
                    Parent = slider_frame
                })

                local slider_value = utility:Draw("Text", Vector2.new(slider_frame.Size.X / 2, -2), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = tostring(default) .. ending,
                    Center = true,
                    Parent = slider_frame
                })

                utility:Image(slider_gradient, "https://i.imgur.com/5hmlrjX.png")

                function slider:Set(value)
                    slider.value = math.clamp(math.round(value * decimals) / decimals, min, max)
                    local percent = 1 - ((max - slider.value) / (max - min))
                    slider_value.Text = tostring(value) .. ending
                    slider_bar.Size = Vector2.new(percent * slider_frame.Size.X, slider_frame.Size.Y)

                    if flag ~= "" then
                        library.flags[flag] = slider.value
                    end

                    callback(slider.value)
                end

                function slider:Get()
                    return slider.value
                end
                
                slider:Set(default)

                utility:Connect(uis.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverPosition({Vector2.new(section_frame.Position.X, slider_title.Position.Y), Vector2.new(section_frame.Position.X + section_frame.Size.X, slider_title.Position.Y + 18 + slider_frame.Size.Y)}) and not window:MouseOverContent() and not window.fading and tab.open then
                        slider.holding = true
                        local percent = math.clamp(uis:GetMouseLocation().X - slider_bar.Position.X, 0, slider_frame.Size.X) / slider_frame.Size.X
                        local value = math.floor((min + (max - min) * percent) * decimals) / decimals
                        value = math.clamp(value, min, max)
                        slider:Set(value)
                    end
                end)

                utility:Connect(uis.InputChanged, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and slider.holding then
                        local percent = math.clamp(uis:GetMouseLocation().X - slider_bar.Position.X, 0, slider_frame.Size.X) / slider_frame.Size.X
                        local value = math.floor((min + (max - min) * percent) * decimals) / decimals
                        value = math.clamp(value, min, max)
                        slider:Set(value)
                    end
                end)

                utility:Connect(uis.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and slider.holding then
                        slider.holding = false
                    end
                end)

                section.offset = section.offset + 32

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 34

                section:Update()

                library.pointers[pointer] = slider

                section.instances = utility:Combine(section.instances, {slider_frame, slider_bar, slider_inline, slider_outline, slider_gradient, slider_title, slider_value})
                
                return slider
            end

            function section:Dropdown(args)
                args = args or {}

                local name = args.name or args.Name or "dropdown"
                local options = args.options or args.Options or {"1", "2"}
                local multi = args.multi or args.Multi or false
                local default = args.default or args.Default or args.def or args.Def or (multi == false and options[1] or multi == true and {options[1]}) 
                local flag = args.flag or args.Flag or ""
                local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. name
                local callback = args.callback or args.Callback or function() end

                local dropdown = {name = name, options = options, value = default, multi = multi, open = false, search = "", content = {}}

                if flag ~= "" then
                    library.flags[flag] = dropdown.value
                end

                function dropdown:ReadValue(val)
                    if not multi then
                        if utility:GetTextSize(dropdown.value, 2, 13).X >= 196 then
                            return "..."
                        else
                            return dropdown.value
                        end
                    else
                        local str = ""
                        for i, v in pairs(dropdown.value) do
                            if i < #dropdown.value then
                                str = str .. tostring(v) .. ", "
                            else
                                str = str .. tostring(v)
                            end
                        end
                        if utility:GetTextSize(str, 2, 13).X >= 196 then
                            return "..."
                        else
                            return str
                        end
                    end
                end

                local dropdown_title = utility:Draw("Text", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Parent = section_frame
                })

                local dropdown_frame = utility:Draw("Square", Vector2.new(0, 16), {
                    Color = Color3.fromRGB(50, 50, 50),
                    Size = Vector2.new(210, 18),
                    Parent = dropdown_title
                })

                local dropdown_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = dropdown_frame.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = dropdown_frame
                })

                local dropdown_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                    Color = Color3.fromRGB(30, 30, 30),
                    Size = dropdown_frame.Size + Vector2.new(4, 4),
                    Filled = false,
                    Parent = dropdown_frame
                })

                local dropdown_gradient = utility:Draw("Image", Vector2.new(), {
                    Size = dropdown_frame.Size,
                    Transparency = 0.8,
                    Parent = dropdown_frame
                })

                local dropdown_value = utility:Draw("Text", Vector2.new(5, 1), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = dropdown:ReadValue(),
                    Parent = dropdown_frame
                })

                local dropdown_indicator = utility:Draw("Text", Vector2.new(dropdown_frame.Size.X - 12, 1), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = "+",
                    Parent = dropdown_frame
                })

                utility:Image(dropdown_gradient, "https://i.imgur.com/5hmlrjX.png")

                function dropdown:Update()
                    if #dropdown.content > 0 then
                        for i, v in pairs({select(4, unpack(dropdown.content))}) do
                            v.Color = (multi == false and v.Text == dropdown.value and accent1 or multi == true and table.find(dropdown.value, v.Text) and accent1 or Color3.fromRGB(255, 255, 255))
                        end
                    end
                end

                function dropdown:Set(value)
                    dropdown.value = table.find(dropdown.options, value) and value or options[1]
                    dropdown_value.Text = dropdown:ReadValue()
                    dropdown:Update()

                    if flag ~= "" then
                        library.flags[flag] = dropdown.value
                    end

                    callback(dropdown.value)
                end

                function dropdown:Get()
                    return dropdown.value
                end

                function dropdown:Refresh(options)
                    if #dropdown.content > 0 then
                        window:CloseContent()
                    end

                    dropdown.options = options
                    dropdown:Set(multi == false and dropdown.options[1] or multi == true and {dropdown.options[1]})
                end

                utility:Connect(uis.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and not window:MouseOverContent() and not window.fading and tab.open then
                        if #dropdown.content == 0 and utility:MouseOverPosition({Vector2.new(section_frame.Position.X, dropdown_title.Position.Y), Vector2.new(section_frame.Position.X + section_frame.Size.X, dropdown_title.Position.Y + 20 + dropdown_frame.Size.Y)}) then
                            window:CloseContent()

                            dropdown.search = ""

                            local list_frame = utility:Draw("Square", Vector2.new(1, 20), {
                                Color = Color3.fromRGB(45, 45, 45),
                                Size = Vector2.new(dropdown_frame.Size.X - 2, #dropdown.options * 15),
                                Parent = dropdown_frame
                            })
    
                            local list_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = list_frame.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = list_frame
                            })
            
                            local list_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = list_frame.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = list_frame
                            })
    
                            dropdown.content = {list_frame, list_inline, list_outline}
    
                            for i, v in pairs(dropdown.options) do
                                local text = utility:Draw("Text", Vector2.new(4, 15 * (i - 1)), {
                                    Color = (multi == false and v == dropdown.value and accent1 or multi == true and table.find(dropdown.value, v) and accent1 or Color3.fromRGB(255, 255, 255)),
                                    Outline = true,
                                    Size = 13,
                                    Font = 2,
                                    Text = tostring(v),
                                    Parent = list_frame
                                })
    
                                table.insert(dropdown.content, text)
                            end

                            window.content.dropdown = dropdown.content

                            dropdown_indicator.Text = "-"
                        elseif #dropdown.content > 0 then
                            window:CloseContent()
                            dropdown.content = {}

                            dropdown_indicator.Text = "+"
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and #dropdown.content > 0 and not window.fading and tab.open then
                        for i = 1, #dropdown.options do
                            if utility:MouseOverPosition({Vector2.new(dropdown.content[1].Position.X, dropdown.content[3 + i].Position.Y), Vector2.new(dropdown.content[1].Position.X + dropdown.content[1].Size.X, dropdown.content[3 + i].Position.Y + 15)}) then
                                if not dropdown.multi then
                                    dropdown:Set(dropdown.options[i])
                                else
                                    if table.find(dropdown.value, dropdown.options[i]) then
                                        dropdown:Set(utility:RemoveItem(dropdown.value, dropdown.options[i]))
                                    else
                                        table.insert(dropdown.value, dropdown.options[i])
                                        dropdown:Set(dropdown.value)
                                    end
                                end
                            end
                        end
                    elseif input.UserInputType == Enum.UserInputType.Keyboard and #dropdown.content > 0 and not window.fading and tab.open then
                        local key = input.KeyCode
                        if key.Name ~= "Backspace" then
                            dropdown.search = dropdown.search .. uis:GetStringForKeyCode(key):lower()
                        else
                            dropdown.search = dropdown.search:sub(1, -2)
                        end
                        if dropdown.search ~= "" then
                            for i, v in pairs({select(4, unpack(dropdown.content))}) do
                                if v.Color ~= accent1 and v.Text:lower():find(dropdown.search) then
                                    v.Color = Color3.fromRGB(255, 255, 255)
                                elseif v.Color ~= accent1 and not v.Text:lower():find(dropdown.search) then
                                    v.Color = Color3.fromRGB(155, 155, 155)
                                end
                            end
                        else
                            for i, v in pairs({select(4, unpack(dropdown.content))}) do
                                if v.Color ~= accent1 then
                                    v.Color = Color3.fromRGB(255, 255, 255)
                                end
                            end
                        end
                    end
                end)

                section.offset = section.offset + 40

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 42

                section:Update()

                library.pointers[pointer] = dropdown

                section.instances = utility:Combine(section.instances, {dropdown_frame, dropdown_inline, dropdown_outline, dropdown_gradient, dropdown_title, dropdown_value, dropdown_indicator})
            
                return dropdown
            end

            function section:Textbox(args)
                args = args or {}

                local name = args.name or args.Name or "textbox"
                local default = args.default or args.Default or args.def or args.Def or ""
                local flag = args.flag or args.Flag or ""
                local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. name
                local callback = args.callback or args.Callback or function() end

                local textbox = {name = name, typing = false, hideHolder = false, value = ""}

                local textbox_frame = utility:Draw("Square", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(50, 50, 50),
                    Size = Vector2.new(210, 18),
                    Parent = section_frame
                })

                local textbox_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = textbox_frame.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = textbox_frame
                })

                local textbox_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                    Color = Color3.fromRGB(30, 30, 30),
                    Size = textbox_frame.Size + Vector2.new(4, 4),
                    Filled = false,
                    Parent = textbox_frame
                })

                local textbox_gradient = utility:Draw("Image", Vector2.new(), {
                    Size = textbox_frame.Size,
                    Transparency = 0.8,
                    Parent = textbox_frame
                })

                local textbox_title = utility:Draw("Text", Vector2.new(4, 1), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Parent = textbox_frame
                })

                utility:Image(textbox_gradient, "https://i.imgur.com/5hmlrjX.png")

                function textbox:Set(value)
                    textbox.value = value
                    textbox_title.Text = textbox.typing == false and name or textbox.value
                    if flag ~= "" then
                        library.flags[flag] = textbox.value
                    end
                    callback(textbox.value)
                end

                function textbox:Get()
                    return textbox.value
                end

                utility:Connect(uis.InputBegan, function(input)
                    if not textbox.typing then
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and utility:MouseOverPosition({Vector2.new(section_frame.Position.X, textbox_frame.Position.Y - 2), Vector2.new(section_frame.Position.X + section_frame.Size.X, textbox_frame.Position.Y + 20)}) and not window:MouseOverContent() and not window.fading and tab.open then
                            textbox.typing = true
                            if textbox.hideHolder == false then
                                textbox.hideHolder = true
                                textbox_title.Text = textbox.value
                            end
                        end
                    else
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and not window:MouseOverContent() and not window.fading and tab.open then
                            textbox.typing = false
                            textbox.hideHolder = false
                            textbox_title.Text = name
                        elseif input.UserInputType == Enum.UserInputType.Keyboard then
                            local key = input.KeyCode
                            if key.Name ~= "Return" then
                                if key.Name ~= "Backspace" then
                                    if uis:GetStringForKeyCode(key) ~= "" then
                                        textbox.value = textbox.value .. uis:GetStringForKeyCode(key):lower()
                                        local time = 1
                                        spawn(function()
                                            task.wait(0.5)
                                            while uis:IsKeyDown(key.Name) do
                                                if not textbox.typing then break end
                                                task.wait(.2 / time)
                                                textbox.value = textbox.value .. uis:GetStringForKeyCode(key):lower()
                                                time = time + 1
                                                textbox:Set(textbox.value)
                                            end
                                        end)
                                    end
                                else
                                    textbox.value = textbox.value:sub(1, -2)
                                    local time = 1
                                    spawn(function()
                                        task.wait(0.5)
                                        while uis:IsKeyDown(key.Name) do
                                            if not textbox.typing then break end
                                            task.wait(.2 / time)
                                            textbox.value = textbox.value:sub(1, -2)
                                            time = time + 1
                                            textbox:Set(textbox.value)
                                        end
                                    end)
                                end
                            else
                                textbox.typing = false
                                textbox.hideHolder = false
                                textbox_title.Text = name
                            end
                            if textbox.hideHolder == true then
                                textbox_title.Text = textbox.value
                                textbox:Set(textbox.value)
                            end
                        end
                    end
                end)

                if flag ~= "" then
                    library.flags[flag] = ""
                end

                section.offset = section.offset + 22

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 24

                section:Update()

                section.instances = utility:Combine(section.instances, {textbox_frame, textbox_inline, textbox_outline, textbox_gradient, textbox_title})
            end

            function section:Label(args)
                args = args or {}

                local name = args.name or args.Name or args.text or args.Text or "label"
                local middle = args.mid or args.Mid or args.middle or args.Middle or false
                local callback = args.callback or args.Callback or function() end

                local label = {name = name, middle = middle}

                local label_title = utility:Draw("Text", Vector2.new(middle == false and 9 or section_frame.Size.X / 2, 25 + section.offset), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Center = middle,
                    Parent = section_frame
                })

                section.offset = section.offset + 15

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 17

                section:Update()

                section.instances = utility:Combine(section.instances, {label_title})
            end

            function section:Colorpicker(args)
                args = args or {}

                local name = args.name or args.Name or "colorpicker"
                local default = args.default or args.Default or args.def or args.Def or Color3.fromRGB(255, 0, 0)
                local flag = args.flag or args.Flag or ""
                local pointer = args.pointer or args.Pointer or tab.name .. "_" .. section.name .. "_" .. name
                local callback = args.callback or args.Callback or function() end

                local colorpicker = {name = name, value = {default:ToHSV()}, tempvalue = {}, brightness = {100, 0}, holding = {hue = false, brightness = false, color = false}, content = {}}

                if flag ~= "" then
                    library.flags[flag] = default
                end

                local colorpicker_title = utility:Draw("Text", Vector2.new(8, 25 + section.offset), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = name,
                    Parent = section_frame
                })

                local colorpicker_color = utility:Draw("Square", Vector2.new(section_frame.Size.X - 45, 2), {
                    Color = default,
                    Size = Vector2.new(24, 10),
                    Parent = colorpicker_title
                })

                local colorpciker_inline1 = utility:Draw("Square", Vector2.new(), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = colorpicker_color.Size,
                    Transparency = 0.3,
                    Filled = false,
                    Parent = colorpicker_color
                })

                local colorpciker_inline2 = utility:Draw("Square", Vector2.new(1, 1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = colorpicker_color.Size - Vector2.new(2, 2),
                    Transparency = 0.3,
                    Filled = false,
                    Parent = colorpicker_color
                })

                local colorpicker_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                    Color = Color3.fromRGB(0, 0, 0),
                    Size = colorpicker_color.Size + Vector2.new(2, 2),
                    Filled = false,
                    Parent = colorpicker_color
                })

                function colorpicker:Set(value)
                    if typeof(value) == "Color3" then
                        value = {value:ToHSV()}
                    end

                    colorpicker.value = value
                    colorpicker_color.Color = Color3.fromHSV(unpack(colorpicker.value))

                    if flag ~= "" then
                        library.flags[flag] = Color3.fromHSV(unpack(colorpicker.value))
                    end

                    callback(Color3.fromHSV(unpack(colorpicker.value)))
                end

                function colorpicker:Get()
                    return Color3.fromHSV(unpack(colorpicker.value))
                end

                utility:Connect(uis.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if #colorpicker.content == 0 and utility:MouseOverPosition({Vector2.new(section_frame.Position.X, colorpicker_title.Position.Y - 3), Vector2.new(section_frame.Position.X + section_frame.Size.X, colorpicker_title.Position.Y + 10)}) and not window:MouseOverContent() and not window.fading and tab.open then
                            colorpicker.tempvalue = colorpicker.value
                            colorpicker.brightness[2] = 0
                            
                            local colorpicker_open_frame = utility:Draw("Square", Vector2.new(12, 5), {
                                Color = Color3.fromRGB(35, 35, 35),
                                Size = Vector2.new(276, 207),
                                Parent = colorpicker_color
                            })

                            local colorpicker_open_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(20, 20, 20),
                                Size = colorpicker_open_frame.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_frame.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_accent1 = utility:Draw("Square", Vector2.new(0, 1), {
                                Color = accent1,
                                Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                Parent = colorpicker_open_frame
                            })

                            table.insert(library.accents, colorpicker_open_accent1)
                        
                            local colorpicker_open_accent2 = utility:Draw("Square", Vector2.new(0, 2), {
                                Color = accent2,
                                Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                Parent = colorpicker_open_frame
                            })

                            table.insert(library.accents, colorpicker_open_accent2)
                        
                            local colorpicker_open_inline2 = utility:Draw("Square", Vector2.new(0, 3), {
                                Color = Color3.fromRGB(20, 20, 20),
                                Size = Vector2.new(colorpicker_open_frame.Size.X, 1),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_title = utility:Draw("Text", Vector2.new(5, 6), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Outline = true,
                                Size = 13,
                                Font = 2,
                                Text = colorpicker.name,
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_apply = utility:Draw("Text", Vector2.new(232, 187), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Outline = true,
                                Size = 13,
                                Font = 2,
                                Text = "[ Apply ]",
                                Center = true,
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_color = utility:Draw("Square", Vector2.new(10, 23), {
                                Color = Color3.fromHSV(colorpicker.value[1], 1, 1),
                                Size = Vector2.new(156, 156),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_color_image = utility:Draw("Image", Vector2.new(), {
                                Size = colorpicker_open_color.Size,
                                Parent = colorpicker_open_color
                            })

                            local colorpicker_open_color_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_color.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_color
                            })

                            local colorpicker_open_color_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = colorpicker_open_color.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_color
                            })

                            local colorpicker_open_brightness_image = utility:Draw("Image", Vector2.new(10, 189), {
                                Size = Vector2.new(156, 10),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_brightness_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_brightness_image.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_brightness_image
                            })

                            local colorpicker_open_brightness_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = colorpicker_open_brightness_image.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_brightness_image
                            })

                            local colorpicker_open_hue_image = utility:Draw("Image", Vector2.new(176, 23), {
                                Size = Vector2.new(10, 156),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_hue_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_hue_image.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_hue_image
                            })

                            local colorpicker_open_hue_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = colorpicker_open_hue_image.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_hue_image
                            })

                            local colorpicker_open_newcolor_title = utility:Draw("Text", Vector2.new(196, 23), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Outline = true,
                                Size = 13,
                                Font = 2,
                                Text = "New color",
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_newcolor_image = utility:Draw("Image", Vector2.new(197, 37), {
                                Size = Vector2.new(71, 36),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_newcolor_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_newcolor_image.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_newcolor_image
                            })

                            local colorpicker_open_newcolor_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = colorpicker_open_newcolor_image.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_newcolor_image
                            })

                            local colorpicker_open_newcolor = utility:Draw("Square", Vector2.new(2, 2), {
                                Color = Color3.fromHSV(unpack(colorpicker.value)),
                                Size = colorpicker_open_newcolor_image.Size - Vector2.new(4, 4),
                                Transparency = 0.4,
                                Parent = colorpicker_open_newcolor_image
                            })

                            local colorpicker_open_oldcolor_title = utility:Draw("Text", Vector2.new(196, 76), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Outline = true,
                                Size = 13,
                                Font = 2,
                                Text = "Old color",
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_oldcolor_image = utility:Draw("Image", Vector2.new(197, 91), {
                                Size = Vector2.new(71, 36),
                                Parent = colorpicker_open_frame
                            })

                            local colorpicker_open_oldcolor_inline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_oldcolor_image.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_oldcolor_image
                            })

                            local colorpicker_open_oldcolor_outline = utility:Draw("Square", Vector2.new(-2, -2), {
                                Color = Color3.fromRGB(30, 30, 30),
                                Size = colorpicker_open_oldcolor_image.Size + Vector2.new(4, 4),
                                Filled = false,
                                Parent = colorpicker_open_oldcolor_image
                            })

                            local colorpicker_open_oldcolor = utility:Draw("Square", Vector2.new(2, 2), {
                                Color = Color3.fromHSV(unpack(colorpicker.value)),
                                Size = colorpicker_open_oldcolor_image.Size - Vector2.new(4, 4),
                                Transparency = 0.4,
                                Parent = colorpicker_open_oldcolor_image
                            })

                            local colorpicker_open_color_holder = utility:Draw("Square", Vector2.new(colorpicker_open_color_image.Size.X - 5, 0), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Size = Vector2.new(5, 5),
                                Filled = false,
                                Parent = colorpicker_open_color_image
                            })

                            local colorpicker_open_color_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_color_holder.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_color_holder
                            })

                            local colorpicker_open_hue_holder = utility:Draw("Square", Vector2.new(-1, 0), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Size = Vector2.new(12, 3),
                                Filled = false,
                                Parent = colorpicker_open_hue_image
                            })

                            colorpicker_open_hue_holder.Position = Vector2.new(colorpicker_open_hue_image.Position.X-1, colorpicker_open_hue_image.Position.Y + colorpicker.tempvalue[1] * colorpicker_open_hue_image.Size.Y)

                            local colorpicker_open_hue_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_hue_holder.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_hue_holder
                            })

                            local colorpicker_open_brightness_holder = utility:Draw("Square", Vector2.new(colorpicker_open_brightness_image.Size.X, -1), {
                                Color = Color3.fromRGB(255, 255, 255),
                                Size = Vector2.new(3, 12),
                                Filled = false,
                                Parent = colorpicker_open_brightness_image
                            })

                            colorpicker_open_brightness_holder.Position = Vector2.new(colorpicker_open_brightness_image.Position.X + colorpicker_open_brightness_image.Size.X * (colorpicker.brightness[1] / 100), colorpicker_open_brightness_image.Position.Y-1)

                            local colorpicker_open_brightness_holder_outline = utility:Draw("Square", Vector2.new(-1, -1), {
                                Color = Color3.fromRGB(0, 0, 0),
                                Size = colorpicker_open_brightness_holder.Size + Vector2.new(2, 2),
                                Filled = false,
                                Parent = colorpicker_open_brightness_holder
                            })

                            utility:Image(colorpicker_open_color_image, "https://i.imgur.com/wpDRqVH.png")
                            utility:Image(colorpicker_open_brightness_image, "https://tr.rbxcdn.com/cf80cdea88fd9bbdb4037ab352260726/420/420/Image/Png")
                            utility:Image(colorpicker_open_hue_image, "https://i.imgur.com/iEOsHFv.png")
                            utility:Image(colorpicker_open_newcolor_image, "https://images-ext-1.discordapp.net/external/Nc7u8ZAc9yYabSDkX2zn48MdXjh0BL3KswXDknMm97w/https/media.discordapp.net/attachments/942749250897477662/980791504954093588/unknown.png")
                            utility:Image(colorpicker_open_oldcolor_image, "https://images-ext-1.discordapp.net/external/Nc7u8ZAc9yYabSDkX2zn48MdXjh0BL3KswXDknMm97w/https/media.discordapp.net/attachments/942749250897477662/980791504954093588/unknown.png")

                            colorpicker.content = {colorpicker_open_frame, colorpicker_open_inline, colorpicker_open_outline, colorpicker_open_accent1, colorpicker_open_accent2, colorpicker_open_inline2, colorpicker_open_title, colorpicker_open_apply,
                            colorpicker_open_color, colorpicker_open_color_image, colorpicker_open_color_inline, colorpicker_open_color_outline, colorpicker_open_brightness_image, colorpicker_open_brightness_inline, colorpicker_open_brightness_outline,
                            colorpicker_open_hue_image, colorpicker_open_hue_inline, colorpicker_open_hue_outline, colorpicker_open_newcolor_title, colorpicker_open_newcolor_image, colorpicker_open_newcolor_inline, colorpicker_open_newcolor_outline,
                            colorpicker_open_newcolor, colorpicker_open_oldcolor_title, colorpicker_open_oldcolor_image, colorpicker_open_oldcolor_inline, colorpicker_open_oldcolor_outline, colorpicker_open_oldcolor, colorpicker_open_hue_holder_outline,
                            colorpicker_open_brightness_holder_outline, colorpicker_open_color_holder_outline, colorpicker_open_color_holder, colorpicker_open_hue_holder, colorpicker_open_brightness_holder}

                            window.content.colorpicker = colorpicker.content

                        elseif #colorpicker.content > 0 and not window:MouseOverContent() and not window.fading and tab.open then
                            window:CloseContent()
                            colorpicker.content = {}
                            for i, v in pairs(colorpicker.holding) do
                                colorpicker.holding[i] = false
                            end
                        elseif #colorpicker.content > 0 and window:MouseOverContent() and not window.fadign and tab.open then
                            if utility:MouseOverDrawing(colorpicker.content[10]) then
                                local colorx = math.clamp(uis:GetMouseLocation().X - colorpicker.content[10].Position.X, 0, colorpicker.content[10].Position.X) /colorpicker.content[10].Size.X
								local colory = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y
								local s = colorx
								local v = (colorpicker.brightness[1] / 100) - colory

                                colorpicker.brightness[2] = colory

                                colorpicker.tempvalue = {colorpicker.tempvalue[1], s, v}

                                local minPos = Vector2.new(colorpicker.content[10].Position.X, colorpicker.content[10].Position.Y)
                                local maxPos = Vector2.new(colorpicker.content[10].Position.X + colorpicker.content[10].Size.X - 5, colorpicker.content[10].Position.Y + colorpicker.content[10].Size.Y - 5)
                                local holderPos = uis:GetMouseLocation()
                                if holderPos.X > maxPos.X then
                                    holderPos = Vector2.new(maxPos.X, holderPos.Y)
                                end 
                                if holderPos.Y > maxPos.Y then
                                    holderPos = Vector2.new(holderPos.X, maxPos.Y)
                                end
                                if holderPos.X < minPos.X then
                                    holderPos = Vector2.new(minPos.X, holderPos.Y)
                                end 
                                if holderPos.Y < minPos.Y then
                                    holderPos = Vector2.new(holderPos.X, minPos.Y)
                                end
                                colorpicker.content[32].Position = holderPos

                                colorpicker.holding.color = true
                            elseif utility:MouseOverDrawing(colorpicker.content[16]) then
                                local hue = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[16].Position.Y, 0, colorpicker.content[16].Size.Y) / colorpicker.content[16].Size.Y

                                colorpicker.tempvalue = {hue, colorpicker.tempvalue[2], colorpicker.tempvalue[3]}

                                colorpicker.content[33].Position = Vector2.new(colorpicker.content[16].Position.X-1, colorpicker.content[16].Position.Y + colorpicker.tempvalue[1] * colorpicker.content[16].Size.Y)

                                colorpicker.content[9].Color = Color3.fromHSV(colorpicker.tempvalue[1], 1, 1)

                                colorpicker.holding.hue = true
                            elseif utility:MouseOverDrawing(colorpicker.content[13]) then
                                local percent = math.clamp(uis:GetMouseLocation().X - colorpicker.content[13].Position.X, 0, colorpicker.content[13].Size.X) / colorpicker.content[13].Size.X

                                colorpicker.brightness[1] = 100 * percent

                                colorpicker.tempvalue[3] = (colorpicker.brightness[1] / 100) - colorpicker.brightness[2]

                                colorpicker.content[34].Position = Vector2.new(colorpicker.content[13].Position.X + colorpicker.content[13].Size.X * (colorpicker.brightness[1] / 100), colorpicker.content[13].Position.Y-1)

                                colorpicker.holding.brightness = true
                            elseif utility:MouseOverPosition({colorpicker.content[8].Position - Vector2.new(colorpicker.content[8].TextBounds.X / 2, 0), colorpicker.content[8].Position + Vector2.new(colorpicker.content[8].TextBounds.X / 2, 13)}) then
                                colorpicker:Set(colorpicker.tempvalue)
                                colorpicker.tempvalue = colorpicker.value
                                colorpicker.content[28].Color = Color3.fromHSV(unpack(colorpicker.value))
                            end
                            colorpicker.content[23].Color = Color3.fromHSV(unpack(colorpicker.tempvalue))
                        end
                    end
                end)

                utility:Connect(uis.InputChanged, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and #colorpicker.content > 0 then
                        if colorpicker.holding.color then
                            local colorx = math.clamp(uis:GetMouseLocation().X - colorpicker.content[10].Position.X, 0, colorpicker.content[10].Position.X) /colorpicker.content[10].Size.X
							local colory = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y
							local s = colorx
							local v = (colorpicker.brightness[1] / 100) - colory

                            colorpicker.brightness[2] = colory

                            colorpicker.tempvalue = {colorpicker.tempvalue[1], s, v}

                            local minPos = Vector2.new(colorpicker.content[10].Position.X, colorpicker.content[10].Position.Y)
                            local maxPos = Vector2.new(colorpicker.content[10].Position.X + colorpicker.content[10].Size.X - 5, colorpicker.content[10].Position.Y + colorpicker.content[10].Size.Y - 5)
                            local holderPos = uis:GetMouseLocation()
                            if holderPos.X > maxPos.X then
                                holderPos = Vector2.new(maxPos.X, holderPos.Y)
                            end 
                            if holderPos.Y > maxPos.Y then
                                holderPos = Vector2.new(holderPos.X, maxPos.Y)
                            end
                            if holderPos.X < minPos.X then
                                holderPos = Vector2.new(minPos.X, holderPos.Y)
                            end 
                            if holderPos.Y < minPos.Y then
                                holderPos = Vector2.new(holderPos.X, minPos.Y)
                            end
                            colorpicker.content[32].Position = holderPos
                        elseif colorpicker.holding.hue then
                            local hue = math.clamp(uis:GetMouseLocation().Y - colorpicker.content[16].Position.Y, 0, colorpicker.content[16].Size.Y) / colorpicker.content[16].Size.Y

                            colorpicker.tempvalue = {hue, colorpicker.tempvalue[2], colorpicker.tempvalue[3]}

                            colorpicker.content[33].Position = Vector2.new(colorpicker.content[16].Position.X-1, colorpicker.content[16].Position.Y + colorpicker.tempvalue[1] * colorpicker.content[16].Size.Y)

                            colorpicker.content[9].Color = Color3.fromHSV(colorpicker.tempvalue[1], 1, 1)
                        elseif colorpicker.holding.brightness then
                            local percent = math.clamp(uis:GetMouseLocation().X - colorpicker.content[13].Position.X, 0, colorpicker.content[13].Size.X) / colorpicker.content[13].Size.X
                                
                            local colory = math.clamp(colorpicker.content[31].Position.Y - colorpicker.content[10].Position.Y, 0, colorpicker.content[10].Position.Y) / colorpicker.content[10].Size.Y

                            colorpicker.brightness[1] = 100 * percent

                            colorpicker.tempvalue[3] = (colorpicker.brightness[1] / 100) - colorpicker.brightness[2]

                            colorpicker.content[34].Position = Vector2.new(colorpicker.content[13].Position.X + colorpicker.content[13].Size.X * (colorpicker.brightness[1] / 100), colorpicker.content[13].Position.Y-1)
                        end
                        colorpicker.content[23].Color = Color3.fromHSV(unpack(colorpicker.tempvalue))
                    end
                end)

                utility:Connect(uis.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and #colorpicker.content > 0 then
                        for i, v in pairs(colorpicker.holding) do
                            colorpicker.holding[i] = false
                        end
                    end
                end)

                section.offset = section.offset + 17

                tab.sectionOffsets[side] = tab.sectionOffsets[side] + 19

                section:Update()

                library.pointers[pointer] = colorpicker

                section.instances = utility:Combine(section.instances, {colorpicker_title, colorpicker_color, colorpciker_inline1, colorpciker_inline2, colorpicker_outline})
            
                return colorpicker
            end

            return section
        end

        function tab:Update()
            function getUnderIndex(i, side)
                local count = 0
                for i2, v in pairs(tab.sections) do
                    if i2 < i and v.side == side then
                        count = count + v.instances[1].Size.Y + 9
                    end
                end
                return count
            end

            for i, v in pairs(tab.sections) do
                v.instances[1].SetOffset(Vector2.new(v.side == "left" and 9 or v.side == "right" and 245, 9 + getUnderIndex(i, v.side)))
            end
        end

        return tab
    end

    function window:Watermark()
        local watermark = {
            name = "beanbot",
            version = "dev",
            instances = {},
            values = {}
        }

        local watermark_frame = utility:Draw("Square", Vector2.new(), {
            Color = Color3.fromRGB(50, 50, 50),
            Size = Vector2.new(223, 20),
            Position = Vector2.new(60, 10)
        }, true)

        local watermark_inline = utility:Draw("Square", Vector2.new(-1, -1), {
            Color = Color3.fromRGB(20, 20, 20),
            Size = watermark_frame.Size + Vector2.new(2, 2),
            Filled = false,
            Parent = watermark_frame
        }, true)

        local watermark_outline = utility:Draw("Square", Vector2.new(-2, -2), {
            Color = Color3.fromRGB(0, 0, 0),
            Size = watermark_frame.Size + Vector2.new(4, 4),
            Filled = false,
            Parent = watermark_frame
        }, true)

        local watermark_accent1 = utility:Draw("Square", Vector2.new(), {
            Color = accent1,
            Size = Vector2.new(watermark_frame.Size.X, 1),
            Parent = watermark_frame
        }, true)

        table.insert(library.accents, watermark_accent1)

        local watermark_accent2 = utility:Draw("Square", Vector2.new(0, 1), {
            Color = accent2,
            Size = Vector2.new(watermark_frame.Size.X, 1),
            Parent = watermark_frame
        }, true)

        table.insert(library.accents, watermark_accent2)

        local watermark_inline2 = utility:Draw("Square", Vector2.new(0, 2), {
            Color = Color3.fromRGB(20, 20, 20),
            Size = Vector2.new(watermark_frame.Size.X, 1),
            Parent = watermark_frame
        }, true)

        local watermark_gradient = utility:Draw("Image", Vector2.new(0, 3), {
            Size = watermark_frame.Size - Vector2.new(0, 3),
            Transparency = 0.65,
            Parent = watermark_frame
        }, true)

        local watermark_icon = utility:Draw("Image", Vector2.new(4, 2), {
            Size = Vector2.new(18, 18),
            Parent = watermark_frame
        }, true)

        local watermark_title = utility:Draw("Text", Vector2.new(28, 4), {
            Color = Color3.fromRGB(255, 255, 255),
            Outline = true,
            Size = 13,
            Font = 2,
            Text = watermark.name .. " | 0 fps | 0ms",
            Parent = watermark_frame
        }, true)

        utility:Image(watermark_gradient, "https://i.imgur.com/5hmlrjX.png")
        utility:Image(watermark_icon, "https://tr.rbxcdn.com/74ac16e97027fc4dd6cec71eb2932dba/420/420/Image/Png")

        function watermark:Property(i, v)
            if i == "Visible" then
                for i2, v2 in pairs(watermark.instances) do
                    v2.Visible = v
                end
            elseif i == "Icon" then
                utility:Image(watermark_icon, v)
            elseif i == "Name" then
                watermark.name = v
            end
        end

        utility:Connect(rs.RenderStepped, function(delta)
            watermark.values[1] = math.floor(1 / delta)
            watermark.values[2] = math.floor(game.Stats.PerformanceStats.Ping:GetValue())
        end)

        spawn(function()
            while task.wait(0.1) do
                if rawget(watermark_title, "__OBJECT_EXIST") then
                    watermark_title.Text = watermark.name .. " | " .. watermark.version .. " | " .. tostring(watermark.values[1]) .. " fps | " .. tostring(watermark.values[2]) .. "ms"
                    watermark_frame.Size = Vector2.new(32 + watermark_title.TextBounds.X, 20)
                    watermark_inline.Size = watermark_frame.Size + Vector2.new(2, 2)
                    watermark_outline.Size = watermark_frame.Size + Vector2.new(4, 4)
                    watermark_gradient.Size = watermark_frame.Size
                    watermark_accent1.Size = Vector2.new(watermark_frame.Size.X, 1)
                    watermark_accent2.Size = Vector2.new(watermark_frame.Size.X, 1)
                    watermark_inline2.Size = Vector2.new(watermark_frame.Size.X, 1)
                else
                    break
                end
            end
        end)

        watermark.instances = {watermark_frame, watermark_inline, watermark_outline, watermark_accent1, watermark_accent2, watermark_inline2, watermark_gradient, watermark_icon, watermark_title}

        watermark:Property("Visible", false)

        window.watermark = watermark
    end

    function window:Keybinds()
        local keybinds = {instances = {}, keybinds = {}}

        local keybinds_frame = utility:Draw("Square", Vector2.new(), {
            Color = Color3.fromRGB(50, 50, 50),
            Size = Vector2.new(62, 18),
            Position = Vector2.new(10, math.floor(utility:ScreenSize().Y / 2))
        }, true)

        local keybinds_inline = utility:Draw("Square", Vector2.new(-1, -1), {
            Color = Color3.fromRGB(20, 20, 20),
            Size = keybinds_frame.Size + Vector2.new(2, 2),
            Filled = false,
            Parent = keybinds_frame
        }, true)

        local keybinds_outline = utility:Draw("Square", Vector2.new(-2, -2), {
            Color = Color3.fromRGB(0, 0, 0),
            Size = keybinds_frame.Size + Vector2.new(4, 4),
            Filled = false,
            Parent = keybinds_frame
        }, true)

        local keybinds_accent1 = utility:Draw("Square", Vector2.new(), {
            Color = accent1,
            Size = Vector2.new(keybinds_frame.Size.X, 1),
            Parent = keybinds_frame
        }, true)

        table.insert(library.accents, keybinds_accent1)

        local keybinds_accent2 = utility:Draw("Square", Vector2.new(0, 1), {
            Color = accent2,
            Size = Vector2.new(keybinds_frame.Size.X, 1),
            Parent = keybinds_frame
        }, true)

        table.insert(library.accents, keybinds_accent2)

        local keybinds_inline2 = utility:Draw("Square", Vector2.new(0, 2), {
            Color = Color3.fromRGB(20, 20, 20),
            Size = Vector2.new(keybinds_frame.Size.X, 1),
            Parent = keybinds_frame
        }, true)

        local keybinds_gradient = utility:Draw("Image", Vector2.new(0, 3), {
            Size = keybinds_frame.Size - Vector2.new(0, 3),
            Transparency = 0.8,
            Parent = keybinds_frame
        }, true)

        local keybinds_title = utility:Draw("Text", Vector2.new(2, 2), {
            Color = Color3.fromRGB(255, 255, 255),
            Outline = true,
            Size = 13,
            Font = 2,
            Text = "Keybinds",
            Parent = keybinds_frame
        }, true)

        utility:Image(keybinds_gradient, "https://i.imgur.com/5hmlrjX.png")

        function keybinds:Longest()
            if #keybinds.keybinds > 0 then
                local copy = utility:CopyTable(keybinds.keybinds)
                table.sort(copy, function(a, b)
                    return utility:GetTextSize(a, 2, 13).X > utility:GetTextSize(b, 2, 13).X
                end)
                return utility:GetTextSize(copy[1], 2, 13).X
            end
            return 0
        end

        function keybinds:Redraw()
            for _, v in pairs({select(9, unpack(keybinds.instances))}) do
                v.Remove()
            end

            keybinds.instances = {keybinds_frame, keybinds_inline, keybinds_outline, keybinds_accent1, keybinds_accent2, keybinds_inline2, keybinds_gradient, keybinds_title}

            if keybinds:Longest() + 6 > 60 then
                keybinds_frame.Size = Vector2.new(keybinds:Longest() + 6, (#keybinds.keybinds + 1) * 16 + 2)
                keybinds_inline.Size = keybinds_frame.Size + Vector2.new(2, 2)
                keybinds_outline.Size = keybinds_frame.Size + Vector2.new(4, 4)
                keybinds_accent1.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_accent2.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_inline2.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_gradient.Size = keybinds_frame.Size
            else
                keybinds_frame.Size = Vector2.new(60, (#keybinds.keybinds + 1) * 16 + 2)
                keybinds_inline.Size = keybinds_frame.Size + Vector2.new(2, 2)
                keybinds_outline.Size = keybinds_frame.Size + Vector2.new(4, 4)
                keybinds_accent1.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_accent2.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_inline2.Size = Vector2.new(keybinds_frame.Size.X, 1)
                keybinds_gradient.Size = keybinds_frame.Size
            end

            for i, v in pairs(keybinds.keybinds) do
                local keybind_title = utility:Draw("Text", Vector2.new(2, 16 * i + 2), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Outline = true,
                    Size = 13,
                    Font = 2,
                    Text = v,
                    Parent = keybinds_frame,
                    Visible = keybinds_frame.Visible
                }, true)

                table.insert(keybinds.instances, keybind_title)
            end
        end

        function keybinds:Add(name)
            if not table.find(keybinds.keybinds, name) then
                table.insert(keybinds.keybinds, name)
                keybinds:Redraw()
            end
        end

        function keybinds:Remove(name)
            if table.find(keybinds.keybinds, name) then
                table.remove(keybinds.keybinds, table.find(keybinds.keybinds, name))
                keybinds:Redraw()
            end
        end

        function keybinds:Property(i, v)
            if i == "Visible" then
                for _, v2 in pairs(keybinds.instances) do
                    v2.Visible = v
                end
            end
        end

        keybinds.instances = {keybinds_frame, keybinds_inline, keybinds_outline, keybinds_accent1, keybinds_accent2, keybinds_inline2, keybinds_gradient, keybinds_title}

        keybinds:Property("Visisble", false)

        window.keybinds = keybinds
    end

    function window:ChangeAccent(atype, color)
        for i, v in pairs(library.accents) do
            if rawget(v, "__OBJECT_EXIST") then
                if atype:lower() == "accent1" and v.Color == accent1 or atype:lower() == "accent2" and v.Color == accent2 then
                    v.Color = color
                end
            end
        end
        if atype:lower() == "accent1" then
            accent1 = color
        else
            accent2 = color
        end
    end
    
    function window:Rename(value)
        title.Text = value
    end

    function window:GetConfig()
        local config = {}
        for i, v in pairs(library.pointers) do
            config[i] = v:Get()
        end
        return game:GetService("HttpService"):JSONEncode(config)
    end

    function window:LoadConfig(config)
        for i, v in pairs(game:GetService("HttpService"):JSONDecode(config)) do
            if library.pointers[i] then
                library.pointers[i]:Set(v)
            end
        end
    end

    function window:Update()
        for i, v in pairs(window.tabs) do
            v:Update()
        end
        window:UpdateTabs()
    end

    function window:MouseOverContent()
        if window_frame.Visible then
            if window.content.dropdown then
                return utility:MouseOverDrawing(window.content.dropdown[1])
            elseif window.content.colorpicker then
                return utility:MouseOverDrawing(window.content.colorpicker[1])
            elseif window.content.keybind then
                return utility:MouseOverDrawing(window.content.keybind[1])
            end
        end 
        return not window_frame.Visible
    end

    function window:CloseContent()
        if window.content.dropdown then
            for i, v in pairs(window.content.dropdown) do
                v.Remove()
            end
            window.content.dropdown = nil
        elseif window.content.colorpicker then
            for i, v in pairs(window.content.colorpicker) do
                v.Remove()
            end
            window.content.colorpicker = nil
        elseif window.content.keybind then
            for i, v in pairs(window.content.keybind) do
                v.Remove()
            end
            window.content.keybind = nil
        end
    end

    function window:UpdateTabs()
        for _, v in pairs(window.tabs) do
            if v.open == false then
                v:Hide()
            else
                v:Show()
            end
        end
    end

    function window:SetTab(name)
        for _, v in pairs(window.tabs) do
            if v.name == name then
                v.open = true
            else
                v.open = false
            end
        end
        window:UpdateTabs()
        window:CloseContent()
    end

    function window:Load()
        getgenv().window_state = "pre"
        window:SetTab(window.tabs[1].name)
        task.wait(0.3)
        getgenv().window_state = "initializing"
        window:Watermark()
        window:Keybinds()
        library.loaded = true
        task.wait(0.3)
        getgenv().window_state = "post"
        task.wait(0.5)
        window:Toggle()
        repeat task.wait() until window.fading == false
        getgenv().window_state = "finished"
    end

    function window:Unload()
        for i, v in pairs(library.connections) do
            v:Disconnect()
        end
        for i, v in pairs(utility:Combine(library.drawings, library.hidden)) do
            v[1].Remove()
        end

        FOV:Remove()

        library.loaded = false
    end

    return window
end


local lplr = game.Players.LocalPlayer
local aimbot_target = nil
local ragebot_target = nil

local desync_stuff = {}
local icons_stuff = {["Default"] = "https://tr.rbxcdn.com/74ac16e97027fc4dd6cec71eb2932dba/420/420/Image/Png", ["Azure"] = "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Microsoft_Azure.svg/1200px-Microsoft_Azure.svg.png"}

function isAlive(player)
    local alive = false
    if player ~= nil and player.Parent == game.Players and player.Character ~= nil then
		if player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("Head") then
			alive = true
		end
    end

    return alive
end

function isTarget(plr, teammates)
	if isAlive(plr) then
		if not plr.Neutral and not lplr.Neutral then
			if teammates == false then
				return plr.Team ~= lplr.Team
			elseif teammates == true then
				return plr ~= lplr
			end
		else
			return plr ~= lplr
		end
	end
end

function getConfigs()
    local configs = {"-"}
    for i, v in pairs(listfiles("beanbot/Da Hood/configs/")) do
        if tostring(v):sub(-5, -1) == ".bean" then
            table.insert(configs, tostring(v):sub(24, -6))
        end
    end

    return configs
end

function RandomNumberRange(a)
    return math.random(-a * 100, a * 100) / 100
end

function RandomVectorRange(a, b, c)
    return Vector3.new(RandomNumberRange(a), RandomNumberRange(b), RandomNumberRange(c))
end

function GetPlayerNames()
    local names = {lplr.Name}
    for i, v in pairs(game.Players:GetPlayers()) do
        if v ~= lplr then
            table.insert(names, v.Name)
        end
    end
    return names
end

local window = library:New({name = "beanbot"})

local legit = window:Tab({name = "Legit"})
local rage = window:Tab({name = "Rage"})
local visuals = window:Tab({name = "Visuals"})
local misc = window:Tab({name = "Misc"})
local settings = window:Tab({name = "Settings"})

local legit_aimbot = legit:Section({name = "Aimbot"})
local legit_silent_aim = legit:Section({name = "Silent Aim", side = "right"})

local rage_ragebot = rage:Section({name = "Ragebot"})

local visuals_esp = visuals:Section({name = "ESP"})

local misc_desync = misc:Section({name = "Desync"})
local misc_target_strafe = misc:Section({name = "Target Strafe", side = "right"})
local misc_cframe_walk = misc:Section({name = "CFrame Walkspeed", side = "right"})

local settings_ui = settings:Section({name = "UI"})
local settings_config = settings:Section({name = "Config"})
local settings_game = settings:Section({name = "Game", side = "right"})

legit_aimbot:Toggle({name = "Enabled", flag = "aimbot_enabled"}):Keybind()
legit_aimbot:Toggle({name = "Draw FOV", flag  = "aimbot_fov", callback = function() FOV.Visible = library.flags["aimbot_fov"] end})
legit_aimbot:Toggle({name = "FOV Filled", flag = "aimbot_fov_filled", callback = function() FOV.Filled = library.flags["aimbot_fov_filled"] end})
legit_aimbot:Colorpicker({name = "FOV Color", flag = "aimbot_fov_color", callback = function() FOV.Color = library.flags["aimbot_fov_color"] end})
legit_aimbot:Slider({name = "FOV Size", min = 0, max = 500, def = 0, suf = "°", flag = "aimbot_fov_size", callback = function() FOV.Radius = library.flags["aimbot_fov_size"] end})
legit_aimbot:Slider({name = "FOV Sides", min = 0, max = 100, def = 0, suf = "°", flag = "aimbot_fov_sides", callback = function() FOV.NumSides = library.flags["aimbot_fov_sides"] end})
legit_aimbot:Slider({name = "FOV Thickness", min = 0, max = 5, def = 0, suf = "°", flag = "aimbot_fov_thickness", callback = function() FOV.Thickness = library.flags["aimbot_fov_thickness"] end})

rage_ragebot:Toggle({name = "Enabled", flag = "ragebot_enabled"}):Keybind()
rage_ragebot:Toggle({name = "Visibility check", flag = "ragebot_vis"})
rage_ragebot:Toggle({name = "Autoshoot", flag = "ragebot_autoshoot"})
rage_ragebot:Dropdown({name = "Hitbox", options = {"Head", "UpperTorso"}, flag = "ragebot_hitbox"})
rage_ragebot:Slider({name = "Prediction", min = 0.1, max = 10, def = 3, decimals = 0.1, flag = "ragebot_prediction"})

visuals_esp:Toggle({name = "Enabled", flag = "esp_enabled"}):Keybind()
visuals_esp:Toggle({name = "Teammates", flag = "esp_teammates"})
visuals_esp:Toggle({name = "Box", flag = "esp_box"}):Colorpicker({name = "Box color", flag = "esp_box_color", def = Color3.fromRGB(255, 255, 255)})
visuals_esp:Toggle({name = "Health", flag = "esp_health"}):Colorpicker({name = "Health color", flag = "esp_health_color", def = Color3.fromRGB(0, 255, 0)})
visuals_esp:Toggle({name = "Name", flag = "esp_name"}):Colorpicker({name = "Name color", flag = "esp_name_color", def = Color3.fromRGB(255, 255, 255)})
visuals_esp:Toggle({name = "Chams", flag = "esp_chams"}):Colorpicker({name = "Chams color", flag = "esp_chams_color", def = Color3.fromRGB(255, 0, 0)})
visuals_esp:Toggle({name = "Chams outline", flag = "esp_chams_outline"}):Colorpicker({name = "Chams outline color", flag = "esp_chams_outline_color", def = Color3.fromRGB(0, 0, 0)})

misc_desync:Toggle({name = "Enabled", flag = "desync_enabled"}):Keybind()
misc_desync:Toggle({name = "Fling", flag = "desync_fling"})
misc_desync:Toggle({name = "Visualize", flag = "desync_visualize"}):Colorpicker({name = "Visualizer color", callback = function(val)
    for i, v in pairs(r6_dummy:GetChildren()) do
        if v:IsA("BasePart") then
            v.Color = val
        end
    end
end})

misc_desync:Dropdown({name = "Mode", options = {"-", "Offset", "Random", "Zero", "Target strafe"}, flag = "desync_mode"})
misc_desync:Dropdown({name = "Rotation", options = {"Manual", "Random"}, flag = "desync_rotation"})

misc_desync:Label({name = "Offset mode", middle = true})

misc_desync:Slider({name = "Offset X", min = -10, max = 10, def = 0, suf = "st", flag = "desync_offset_x"})
misc_desync:Slider({name = "Offset Y", min = -10, max = 10, def = 0, suf = "st", flag = "desync_offset_y"})
misc_desync:Slider({name = "Offset Z", min = -10, max = 10, def = 0, suf = "st", flag = "desync_offset_z"})

misc_desync:Label({name = "Random mode", middle = true})

misc_desync:Slider({name = "Random X", min = 0, max = 35, def = 10, suf = "st", flag = "desync_random_x"})
misc_desync:Slider({name = "Random Y", min = 0, max = 35, def = 10, suf = "st", flag = "desync_random_y"})
misc_desync:Slider({name = "Random Z", min = 0, max = 35, def = 10, suf = "st", flag = "desync_random_z"})

misc_desync:Label({name = "Manual rotation", middle = true})

misc_desync:Slider({name = "Manual X", min = -180, max = 180, def = 0, suf = "°", flag = "desync_manual_x"})
misc_desync:Slider({name = "Manual Y", min = -180, max = 180, def = 0, suf = "°", flag = "desync_manual_y"})
misc_desync:Slider({name = "Manual Z", min = -180, max = 180, def = 0, suf = "°", flag = "desync_manual_z"})

misc_desync:Button({name = "Reset", callback = function()
    local values = {{"Misc_Desync_Offset ", 0}, {"Misc_Desync_Manual ", 0}, {"Misc_Desync_Random ", 10}}
    for _, v in pairs(values) do
        for _, v2 in pairs({"X", "Y", "Z"}) do
            library.pointers[v[1] .. v2]:Set(v[2])
        end
    end
end})

misc_target_strafe:Slider({name = "Speed", min = 1, max = 10, default = 1, decimals = 0.1, flag = "desync_targetstrafe_speed"})
misc_target_strafe:Slider({name = "Offset", min = 5, max = 20, default = 5, flag = "desync_targetstrafe_offset"})
misc_target_strafe:Dropdown({name = "Target", options = GetPlayerNames(), flag = "desync_targetstrafe_selected"})
misc_target_strafe:Button({name = "Refresh", callback = function() library.pointers["Misc_Desync_Select player"]:Refresh(GetPlayerNames()) end})

misc_cframe_walk:Toggle({name = "Enabled", flag = "cframe_walk_enabled"}):Keybind()
misc_cframe_walk:Slider({name = "Speed", min = 0, max = 10, default = 0, decimals = 0.1, flag = "cframe_walk_speed"})

settings_ui:Toggle({name = "Watermark", flag = "ui_watermark", callback = function() if library.loaded then window.watermark:Property("Visible", library.flags["ui_watermark"]) end end})
settings_ui:Toggle({name = "Keybinds", flag = "ui_keybinds", callback = function() if library.loaded then window.keybinds:Property("Visible", library.flags["ui_keybinds"]) end end})
settings_ui:Textbox({name = "Custom cheat name", flag = "ui_name", callback = function() window:Rename(library.flags["ui_name"]) if library.loaded then window.watermark:Property("Name", library.flags["ui_name"]) end end})
settings_ui:Dropdown({name = "Icon", options = {"Default", "Azure"}, flag = "ui_icon", callback = function() if library.loaded then window.watermark:Property("Icon", icons_stuff[library.flags["ui_icon"]]) end end})
settings_ui:Colorpicker({name = "Accent 1", def = Color3.fromRGB(127, 72, 163), flag = "ui_accent1", callback = function() window:ChangeAccent("accent1", library.flags["ui_accent1"]) end})
settings_ui:Colorpicker({name = "Accent 2", def = Color3.fromRGB(87, 32, 127), flag = "ui_accent2", callback = function() window:ChangeAccent("accent2", library.flags["ui_accent2"]) end})
settings_ui:Button({name = "Unload", callback = function() window:Unload() end})

settings_config:Textbox({name = "Config name", flag = "config_name"})
settings_config:Dropdown({name = "Saved configs", options = getConfigs(), flag = "config_selected"})
settings_config:SubButtons({buttons = {
    {"Save", function()
        writefile("beanbot/configs/".. library.flags["config_name"].. ".bean", window:GetConfig())
    end},
    {"Load", function()
        if isfile("beanbot/configs/".. library.flags["config_selected"].. ".bean") then
            window:LoadConfig(readfile("beanbot/configs/".. library.flags["config_selected"].. ".bean"))
        end
    end}
}})
settings_config:Button({name = "Refresh", callback = function() library.pointers["Settings_Config_Saved configs"]:Refresh(getConfigs()) end})

settings_game:Slider({name = "FPS cap", min = 30, max = 240, def = 60, flag = "game_fps_cap", callback = function() if not library.flags["game_unlimited_fps"] then setfpscap(library.flags["game_fps_cap"]) end end})
settings_game:Toggle({name = "Unlocked FPS cap", flag = "game_unlimited_fps", callback = function() setfpscap(library.flags["game_unlimited_fps"] == true and 100000 or library.flags["game_fps_cap"]) end})


utility:Connect(rs.RenderStepped, function()
    aimbot_target = nil
    ragebot_target = nil

    if library.flags["aimbot_fov"] then
        FOV.Position = uis:GetMouseLocation()
    end

    local aimbot_max_fov = library.flags["aimbot_fov_size"]
    local ragebot_distance = math.huge
    for _, plr in pairs(game.Players:GetPlayers()) do
        if isAlive(lplr) and isTarget(plr, true) then
            if library.flags["aimbot_enabled"] then
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(plr.Character.Head.Position)
                local mag = (uis:GetMouseLocation() - Vector2.new(pos.X, pos.Y)).magnitude
                if mag < aimbot_max_fov and onScreen then
                    aimbot_target = plr.Character.Head
                    aimbot_max_fov = mag
                end
            end
            if library.flags["ragebot_enabled"] then
                local ray = Ray.new(lplr.Character.HumanoidRootPart.Position, (lplr.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).unit * 9999)
                local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {lplr.Character, workspace.Ignored})
                if library.flags["ragebot_vis"] and hit and hit.Parent ~= nil or not library.flags["ragebot_vis"] then
                    if (lplr.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).magnitude < ragebot_distance then
                        ragebot_distance = (lplr.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).magnitude
                        ragebot_target = plr.Character[library.flags["ragebot_hitbox"]]
                    end
                end
            end
        end
        if library.flags["esp_enabled"] and isTarget(plr, library.flags["esp_teammates"]) and esp_stuff[plr] then
            local player_table = esp_stuff[plr]

            local bbox_orintation, bbox_size = plr.Character:GetBoundingBox()

            local width = (workspace.CurrentCamera.CFrame - workspace.CurrentCamera.CFrame.p) * Vector3.new((math.clamp(bbox_size.X, 1, 10) + 0.5) / 2, 0, 0)
            local height = (workspace.CurrentCamera.CFrame - workspace.CurrentCamera.CFrame.p) * Vector3.new(0, (math.clamp(bbox_size.X, 1, 10) + 2) / 2, 0)

            width = math.abs(workspace.CurrentCamera:WorldToViewportPoint(bbox_orintation.Position + width).X - workspace.CurrentCamera:WorldToViewportPoint(bbox_orintation.Position - width).X)
            height = math.abs(workspace.CurrentCamera:WorldToViewportPoint(bbox_orintation.Position + height).Y - workspace.CurrentCamera:WorldToViewportPoint(bbox_orintation.Position - height).Y)
            
            local size = Vector2.new(math.floor(width), math.floor(height))

            local rootPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)

            if onScreen then
                if library.flags["esp_box"] then
                    player_table.Box.Visible = onScreen
                    player_table.Box.Size = size
                    player_table.Box.Position = Vector2.new(math.floor(rootPos.X), math.floor(rootPos.Y)) - (player_table.Box.Size / 2)
                    player_table.Box.Color = library.flags["esp_box_color"]

                    player_table.BoxOutline.Visible = onScreen
                    player_table.BoxOutline.Size = size
                    player_table.BoxOutline.Position = Vector2.new(math.floor(rootPos.X), math.floor(rootPos.Y)) - (player_table.Box.Size / 2)
                else
                    player_table.Box.Visible = false
                    player_table.BoxOutline.Visible = false
                end

                if library.flags["esp_health"] then
                    player_table.Health.Visible = onScreen
                    player_table.Health.Size = Vector2.new(2, size.Y * (1-((plr.Character.Humanoid.MaxHealth - plr.Character.Humanoid.Health) / plr.Character.Humanoid.MaxHealth)))
                    player_table.Health.Position = Vector2.new(math.floor(rootPos.X) - 6, math.floor(rootPos.Y) + (size.Y - math.floor(player_table.Health.Size.Y))) - size / 2
                    player_table.Health.Color = library.flags["esp_health_color"]

                    player_table.HealthOutline.Visible = onScreen
                    player_table.HealthOutline.Size = Vector2.new(4, size.Y + 2)
                    player_table.HealthOutline.Position = Vector2.new(math.floor(rootPos.X) - 7, math.floor(rootPos.Y) - 1) - size / 2
                else
                    player_table.Health.Visible = false
                    player_table.HealthOutline.Visible = false
                end

                if library.flags["esp_name"] then
                    player_table.Name.Visible = onScreen
                    player_table.Name.Position = Vector2.new(math.floor(rootPos.X), math.floor(rootPos.Y) - size.Y / 2 - 16)
                    player_table.Name.Color = library.flags["esp_name_color"]
                else
                    player_table.Name.Visible = false
                end

                if library.flags["esp_chams"] then
                    if plr.Character:FindFirstChildOfClass("Highlight") == nil then
                        local highlight = Instance.new("Highlight", plr.Character)
                        highlight.FillTransparency = 0.3
                        highlight.OutlineTransparency = 1
                    end
                    plr.Character.Highlight.FillColor = library.flags["esp_chams_color"]
                    if library.flags["esp_chams_outline"] then
                        plr.Character.Highlight.OutlineTransparency = 0.3
                        plr.Character.Highlight.OutlineColor = library.flags["esp_chams_outline_color"]
                    else
                        plr.Character.Highlight.OutlineTransparency = 1
                    end
                else
                    if plr.Character:FindFirstChildOfClass("Highlight") then
                        plr.Character:FindFirstChildOfClass("Highlight"):Destroy()
                    end
                end
            else
                for i, v in pairs(player_table) do
                    v.Visible = false
                end
                
                if plr.Character:FindFirstChildOfClass("Highlight") then
                    plr.Character:FindFirstChildOfClass("Highlight"):Destroy()
                end
            end
        else
            if esp_stuff[plr] then
                for i, v in pairs(esp_stuff[plr]) do
                    if v.Visible ~= false then
                        v.Visible = false
                    end
                end
            end

            if isAlive(plr) and plr.Character:FindFirstChildOfClass("Highlight") then
                plr.Character:FindFirstChildOfClass("Highlight"):Destroy()
            end
        end
    end

    if isAlive(lplr) then
        if library.flags["aimbot_enabled"] and aimbot_target then
            local vector, _ = workspace.CurrentCamera:WorldToViewportPoint(aimbot_target.Position)
            local mag = (uis:GetMouseLocation() - Vector2.new(vector.X, vector.Y)).magnitude
            mousemoverel(-mag.X, -mag.Y)
        end
        if library.flags["ragebot_enabled"] and library.flags["ragebot_autoshoot"] and ragebot_target and lplr.Character:FindFirstChildOfClass("Tool") and lplr.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Ammo") then
            lplr.Character:FindFirstChildOfClass("Tool"):Activate()
        end
    end
end)

utility:Connect(rs.Heartbeat, function()
    if isAlive(lplr) then
        if library.flags["desync_enabled"] then
            desync_stuff[1] = lplr.Character.HumanoidRootPart.CFrame
            if library.flags["desync_fling"] then
                desync_stuff[2] = lplr.Character.HumanoidRootPart.Velocity
            end

            local fakeCFrame = lplr.Character.HumanoidRootPart.CFrame

            if library.flags["desync_mode"] == "Offset" then
                fakeCFrame = fakeCFrame * CFrame.new(Vector3.new(library.flags["desync_offset_x"], library.flags["desync_offset_y"], library.flags["desync_offset_z"]))
            elseif library.flags["desync_mode"] == "Random" then
                fakeCFrame = fakeCFrame * CFrame.new(RandomVectorRange(library.flags["desync_random_x"], library.flags["desync_random_y"], library.flags["desync_random_z"]))
            elseif library.flags["desync_mode"] == "Zero" then
                fakeCFrame = CFrame.new()
            elseif library.flags["desync_mode"] == "Target strafe" and game.Players:FindFirstChild(library.flags["desync_targetstrafe_selected"]) and isAlive(game.Players[library.flags["desync_targetstrafe_selected"]]) then
                fakeCFrame = game.Players[library.flags["desync_targetstrafe_selected"]].Character.HumanoidRootPart.CFrame
                if not desync_stuff[3] then
                    desync_stuff[3] = 0
                end
                if desync_stuff[3] > 360 then
                    desync_stuff[3] = 0
                end
                fakeCFrame = fakeCFrame * CFrame.Angles(0, math.rad(desync_stuff[3]), 0) * CFrame.new(0, 0, library.flags["desync_targetstrafe_offset"])
                desync_stuff[3] = desync_stuff[3] + library.flags["desync_targetstrafe_speed"]
            end

            if library.flags["desync_rotation"] == "Manual" then
                fakeCFrame = fakeCFrame * CFrame.Angles(math.rad(library.flags["desync_manual_x"]), math.rad(library.flags["desync_manual_y"]), math.rad(library.flags["desync_manual_z"]))
            elseif library.flags["desync_rotation"] == "Random" then
                fakeCFrame = fakeCFrame * CFrame.Angles(math.rad(RandomNumberRange(180)), math.rad(RandomNumberRange(180)), math.rad(RandomNumberRange(180)))
            end

            if library.flags["desync_visualize"] then
                r6_dummy.Parent = workspace
                r6_dummy.HumanoidRootPart.Velocity = Vector3.new()
                r6_dummy:SetPrimaryPartCFrame(fakeCFrame)
            else
                r6_dummy.Parent = nil
            end

            lplr.Character.HumanoidRootPart.CFrame = fakeCFrame
            if library.flags["desync_fling"] then
                lplr.Character.HumanoidRootPart.Velocity = Vector3.new(1, 1, 1) * 16384
            end 

            rs.RenderStepped:Wait()

            lplr.Character.HumanoidRootPart.CFrame = desync_stuff[1]
            if library.flags["desync_fling"] then
                lplr.Character.HumanoidRootPart.Velocity = desync_stuff[2]
            end
        else
            if r6_dummy.Parent ~= nil then
                r6_dummy.Parent = nil
            end
        end
    else
        if r6_dummy.Parent ~= nil then
            r6_dummy.Parent = nil
        end
    end

    if isAlive(lplr) then
        if library.flags["cframe_walk_enabled"] then
            if lplr.Character.Humanoid.MoveDirection.Magnitude > 0 then
                for i = 1, library.flags["cframe_walk_speed"] do
                    lplr.Character:TranslateBy(lplr.Character.Humanoid.MoveDirection)
                end
            end
        end
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if library.loaded then
        if method == "FireServer" then
            if args[1] == "UpdateMousePos" and library.flags["ragebot_enabled"] and ragebot_target then
                args[2] = ragebot_target.Position + (ragebot_target.Parent.Humanoid.MoveDirection * library.flags["ragebot_prediction"])
            end
        end
    end

    return oldNamecall(self, unpack(args))
end))

local oldIndex

oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if library.loaded then
        if not checkcaller() then
            if key == "CFrame" and library.flags["desync_enabled"] and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") and lplr.Character:FindFirstChild("Humanoid") and lplr.Character:FindFirstChild("Humanoid").Health > 0 then
                if self == lplr.Character.HumanoidRootPart then
                    return desync_stuff[1] or CFrame.new()
                elseif self == lplr.Character.Head then
                    return desync_stuff[1] and desync_stuff[1] + Vector3.new(0, lplr.Character.HumanoidRootPart.Size / 2 + 0.5, 0) or CFrame.new()
                end
            end
        end
    end
    return oldIndex(self, key)
end))

window:Update()
window:Load()
