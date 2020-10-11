local CHROMIUM_BRANCH    =  BRANCH == "chromium"
local LUA_EDITOR_URL     =  CHROMIUM_BRANCH and "https://metastruct.github.io/gmod-monaco/" or "http://metastruct.github.io/lua_editor/"



local surface       = surface
local draw          = draw
local vgui          = vgui
local Lerp          = Lerp
local unpack        = unpack
local math          = math
local string        = string
local table         = table
local utf8          = utf8
local pairs         = pairs
local ipairs        = ipairs
local CompileString = CompileString

/////////////////////////////////
--  net & net strucure logger  --
/////////////////////////////////

local function NiceTab(tablen,...)
    local args  = {...}
    local ret = ""
    local tlen = tablen or 23
    
    for i=1,#args
    do
        local curlen  = utf8.len(utf8.force( tostring( args[i] ) ))
        ret = ret .. args[i] .. string.rep(" ",tlen-curlen) .. ( curlen >= tlen and " " or "" )
    end

    return ret
end

NET = NET or table.Copy( net )

local NET_LOGGER_STRUCTURES_COUNT = 0
NET_LOGGER_STRUCTURES = NET_LOGGER_STRUCTURES or {}

local STRUCTURE_BUFFER = {}

function net.ReadInt(bitCount)  local data = NET.ReadInt(bitCount) STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "int"  .. bitCount .. ":", "0x".. bit.tohex(data) , data   )return data end
function net.ReadUInt(bitCount) local data = NET.ReadUInt(bitCount)STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Uint" .. bitCount .. ":","0x" .. bit.tohex(data)  , data  )return data end
function net.ReadString()       local data = NET.ReadString()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "String:","\"".. data .. "\""                              )return data end
function net.ReadEntity()       local data = NET.ReadEntity()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Entity:", tostring( data )                                )return data end
function net.ReadVector()       local data = NET.ReadVector()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Vector:", tostring( data )                                )return data end
function net.ReadAngle()        local data = NET.ReadAngle()       STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Table:" , table.ToString( data , "",false )               )return data end
function net.ReadTable()        local data = NET.ReadTable()       STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Angle:" , tostring( data )                                )return data end
function net.ReadColor()        local data = NET.ReadColor()       STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Color:" , tostring( data )                                )return data end
function net.ReadFloat()        local data = NET.ReadFloat()       STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Float:" , data                                            )return data end
function net.ReadDouble()       local data = NET.ReadDouble()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Double:", data                                            )return data end
function net.ReadNormal()       local data = NET.ReadNormal()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Vector(Normal):",tostring( data )                         )return data end
function net.ReadMatrix()       local data = NET.ReadMatrix()      STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Matrix:"        ,tostring( data )                         )return data end
function net.ReadData(length)   local data = NET.ReadData(length)  STRUCTURE_BUFFER[ #STRUCTURE_BUFFER + 1 ]  = NiceTab(23, "Binary Data:","<" .. length .. ">"                        )return data end

function net.Incoming( len, client )

	local i = net.ReadHeader()
	local strName = util.NetworkIDToString( i )
	
	if ( !strName ) then return end
	
	local func = net.Receivers[ strName:lower() ]
	if ( !func ) then return end

    len = len - 16
    
    STRUCTURE_BUFFER = {}
    
    func( len, client )

    if NET_LOGGER_STRUCTURES_COUNT > 2048 then NET_LOGGER_STRUCTURES = {} end
    
    NET_LOGGER_STRUCTURES[ strName ] = NET_LOGGER_STRUCTURES[ strName ] or {}
    NET_LOGGER_STRUCTURES[ strName ][ tostring( util.CRC( table.concat(STRUCTURE_BUFFER ,"" )  ) ) ] = STRUCTURE_BUFFER
    NET_LOGGER_STRUCTURES_COUNT = NET_LOGGER_STRUCTURES_COUNT + #STRUCTURE_BUFFER
end

/////////////////////////////////////////////////////
-- don't let special characters break the js queue --
/////////////////////////////////////////////////////
local replace =
{
    ["\n"] = "\\n" ,
    ["\0"] = "\\0" ,
    ["\b"] = "\\b" ,
    ["\t"] = "\\t" ,
    ["\v"] = "\\v" ,
    ["\f"] = "\\f" ,
    ["\r"] = "\\r" ,
    ["\""] = "\\\"",
    ["\'"] = "\\\'",
    ["\\"] = "\\\\",
}

local function SafeJS( js )
    return js:gsub(".",replace)
end



local LUA_SESSIONS = {}

local LUA_EDITOR_PRINT = function( ... )
    print( ... )

    if !LUA_EDITOR_FRAME then return end
    for k,v in pairs( { ... } )
    do
        LUA_EDITOR_FRAME.Console:InsertColorChange(255,255,255,255)
        LUA_EDITOR_FRAME.Console:AppendText( tostring( v ) )
        LUA_EDITOR_FRAME.Console:AppendText( "\n" )
    end
end

/////////////////////////////////////////////////////////
-- here you can put the functions you want to override --
/////////////////////////////////////////////////////////
local _FN_ENV = {
    print = LUA_EDITOR_PRINT,
    --net   = {}
}

local function Compile( code,sessionID )
    local var = CompileString( code,"",false)
    if isstring( var ) then return var end
    --              Maybe better localize it?
    local NEW_ENV = table.Copy( debug.getfenv( var ) )

    for k,v in pairs( _FN_ENV )
    do
        NEW_ENV[k] = v 
    end

    NEW_ENV["hook"]["Add"] = function(eventname,id,fn) 
        --id = id .. "_lua_editor"
        LUA_SESSIONS[sessionID] = LUA_SESSIONS[sessionID] or {} 
        LUA_SESSIONS[sessionID]["hooks"] = LUA_SESSIONS[sessionID]["hooks"] or {} 
        LUA_SESSIONS[sessionID]["hooks"][eventname] = { eventname,id,fn } 
        hook.Add(eventname,id,fn) 
    end    
    NEW_ENV["hook"]["Remove"] = function(eventname,id,fn) 
        --id = id .. "_lua_editor"
        LUA_SESSIONS[sessionID] = LUA_SESSIONS[sessionID] or {} 
        LUA_SESSIONS[sessionID]["hooks"] = LUA_SESSIONS[sessionID]["hooks"] or {} 
        LUA_SESSIONS[sessionID]["hooks"][eventname] = nil
    end
    NEW_ENV["timer"]["Create"] = function(id,delay,rep,fn) 
        --id = id .. "_lua_editor"
        LUA_SESSIONS[sessionID] = LUA_SESSIONS[sessionID] or {} 
        LUA_SESSIONS[sessionID]["timers"] = LUA_SESSIONS[sessionID]["timers"] or {} 
        LUA_SESSIONS[sessionID]["timers"][id] = { id,delay,rep,fn } 
        timer.Create(id,delay,rep,fn) 
    end    

    local delTimer = function(...) 
        local id = ...
        --id = id .. "_lua_editor"
        LUA_SESSIONS[sessionID] = LUA_SESSIONS[sessionID] or {} 
        LUA_SESSIONS[sessionID]["timers"] = LUA_SESSIONS[sessionID]["timers"] or {} 
        LUA_SESSIONS[sessionID]["timers"][id] = nil
    end

    NEW_ENV["timer"]["Remove"] = function(...) 
        delTimer( ... )
        timer.Remove(...)
    end    
    NEW_ENV["timer"]["Destroy"] = function(...) 
        delTimer( ... )
        timer.Destroy(...)
    end    
    
    debug.setfenv( var , NEW_ENV )

    return var
end

////////////////
-- LUA EDITOR --
////////////////

local PANEL = {}

function PANEL:UpdateColours( )
    return self:SetTextStyleColor( color_white )
end

local btNormal = Color(0,0,0,0)
local btHovered = Color(100,100,100,50)
local btDown= Color(100,100,100,150)

function PANEL:Paint(w,h)
    surface.SetDrawColor( self:IsDown() and btDown or self:IsHovered() and btHovered or btNormal )
    surface.DrawRect(0,0,w,h)
end

vgui.Register("LUAEDITOR_Button", PANEL , "DButton")

local PANEL = {}

function PANEL:Init()
    self.time = 0
end

function PANEL:Paint(w,h)
    surface.SetDrawColor(39, 40, 34)
    surface.DrawRect(0,0,w,h)
    local W = w * 0.05
    local H = w * 0.05

    local mult = math.max( surface.GetAlphaMultiplier() , 0.7 )
    
    surface.SetAlphaMultiplier( 1 )
    surface.SetDrawColor(12 * mult, 125 * mult, 157 * mult)
    
    draw.NoTexture()
    
    surface.DrawTexturedRectRotated(w * 0.5 - W * 0.5 , h * 0.5 - H * 0.5,W,H,self.time)
    surface.DrawTexturedRectRotated(w * 0.5 - W * 0.5 , h * 0.5 - H * 0.5,W,H,self.time + math.sin( CurTime() ) * 40 )

    self.time = self.time + 2
end

vgui.Register("LUAEDITOR_LoadingPanel", PANEL , "DPanel")

local PANEL = {}
function PANEL:Init()
    self.BaseClass.Init(self)
    self.CloseBt = vgui.Create("LUAEDITOR_Button",self)
    self.CloseBt:Dock(RIGHT)
    self.CloseBt:SetText("X")
    self.CloseBt:SizeToContents()
    self.CloseBt.DoClick = function() 
        if #self:GetPropertySheet():GetItems() == 1 then LUA_EDITOR_FRAME:AddEditorTab() end
        self:GetPropertySheet():CloseTab(self) 
    end

    self.AnimFrac = 0
end

function PANEL:PerformLayout(w,h)
    self:SetTall(22)
end

function PANEL:Paint(w,h)
    self.AnimFrac = Lerp(0.1,self.AnimFrac, self:IsActive() and 1 or 0 )

    surface.SetDrawColor(70,70,70,self.AnimFrac * 255)
    surface.DrawRect(0,0,w,h)  
end

vgui.Register("LUAEDITOR_DTab", PANEL , "DTab")

local PANEL = {}
function PANEL:Init()
    self.btnMaxim:SetDisabled(false)
    self.btnMaxim.DoClick = function()
        if self.LastSize
        then
            self:SetSize( unpack( self.LastSize ) )
            self:SetPos( unpack( self.LastPos ) )
            self.LastSize = nil
            self.LastPos  = nil
        else
            self.LastSize = {self:GetSize()}
            self.LastPos  = {self:GetPos()}
            
            self:SetSize( ScrW() , ScrH() )
            self:Center()
        end
    end
end

function PANEL:Paint(w,h)
    surface.SetDrawColor(54, 54, 54)
    surface.DrawRect(0,0,w,h)
end

vgui.Register("LUAEDITOR_DFrame", PANEL , "DFrame")

local PANEL = {}
function PANEL:Init()
    self.Canvas = vgui.Create("DPanel",self)

    self.Canvas:Hide()
    self.Canvas:SetBackgroundColor( Color( 40,40,40 ) )

    self.Canvas:SetTall( 0 )
    self.Canvas.OnFocusChanged = function(self,gained) if !gained then self:Hide() end end
    self.Offset = 0
end

function PANEL:OnRemove()
    self.Canvas:Remove()
end

function PANEL:DoClick()
    self.Canvas:SetVisible( !self.Canvas:IsVisible() )
    self.Canvas:SetPos( input.GetCursorPos() )
    self.Canvas:MakePopup()
end

function PANEL:AddOption( name , callback )
    local Option = vgui.Create("LUAEDITOR_Button",self.Canvas)
    Option:SetPos( 0 , 5 + 25 * self.Offset )
    
    Option:SetText(name)
    Option:SizeToContentsX( 15 )

    if self.Canvas:GetWide() < Option:GetWide() - 5
    then
        self.Canvas:SetWide( Option:GetWide() )
        for k,v in ipairs(self.Canvas:GetChildren() )
        do
            v:SetWide( Option:GetWide() )
        end
    end

    self.Canvas:SetTall( self.Canvas:GetTall() + Option:GetTall() + 5  )
    Option:SetWide( self.Canvas:GetWide() )
    Option.DoClick = callback
    self.Offset = self.Offset + 1
end

vgui.Register("LUAEDITOR_Options",PANEL,"LUAEDITOR_Button")

local PANEL = {}

function PANEL:Init()
    self:SetSize( ScrW() * 0.7 , ScrH() * 0.7 )
    self:Center()

    self:SetSizable( true )
    self:MakePopup()

    self:SetTitle("")
    
    self.btnClose.DoClick = function() self:Hide() end

    local panel1 = vgui.Create("DPanel")
    panel1:SetDrawBackground(false)

    self.EditorTabsSheet = vgui.Create("DPropertySheet",panel1 )
    
    self.EditorTabsSheet:Dock(FILL)
    self.EditorTabsSheet:DockMargin(0,0,0,-15)
    self.EditorTabsSheet.tabScroller:SetOverlap(0)
    self.EditorTabsSheet.Paint = function() end

    function self.EditorTabsSheet:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )
        if ( !IsValid( panel ) ) then
            ErrorNoHalt( "DPropertySheet:AddSheet tried to add invalid panel!" )
            debug.Trace()
            return
        end
    
        local Sheet = {}
    
        Sheet.Name = label
    
        Sheet.Tab = vgui.Create( "LUAEDITOR_DTab", self )
        Sheet.Tab:SetTooltip( Tooltip )
        Sheet.Tab:Setup( label .. "   " , self, panel, material )
    
        Sheet.Panel = panel
        Sheet.Panel.NoStretchX = NoStretchX
        Sheet.Panel.NoStretchY = NoStretchY
        Sheet.Panel:SetPos( self:GetPadding(), 20 + self:GetPadding() )
        Sheet.Panel:SetVisible( false )
    
        panel:SetParent( self )
    
        table.insert( self.Items, Sheet )
    
        if ( !self:GetActiveTab() ) then
            self:SetActiveTab( Sheet.Tab )
            Sheet.Panel:SetVisible( true )
        end
    
        self.tabScroller:AddPanel( Sheet.Tab )
    
        return Sheet
    
    end

    local panel2 = vgui.Create("DPanel")
    panel2:SetDrawBackground(false)
    
    self.Console = vgui.Create("RichText",panel2)
    self.Console:Dock(FILL)
    self.Console:DockMargin(6,0,8,3)
    self.Console.Paint = function( _,w,h )
        surface.SetDrawColor(12, 125, 157)
        surface.DrawRect(0,0,w,2)
    end

    local divider = vgui.Create("DVerticalDivider",self)
    
    divider:Dock(FILL)
    divider:DockMargin(-13,1,-13,0)
    
    divider:SetTop( panel1 )
    divider:SetBottom( panel2 )
    divider:SetDividerHeight( 4 )
    divider:SetTopHeight( self:GetTall() - 200 )

    local optionsHolder = vgui.Create("DPanel",self)
    optionsHolder:Dock(TOP)
    optionsHolder:DockMargin(-5,-20,100,-1)
    optionsHolder:SetDrawBackground(false)

    local FileOptions = vgui.Create("LUAEDITOR_Options",optionsHolder)
    FileOptions:Dock(LEFT)
    FileOptions:SetText("File")
    FileOptions:AddOption("New File",function() 
        self:AddEditorTab()
        self:MakePopup()
    end)

    FileOptions:AddOption("Save As",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.2 , ScrH() * 0.2)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        local te = vgui.Create("DTextEntry",frame)
        te:Dock(TOP)
        te:RequestFocus()
        
        if !string.find( self:GetActiveEditorTab():GetText() , "Lua session" )
        then
            te:SetText( string.GetFileFromFilename( string.Replace( self:GetActiveEditorTab():GetText() ," " , "") ) )
        end
        local lbl = vgui.Create("DLabel",frame)
        lbl:Dock(TOP)
        lbl:SetText("<foldername>/<filename> to save into folder")
        local bt = vgui.Create("LUAEDITOR_Button",frame)
        bt:Dock(BOTTOM)
        bt:SetText("Save")

        bt.DoClick = function()  
            local path = te:GetText() .. "  "
            local panel = self:GetActiveEditorTab():GetPanel()
            
            if string.find(path,"/") 
            then 
                file.CreateDir( string.GetPathFromFilename( path ) )
                local path = string.GetPathFromFilename( path ) .. "/" .. string.GetFileFromFilename(path)
                file.Write( path ,self:GetActiveEditor():GetCode() )
                panel.SaveTo = path
            else
                panel.SaveTo = path
                file.Write(path,self:GetActiveEditor():GetCode() )
            end
            self:GetActiveEditorTab():SetText( string.GetFileFromFilename(path) )

            frame:Close()
        end
    end)
    FileOptions:AddOption("Open File",function() 
        
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.5)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        local browser = vgui.Create( "DFileBrowser", frame )
        browser:Dock( FILL )

        browser:SetPath( "GAME" )
        browser:SetBaseFolder( "data" ) 
        browser:SetOpen( true ) 
        browser:SetSearch( "*" )
        browser:SetFileTypes("*.txt")
        browser.OnSelect = function( _,path, pnl )
            self:AddEditorTab( file.Read(path, "GAME"), string.GetFileFromFilename( path ) )
            local panel = self:GetActiveEditorTab():GetPanel()
            panel.SaveTo =  string.Replace(path,"data/","")
            frame:Close()
        end
    end)

    FileOptions:AddOption("Load code from url",function() 
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.2 , ScrH() * 0.1)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        local te = vgui.Create("DTextEntry",frame)
        te:Dock(TOP)
        te:RequestFocus()

        local bt = vgui.Create("LUAEDITOR_Button",frame)
        bt:Dock(BOTTOM)
        bt:SetText("Load")

        bt.DoClick = function()  
            http.Fetch( te:GetText() , function( body,_,_,_ )
                self:AddEditorTab( body )
                self:MakePopup()
                frame:Close()
            end)
        end

    end)

    local LuaOptions = vgui.Create("LUAEDITOR_Options",optionsHolder)
    LuaOptions:Dock(LEFT)
    LuaOptions:SetText("LUA")    
    
    LuaOptions:AddOption("Deyvan's lua syntax tool",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)
        local HTML = vgui.Create("DHTML",frame)
        HTML:Dock(FILL)
        HTML:DockMargin(-13,-9,-13,0)
        HTML:OpenURL("https://deyvan.github.io/glua_syntax_tool/")
        HTML:QueueJavascript([[document.getElementById("info").style.display="none"]])

        local loadingpanel = vgui.Create("LUAEDITOR_LoadingPanel",frame)
        loadingpanel:Dock(FILL)
        function HTML:OnDocumentReady() 
            loadingpanel:AlphaTo(0,0.2,0,function() loadingpanel:Remove()  HTML:RequestFocus() end)
        end
    end)    

    LuaOptions:AddOption("Gmod wiki",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
            frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
            frame:Center()
            frame:SetTitle("")
            frame:MakePopup()
            frame:SetSizable(true)
            local HTML = vgui.Create("DHTML",frame)
            HTML:Dock(FILL)
            HTML:DockMargin(0,-5,0,0)
            HTML:OpenURL("https://wiki.facepunch.com/gmod/")
            local loadingpanel = vgui.Create("LUAEDITOR_LoadingPanel",frame)
            loadingpanel:Dock(FILL)
            function HTML:OnDocumentReady() 
                loadingpanel:AlphaTo(0,0.2,0,function() loadingpanel:Remove()  HTML:RequestFocus() end)
            end
    end)

    LuaOptions:AddOption("Lua Sessions",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.5)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        local scroll = vgui.Create("DScrollPanel",frame)
        scroll:Dock(FILL)
        local function generate()
            scroll:Clear()
            for UID,Session in pairs( LUA_SESSIONS )
            do
                local cat = vgui.Create("DCollapsibleCategory",scroll)
                cat:Dock(TOP)
                cat:SetTall(150)
                cat:SetLabel( UID )
                local scroll = vgui.Create("DScrollPanel",cat)
                scroll:Dock(FILL)

                for eventname,data in pairs( Session.hooks or {} )
                do
                    local panel = vgui.Create("DPanel",scroll)
                    panel:Dock(TOP)
                    panel:DockMargin(10,10,10,0)
                    panel:SetTall(50)
                    local lbltitle = vgui.Create("DLabel",panel)
                    lbltitle:Dock(TOP)
                    lbltitle:DockMargin(6,0,0,0)

                    lbltitle:SetText( string.format("hook.Add(%q,%q,function %p)",unpack(data)) )
                    lbltitle:SetTextColor( color_black ) 

                    local terminate = vgui.Create("DButton",panel)
                    terminate:Dock(TOP)
                    terminate:DockMargin(5,0,5,0)
                    terminate:SetText("Terminate hook")
                    terminate.DoClick = function() hook.Remove( data[1] , data[2] ) Session.hooks[eventname] = nil generate() end
                end   

                for id,data in pairs( Session.timers or {} )
                do
                    local panel = vgui.Create("DPanel",scroll)
                    panel:Dock(TOP)
                    panel:DockMargin(10,10,10,0)
                    panel:SetTall(50)
                    local lbltitle = vgui.Create("DLabel",panel)
                    lbltitle:Dock(TOP)
                    lbltitle:DockMargin(6,0,0,0)
                    lbltitle:SetText( string.format("timer.Create(%q,%s,%s,function %p)",unpack(data)) )
                    lbltitle:SetTextColor( color_black ) 

                    local terminate = vgui.Create("DButton",panel)
                    terminate:Dock(TOP)
                    terminate:DockMargin(5,0,5,0)
                    terminate:SetText("Terminate timer")
                    terminate.DoClick = function()  timer.Remove( data[1] ) Session.timers[id] = nil generate() end
                end 
                
                if #cat:GetChildren() == 0 then cat:SetExpanded(false) end
            end
        end
        generate()

        local refreshBt = vgui.Create("LUAEDITOR_Button",frame)
        refreshBt:Dock(TOP)
        refreshBt:DockMargin(-5,-29, frame:GetWide() - 150 ,10)
        refreshBt:SetText("Refresh")
        refreshBt.DoClick = generate
    end) 

    LuaOptions:AddOption("net logger",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        NET_LOGGER_FRAME = frame
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)

        local netrecievers = vgui.Create("DScrollPanel",frame)
        netrecievers:Dock(LEFT)
        
        for k,v in pairs( net.Receivers )
        do
            local label = vgui.Create("DTextEntry",netrecievers)
            label:Dock(TOP)
            label:DockMargin(5,0,0,0)
            label:SetText(k)
        end

        frame.netStructures = vgui.Create("DScrollPanel",frame)
        frame.netStructures:Dock(RIGHT)

        local function generate()
            frame.netStructures:Clear()

            local refreshButton = vgui.Create("LUAEDITOR_Button",frame.netStructures)
            refreshButton:Dock(TOP)
            refreshButton:DockMargin(-50,0,-50,10)
            refreshButton:SetText("Refresh")
            refreshButton.DoClick = generate

            local clearButton = vgui.Create("LUAEDITOR_Button",frame.netStructures)
            clearButton:Dock(TOP)
            clearButton:DockMargin(-50,0,-50,10)
            clearButton:SetText("Clear")
            clearButton.DoClick = function() NET_LOGGER_STRUCTURES = {} generate() end

            for k,v in pairs( NET_LOGGER_STRUCTURES )
            do
         
                local scroll = frame.netStructures[k]
                
                if !cat
                then
                    local lframe = vgui.Create("DFrame",frame.netStructures)
                    lframe:Dock(TOP)
                    lframe:SetTall(150)
                    lframe:SetTitle( k )
                    lframe:SetSizable(true)

                    local unpin = vgui.Create("DButton",lframe)
                    unpin:SetPos( 0,20 )
                    unpin:SetText("x")
                    unpin:SizeToContents()
                    unpin.DoClick = function(_,val) 
                                            lframe:SetParent(nil) 
                                            lframe:Dock(0)
                                            lframe:MakePopup()
                                            unpin:Remove()
                    end
                    
                    scroll = vgui.Create("DScrollPanel",lframe)
                    scroll:Dock(FILL)

                    frame.netStructures[k] = scroll
                    
                end
                for k,v in pairs( v )
                do
                    local line = nil
                    for k,v in pairs( v )
                    do
                        line = vgui.Create("DTextEntry",scroll)
                        line:Dock(TOP)
                        line:DockMargin(5,1,5,0)
                        line:SetText( v )
                    end
                    if line then line:DockMargin(5,1,5,15) end
                end
            end

        end
        generate()

        
        local _PerformLayout = frame.PerformLayout
        function frame:PerformLayout(w,h)
            _PerformLayout(self,w,h)
            netrecievers:SetWide( w / 2 - 10 )
            frame.netStructures:SetWide( w / 2 - 10 )
        end
    end)

    LuaOptions:AddOption("hook finder",function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        NET_LOGGER_FRAME = frame
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)

        local scroll = vgui.Create("DScrollPanel",frame)
        scroll:Dock(FILL)
        
        local hooks = hook.GetTable()
        for eventname,tbl in pairs(hooks)
        do
            for id,fn in pairs(tbl)
            do
                local fninfo = debug.getinfo(fn) 
                local label = vgui.Create("DTextEntry",scroll)
                label:Dock(TOP)
                label:DockMargin(5,0,5,0)
                label:SetText( NiceTab(46,eventname , tostring( id ) , "Source :" .. fninfo.short_src .. ":" .. fninfo.linedefined   ) )
                local terminate = vgui.Create("DButton",scroll)
                terminate:Dock(TOP)
                terminate:DockMargin(5,0,5,20)
                terminate:SetText("Terminate hook")
                terminate.DoClick = function() hook.Remove( eventname,id ) label:Remove() terminate:Remove() end
            end
        end
    end)
    self.LuaSessionUID = 1

    -- I really don't know why i added this but why not
    local Rextester = vgui.Create("LUAEDITOR_Button",optionsHolder)
    Rextester:Dock(RIGHT)
    Rextester:SetText("rextester")

    Rextester.DoClick = function()
        local frame = vgui.Create("LUAEDITOR_DFrame")
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)
        
        local HTML = vgui.Create("DHTML",frame)
        HTML:Dock(FILL)
        HTML:DockMargin(-13,-9,0,0)
        HTML:OpenURL("https://rextester.com/")
        local loadingpanel = vgui.Create("LUAEDITOR_LoadingPanel",frame)
        loadingpanel:Dock(FILL)
        function HTML:OnDocumentReady() 
            loadingpanel:AlphaTo(0,0.2,0,function() loadingpanel:Remove()  HTML:RequestFocus() end)
        end
    end

    local ColorPicker = vgui.Create("LUAEDITOR_Options",optionsHolder)
    ColorPicker:Dock(LEFT)
    ColorPicker:SetText("Color Picker")
    local colormixer = vgui.Create("DColorMixer",ColorPicker.Canvas)
    colormixer:Dock(FILL)
    colormixer:SetPalette(true)  	

    local copybutton = vgui.Create("LUAEDITOR_Button",ColorPicker.Canvas)
    copybutton:Dock(BOTTOM)
    copybutton:SetText("Copy color")
    copybutton.DoClick = function() local color = colormixer:GetColor()  SetClipboardText( string.format("%s,%s,%s", color.r,color.g,color.b .. ( color.a != 255 and "," .. color.a or "" ) ) ) end
    ColorPicker.Canvas:SetSize( ScrW() * 0.2 , ScrH() * 0.2 )

    self:AddEditorTab()
end

function PANEL:GetActiveEditorTab()
    return self.EditorTabsSheet:GetActiveTab()
end
function PANEL:GetActiveEditor()
    return self:GetActiveEditorTab():GetPanel().HTML
end

function PANEL:Compile()
    local panel = self:GetActiveEditorTab():GetPanel()

    local var   = Compile( panel.HTML:GetCode() , panel.UID )
    if isfunction( var ) then var() else 
        local line,err = string.match(var,":(%d*):(.+)")
        if line and err
        then
            panel.HTML:SetError( line , err )
            panel.HTML:GotoLine( line)
        end
        LUA_EDITOR_PRINT( var ) 
    end
end

function PANEL:AddEditorTab(Code,UID)

    local panel = vgui.Create("DPanel")
    panel:SetDrawBackground(false)
    panel:Dock(FILL)
    panel:DockMargin(0,0,0,0)

    local HTML = vgui.Create("DHTML",panel)
    panel.HTML = HTML
    
    panel.UID = UID or ( "Lua session #" .. self.LuaSessionUID )
    if !UID then self.LuaSessionUID = self.LuaSessionUID + 1 end

    HTML:Dock(FILL)
    HTML:SetAlpha(0)

    HTML:AddFunction("gmodinterface","OnCode", function(Code)
        HTML.Code = Code
    end)         
    
    function HTML:GetCode()
        return self.Code or ""
    end
    -- TODO:
    -- Write own errors list
    function HTML:SetError( line , error )
        if !CHROMIUM_BRANCH then self:QueueJavascript("SetErr('" .. line .. "','" .. SafeJS(error).. "')") end
    end
    
    function HTML:ClearErrors()
        if !CHROMIUM_BRANCH then self:QueueJavascript("ClearErr()") end
    end

    function HTML:GotoLine(num)
        self:QueueJavascript("GotoLine('" .. num .. "')")
    end

    function HTML:SetCode( Code )
        if CHROMIUM_BRANCH then self:QueueJavascript("gmodinterface.SetCode('" ..  SafeJS( Code ) .. "');") else self:QueueJavascript("SetContent('" ..  SafeJS( Code ) .. "');") end
    end

    local loadingpanel = vgui.Create("LUAEDITOR_LoadingPanel",panel)
    loadingpanel:Dock(FILL)

    HTML:AddFunction("gmodinterface","OnThemesLoaded", function()end)    
    HTML:AddFunction("gmodinterface","OnLanguages", function()end)

    HTML:AddFunction("gmodinterface","OnReady", function()
        if Code then HTML:SetCode(Code) end
        -- force you to look at fucking animation (͡° ͜ʖ ͡°)
        timer.Simple(1,function()
            if !HTML then return end

            xpcall(function()

                    HTML:SetAlpha(255)
                    loadingpanel:AlphaTo(0,0.2,0,function() 

                    loadingpanel:Remove() 
                    HTML:RequestFocus()

                    local _Think = HTML.Think
                    HTML.ValidateDelay = 0
                    function HTML:Think()
                        _Think(self)
                        if self.ValidateDelay < CurTime()
                        then
                            self:ClearErrors()
                            if self:GetCode() != "" 
                            then 
                                local var = Compile( self:GetCode() )
                                if isstring( var ) 
                                then 
                                    local line,err = string.match(var,":(%d*):(.+)")
                                    self:SetError( line , err )
                                end
                            end

                            self.ValidateDelay = CurTime() + 0.5
                        end
                    end

                end)
            end,function() end)
        end)
    end)

    HTML:OpenURL( LUA_EDITOR_URL )

    local sheet = self.EditorTabsSheet:AddSheet( panel.UID  ,panel)
    self.EditorTabsSheet:SetActiveTab( sheet["Tab"] )

end

function PANEL:Paint(w,h)
    surface.SetDrawColor(44,44,44)
    surface.DrawRect(0,0,w,h)
end

function PANEL:Think()
    self.BaseClass.Think(self)
    if input.IsKeyDown( KEY_LCONTROL ) and  input.IsKeyDown( KEY_S )
    then
        if self.KeyToggled then return end
        self.KeyToggled = true

        self:Compile()
        
        local panel = self:GetActiveEditorTab():GetPanel()
        if panel.SaveTo then file.Write(panel.SaveTo, panel.HTML:GetCode() ) end
    else
        self.KeyToggled = false
    end
end

vgui.Register("LUAEDITOR_Frame",PANEL,"LUAEDITOR_DFrame")

concommand.Add("lua_editor",function()
    if LUA_EDITOR_FRAME then  LUA_EDITOR_FRAME:Remove() end
    LUA_EDITOR_FRAME = vgui.Create("LUAEDITOR_Frame")
end)
