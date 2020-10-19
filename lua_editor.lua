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


-- Fixed by Deyvan
--  For some reason starfall give an error with table copy
--  not cool yet...
local function tableCopy( t, lookup_table )
	if ( t == nil ) then return nil end
    local copy = {}
    if lookup_table then setmetatable(copy, debug.getmetatable(t)) end
    for i, v in pairs( t ) do
		if ( !istable( v ) ) then
			copy[ i ] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[ t ] = copy
			if ( lookup_table[ v ] ) then
				copy[ i ] = lookup_table[ v ] -- we already copied this table. reuse the copy.
			else
				copy[ i ] = tableCopy( v, lookup_table ) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

/////////////////
--  net utils  --
/////////////////

NET = NET or tableCopy( net )

local function NiceTab(tablen,...)
    local args  = {...}
    local ret = ""
    tablen = tablen or 23
    
    for i=1,#args
    do
        local len  = utf8.len(utf8.force( tostring( args[i] ) ))
        ret = ret .. args[i] .. string.rep(" ",tablen-len) .. ( len >= tablen and " " or "" )
    end

    return ret
end

local NETUTILS   = {}
NETUTILS.SNIFFIN   = false
NETUTILS.SNIFFOUT   = false
NETUTILS.FREEZE   = false
NETUTILS.HOOK = {}

function net.ReadInt(bitCount)  local data = NET.ReadInt(bitCount)  if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "int"  .. bitCount .. ":","0x".. bit.tohex(data) , data    ) .. "\n" ) end return data end
function net.ReadUInt(bitCount) local data = NET.ReadUInt(bitCount) if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Uint" .. bitCount .. ":","0x" .. bit.tohex(data), data    ) .. "\n" ) end return data end
function net.ReadString()       local data = NET.ReadString()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "String:","\"".. data .. "\""                              ) .. "\n" ) end return data end
function net.ReadEntity()       local data = NET.ReadEntity()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Entity:", tostring( data )                                ) .. "\n" ) end return data end
function net.ReadVector()       local data = NET.ReadVector()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Vector:", tostring( data )                                ) .. "\n" ) end return data end
function net.ReadAngle()        local data = NET.ReadAngle()        if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Angle:" , data[1] .. " " .. data[2] .. " " .. data[3]     ) .. "\n" ) end return data end
function net.ReadTable()        local data = NET.ReadTable()        if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Table:" , table.ToString(data, "",false)                  ) .. "\n" ) end return data end
function net.ReadColor()        local data = NET.ReadColor()        if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Color:" , tostring( data )                                ) .. "\n" ) end return data end
function net.ReadFloat()        local data = NET.ReadFloat()        if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Float:" , data                                            ) .. "\n" ) end return data end
function net.ReadDouble()       local data = NET.ReadDouble()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Double:", data                                            ) .. "\n" ) end return data end
function net.ReadNormal()       local data = NET.ReadNormal()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Vector(Normal):",tostring( data )                         ) .. "\n" ) end return data end
function net.ReadMatrix()       local data = NET.ReadMatrix()       if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Matrix:"        ,tostring( data )                         ) .. "\n" ) end return data end
function net.ReadData(length)   local data = NET.ReadData(length)   if NETUTILS.SNIFFIN then NETUTILS.LOGOUTPUT:AppendText( NiceTab(23, "Binary Data:","<" .. length .. ">"                        ) .. "\n" ) end return data end

function net.WriteInt(num,bitCount)  if NETUTILS.FREEZE then return end  NET.WriteInt(num,bitCount)   if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "int"  .. bitCount .. ":","0x"..  bit.tohex(num), num      ) .. "\n" ) end end
function net.WriteUInt(num,bitCount) if NETUTILS.FREEZE then return end  NET.WriteUInt(num,bitCount)  if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Uint" .. bitCount .. ":","0x" .. bit.tohex(num), num      ) .. "\n" ) end end
function net.WriteString(string)     if NETUTILS.FREEZE then return end  NET.WriteString(string)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "String:","\"".. string .. "\""                            ) .. "\n" ) end end
function net.WriteEntity(entity)     if NETUTILS.FREEZE then return end  NET.WriteEntity(entity)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Entity:", tostring( entity )                              ) .. "\n" ) end end
function net.WriteVector(vector)     if NETUTILS.FREEZE then return end  NET.WriteVector(vector)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Vector:", tostring( vector )                              ) .. "\n" ) end end
function net.WriteAngle(angle)       if NETUTILS.FREEZE then return end  NET.WriteAngle(angle)        if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Angle:" , angle[1] .. " " .. angle[2] .. " " .. angle[3]  ) .. "\n" ) end end
function net.WriteTable(table)       if NETUTILS.FREEZE then return end  NET.WriteTable(table)        if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Table:" , table.ToString(table, "",false)                 ) .. "\n" ) end end
function net.WriteColor(color)       if NETUTILS.FREEZE then return end  NET.WriteColor(color)        if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Color:" , tostring( color )                               ) .. "\n" ) end end
function net.WriteFloat(float)       if NETUTILS.FREEZE then return end  NET.WriteFloat(float)        if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Float:" , float                                           ) .. "\n" ) end end
function net.WriteDouble(double)     if NETUTILS.FREEZE then return end  NET.WriteDouble(double)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Double:", double                                          ) .. "\n" ) end end
function net.WriteNormal(normal)     if NETUTILS.FREEZE then return end  NET.WriteNormal(normal)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Vector(Normal):",tostring( vector )                       ) .. "\n" ) end end
function net.WriteMatrix(matrix)     if NETUTILS.FREEZE then return end  NET.WriteMatrix(matrix)      if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Matrix:"        ,tostring( matrix )                       ) .. "\n" ) end end
function net.WriteData(data,length)  if NETUTILS.FREEZE then return end  NET.WriteData(data,length)   if NETUTILS.SNIFFOUT then  NETUTILS.LOGOUTPUT2:AppendText(NiceTab(23, "Binary Data:","<" .. length .. ">"                        ) .. "\n" ) end end

function net.Incoming( len )
	local i = net.ReadHeader()
	local strName = util.NetworkIDToString( i )
	if ( !strName ) then return end
	local func = net.Receivers[ strName:lower() ]
	if ( !func ) then return end
    len = len - 16
    
    if NETUTILS.HOOK[ strName ]
    then

        if NETUTILS.HOOK[ strName ] and NETUTILS.HOOK[ strName ][3] or false then return end
        
        NETUTILS.SNIFFIN = NETUTILS.HOOK[ strName ] and NETUTILS.HOOK[ strName ][2] or false

        if NETUTILS.SNIFFIN
        then
            NETUTILS.LOGOUTPUT = NETUTILS.HOOK[ strName ][1].netinlog
            NETUTILS.LOGOUTPUT:AppendText( "\n" ..  strName .. ":In\n" )
        end

    end
    
    func( len )

end

function net.Start(messageName, unreliable)
    local msgName = messageName:lower()

    net.Receivers[ msgName ] = net.Receivers[ msgName ] or msgName
    if NETUTILS.HOOK[ messageName ]
    then
        
        NETUTILS.FREEZE = NETUTILS.HOOK[ messageName ] and NETUTILS.HOOK[ messageName ][3] or false
        NETUTILS.SNIFFOUT   = NETUTILS.HOOK[ messageName ] and NETUTILS.HOOK[ messageName ][2] or false
        
        if NETUTILS.SNIFFOUT
        then
            NETUTILS.LOGOUTPUT2 = NETUTILS.HOOK[ messageName ][1].netoutlog
            NETUTILS.LOGOUTPUT2:AppendText( "\n" ..  messageName .. ":Out\n" )
        end
        if NETUTILS.FREEZE then return end

    end
    
    NET.Start(messageName, unreliable)
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
    local NEW_ENV = tableCopy( debug.getfenv( var ) )

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

local LuaSessionUID = 1

local function OpenFunctionSource(fn)
    local fninfo = debug.getinfo( fn )

    if fninfo.short_src == nil then return end

    local src_path    = string.sub( string.match(fninfo.short_src,"lua/.*lua" ) , 5 )
    local source = file.Read( src_path ,"LUA")
    if source == nil then error("") end
    
    if LUA_EDITOR_FRAME
    then
        LUA_EDITOR_FRAME:Show()
        LUA_EDITOR_FRAME:AddEditorTab(nil,string.GetFileFromFilename( src_path ))
        LUA_EDITOR_FRAME:GetActiveEditor():SetCode( source )
        LUA_EDITOR_FRAME:GetActiveEditor():GotoLine( fninfo.linedefined )
    else
        local frame = vgui.Create("LUAEDITOR")
        frame:GetActiveEditor():SetCode( source )
        frame:GetActiveEditor():GotoLine( fninfo.linedefined )
        frame:GetActiveEditorTab().CloseButton:Remove()
        frame:GetActiveEditorTab():SetText( string.GetFileFromFilename( src_path ) )
    end
end

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

-- don't let special characters break the js queue --
local function SafeJS( js )
    return js:gsub(".",replace)
end


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

vgui.Register("LUAEDITOR_Frame", PANEL , "DFrame")

local PANEL = {}
function PANEL:Init()
    self.BaseClass.Init(self)
    self.CloseButton = vgui.Create("LUAEDITOR_Button",self)
    self.CloseButton:Dock(RIGHT)
    self.CloseButton:SetText("X")
    self.CloseButton:SizeToContents()
    self.CloseButton.DoClick = function() 
        if #self:GetPropertySheet():GetItems() == 1 then LUA_EDITOR_FRAME:AddEditorTab() end
        self:GetPropertySheet():CloseTab(self,true) 
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

vgui.Register("LUAEDITOR_Tab", PANEL , "DTab")

local PANEL = {}

function PANEL:Init()
    self.tabScroller:SetOverlap(0)
end

function PANEL:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )
    if ( !IsValid( panel ) ) then
        ErrorNoHalt( "DPropertySheet:AddSheet tried to add invalid panel!" )
        debug.Trace()
        return
    end

    local Sheet = {}

    Sheet.Name = label

    Sheet.Tab = vgui.Create( "LUAEDITOR_Tab", self )
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

function PANEL:Paint()
end

vgui.Register("LUAEDITOR_PropertySheet", PANEL , "DPropertySheet")

local PANEL = {}
function PANEL:Init()
    self.Canvas = vgui.Create("DFrame",self)

    self.Canvas:Hide()

    self.Canvas:SetSizable(false)
    self.Canvas:SetDraggable(false)
    self.Canvas:SetTitle("")
    self.Canvas:ShowCloseButton(false)
    
    self.Canvas:SetTall( 0 )
    
    self.Canvas.OnFocusChanged = function(self,gained) if !gained and !vgui.FocusedHasParent( self ) then self:Hide() end end
    self.Canvas.Paint = function(_,w,h)
        surface.SetDrawColor(40,40,40)
        surface.DrawRect(0,0,w,h)
    end
    
    self.Offset = 0
end

function PANEL:OnRemove()
    self.Canvas:Remove()
end

function PANEL:DoClick()
    self.Canvas:SetVisible( !self.Canvas:IsVisible() )
    self.Canvas:SetPos( input.GetCursorPos() )
    self.Canvas:MakePopup()
    self.Canvas:RequestFocus()  
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

vgui.Register("LUAEDITOR_OptionsMenu",PANEL,"LUAEDITOR_Button")

local PANEL = {}

function PANEL:Init()
    local VBar = self:GetVBar()
    VBar.Paint = function() end
    function VBar.btnGrip:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))
    end

    VBar:SetHideButtons(true)

    self.hiddenCanvas = vgui.Create("DPanel",self)
    self.hiddenCanvas:Hide()
end

function PANEL:AddSearchBar()
    self.searchbar = vgui.Create("DTextEntry",self)
    self.searchbar:SetUpdateOnType(true)
    self.searchbar:SetPlaceholderText("Search...")

    self.searchbar.OnValueChange = function()
        local text = self.searchbar:GetValue()

        for _,panel in ipairs( table.Add( self.pnlCanvas:GetChildren() , self.hiddenCanvas:GetChildren() ) )
        do
            if panel == self.searchbar then continue end
            if string.find( panel.filterdata or "" , text )
            then
                panel:SetParent( self.pnlCanvas )
            else
                panel:SetParent( self.hiddenCanvas )
            end
        end
    end
end

function PANEL:PerformLayout(w,h)
    self:PerformLayoutInternal()
    if self.searchbar then self.searchbar:SetWide(w) end
end

vgui.Register("LUAEDITOR_ScrollPanel",PANEL,"DScrollPanel")

local PANEL = {}

function PANEL:Init()
    local w,h =  ScrW() * 0.7 , ScrH() * 0.7

    self:SetSizable( true )
    self:MakePopup()
    self:SetTitle("")
    
    self:SetSize( w,h )
    self:Center()

    
    self.btnClose.DoClick = function() self:Hide() end

    local toppanel = vgui.Create("DPanel")
    toppanel:SetDrawBackground(false)

    self.EditorTabsSheet = vgui.Create("LUAEDITOR_PropertySheet",toppanel )
    
    self.EditorTabsSheet:Dock(FILL)
    self.EditorTabsSheet:DockMargin(0,0,0,-15)

    local bottompanel = vgui.Create("DPanel")
    bottompanel:SetDrawBackground(false)
    
    self.Console = vgui.Create("RichText",bottompanel)
    self.Console:Dock(FILL)
    self.Console:DockMargin(6,0,8,3)
    self.Console.Paint = function(_,w,h)
        surface.SetDrawColor(12 , 125 , 157)
        surface.DrawRect(0,0,w,2)
    end
    local divider = vgui.Create("DVerticalDivider",self)
    
    divider:Dock(FILL)
    divider:DockMargin(-13,1,-13,0)
    
    divider:SetTop( toppanel )
    divider:SetBottom( bottompanel )

    divider:SetDividerHeight( 4 )
    divider:SetTopHeight( h - 200 )

    
    self:AddEditorTab()
end

    
function PANEL:GenerateOptions()

    local optionsHolder = vgui.Create("DPanel",self)
    optionsHolder:Dock(TOP)
    optionsHolder:DockMargin(-5,-10,100,-1)
    optionsHolder:SetDrawBackground(false)

    local FileOptions = vgui.Create("LUAEDITOR_OptionsMenu",optionsHolder)
    FileOptions:Dock(LEFT)
    FileOptions:SetText("File")
    FileOptions:AddOption("New File",function() 
        self:AddEditorTab()
        self:MakePopup()
    end)

    FileOptions:AddOption("Save As",function()
        local frame = vgui.Create("LUAEDITOR_Frame")
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

        local button = vgui.Create("LUAEDITOR_Button",frame)
        button:Dock(BOTTOM)
        button:SetText("Save")

        button.DoClick = function()  
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
        
        local frame = vgui.Create("LUAEDITOR_Frame")
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
            self:AddEditorTab( function( html ) html:SetCode( file.Read(path, "GAME") ) end, string.GetFileFromFilename( path ) )
            local panel = self:GetActiveEditorTab():GetPanel()
            panel.SaveTo =  string.Replace(path,"data/","")
            frame:Close()
        end
    end)

    FileOptions:AddOption("Load code from url",function() 
        local frame = vgui.Create("LUAEDITOR_Frame")
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

    local LuaOptions = vgui.Create("LUAEDITOR_OptionsMenu",optionsHolder)
    LuaOptions:Dock(LEFT)
    LuaOptions:SetText("LUA")    
    
    LuaOptions:AddOption("Deyvan's lua syntax tool",function()
        if !CHROMIUM_BRANCH then return Derma_Query("This only works on chromium branch!","Lua editor","Ok") end

        local frame = vgui.Create("LUAEDITOR_Frame")
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
        if !CHROMIUM_BRANCH then return Derma_Query("This only works on chromium branch!","Lua editor","Ok") end

        local frame = vgui.Create("LUAEDITOR_Frame")
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
        local frame = vgui.Create("LUAEDITOR_Frame")
        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.5)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        local scroll = vgui.Create("LUAEDITOR_ScrollPanel",frame)
        scroll:Dock(FILL)
        local function generate()
            scroll:Clear()
            for UID,Session in pairs( LUA_SESSIONS )
            do
                local cat = vgui.Create("DCollapsibleCategory",scroll)
                cat:Dock(TOP)
                cat:SetTall(150)
                cat:SetLabel( UID )
                local scroll = vgui.Create("LUAEDITOR_ScrollPanel",cat)
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

    LuaOptions:AddOption("net",function()
        local frame = vgui.Create("LUAEDITOR_Frame")
        frame:SetSize(ScrW() * 0.6 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)

        local netlist = vgui.Create("LUAEDITOR_ScrollPanel",frame)
        netlist:Dock(FILL)
        netlist:AddSearchBar()

        for netname,fn in SortedPairs( net.Receivers,true )
        do
            local panel = vgui.Create("DPanel",netlist)
            panel:SetDrawBackground(false)
            panel:Dock(TOP)
            panel:DockMargin(0,30,0,0)

            panel.filterdata = netname

            local label = vgui.Create("DTextEntry",panel)
            label:Dock(TOP)
            label:DockMargin(5,0,5,0)
            label:SetText(netname)

            local open = vgui.Create("DButton",panel)
            open:Dock(TOP)
            open:SetText("open source")
            open:DockMargin(5,0,5,0)

            open.DoClick = function()
                xpcall(function()
                    OpenFunctionSource(fn)
                end,function()
                     Derma_Query("Can't open the file","Lua editor","Ok")
                     open:SetDisabled(true) 
                end)
            end

            local sniff = vgui.Create("DButton",panel)
            sniff:Dock(TOP)
            sniff:SetText("sniff")
            sniff:DockMargin(5,0,5,10)
            sniff.DoClick = function()
                if NETUTILS.HOOK[ netname ] and NETUTILS.HOOK[ netname ][2]
                then
                    NETUTILS.HOOK[ netname ][1]:Show()
                    NETUTILS.HOOK[ netname ][1]:MakePopup()
                else
                    local frame = vgui.Create("LUAEDITOR_Frame")

                    frame:SetTitle("")
                    frame:Center()
                    frame:MakePopup()
                    frame:SetSizable(true)

                    frame:SetSize(ScrW() * 0.4,ScrH() *0.6)
                    frame.btnClose.DoClick = function() frame:Hide() end
 
                    local enabled = vgui.Create("DCheckBoxLabel",frame)
                    enabled:SetPos(10,10)
                    enabled:SetText("Sniff " .. netname )
                    enabled:SetValue(true)

                    enabled.OnChange = function(_,val) 
                        NETUTILS.HOOK[ netname ][2] = val
                    end

                    local freeze = vgui.Create("DCheckBoxLabel",frame)
                    freeze:SetPos(10,30)
                    freeze:SetText("Freeze sending/receiving " .. netname )

                    freeze.OnChange = function(_,val) 
                        NETUTILS.HOOK[ netname ][3] = val
                    end

                    frame.netinlog = vgui.Create("RichText",frame)
                    frame.netinlog:Dock(LEFT)  
                    frame.netinlog:DockMargin(0,20,0,0)
                    
                    frame.netoutlog = vgui.Create("RichText",frame)
                    frame.netoutlog:Dock(RIGHT)
                    frame.netoutlog:DockMargin(0,20,0,0)

                    local _PerformLayout = frame.PerformLayout
                    function frame:PerformLayout(w,h)
                        _PerformLayout(self,w,h)
                        frame.netinlog:SetWide( w/2 - 10 )
                        frame.netoutlog:SetWide( w/2 - 10 )
                    end

                    NETUTILS.HOOK[ netname ]    = {} 
                    NETUTILS.HOOK[ netname ][1] = frame
                    NETUTILS.HOOK[ netname ][2] = true
                    NETUTILS.HOOK[ netname ][3] = false
                end
            end

            panel:SetTall(70)

        end
    end)

    LuaOptions:AddOption("hook",function()
        local frame = vgui.Create("LUAEDITOR_Frame")

        frame:SetSize(ScrW() * 0.5 , ScrH() * 0.7)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        frame:SetSizable(true)

        local scroll = vgui.Create("LUAEDITOR_ScrollPanel",frame)
        scroll:Dock(FILL)
        scroll:AddSearchBar()

        local hooks = hook.GetTable()
        for eventname,tbl in pairs(hooks)
        do
            for id,fn in pairs(tbl)
            do
                local fninfo = debug.getinfo(fn) 

                local panel = vgui.Create("DPanel",scroll)
                panel:SetDrawBackground(false)
                panel:Dock(TOP)
                panel:DockMargin(0,30,0,0)
                
                panel.filterdata = eventname .. " " .. tostring( id )
                
                local label = vgui.Create("DTextEntry",panel)
                label:Dock(TOP)
                label:DockMargin(5,0,5,0)
                label:SetText( eventname .. " " .. tostring( id ) )

                local open = vgui.Create("DButton",panel)
                open:Dock(TOP)
                open:SetText("open source")
                open:DockMargin(5,0,5,0)
    
                open.DoClick = function()
                    xpcall(function()
                        OpenFunctionSource(fn)
                    end,function()
                         Derma_Query("Can't open the file","Lua editor","Ok")
                         open:SetDisabled(true) 
                    end)
                end

                local terminate = vgui.Create("DButton",panel)
                terminate:Dock(TOP)
                terminate:DockMargin(5,0,5,20)
                terminate:SetText("Terminate hook")
                terminate.DoClick = function() hook.Remove( eventname,id ) label:Remove() terminate:Remove() end

                panel:SetTall(70)
            end
        end
    end)

    -- I really don't know why i added this but why not
    local Rextester = vgui.Create("LUAEDITOR_Button",optionsHolder)
    Rextester:Dock(RIGHT)
    Rextester:SetText("rextester")

    Rextester.DoClick = function()
        local frame = vgui.Create("LUAEDITOR_Frame")
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

    local ColorPicker = vgui.Create("LUAEDITOR_OptionsMenu",optionsHolder)
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
            panel.HTML:GotoLine( line )
        end
        LUA_EDITOR_PRINT( var ) 
    end
end

function PANEL:AddEditorTab(OnReadyCallback,UID)
    local panel = vgui.Create("DPanel")
    panel:SetDrawBackground(false)
    panel:Dock(FILL)
    panel:DockMargin(0,0,0,0)

    local ErrorIndicator = vgui.Create("LUAEDITOR_Button",panel)
    ErrorIndicator:Dock(TOP)
    ErrorIndicator.DoClick = function()
        if ErrorIndicator.errLine == nil then return end
        panel.HTML:GotoLine( ErrorIndicator.errLine )
    end

    
    local HTML = vgui.Create("DHTML",panel)
    panel.HTML = HTML
    
    panel.UID = UID or ( "Lua session #" .. LuaSessionUID )
    if !UID then LuaSessionUID = LuaSessionUID + 1 end

    HTML:Dock(FILL)
    HTML:DockMargin(0,0,10,15)
    HTML:SetAlpha(0)

    HTML:AddFunction("gmodinterface","OnCode", function(Code)
        HTML.Code = Code

        if Code != "" then
            local var = Compile( Code )
            if isstring( var ) 
            then 
                local line,err = string.match(var,":(%d*):(.+)")
                HTML:SetError( line , err )
                return
            end
        end
        HTML:ClearError()
    end)         
    
    function HTML:GetCode()
        return self.Code or ""
    end

    function HTML:GotoLine(num)
        self:QueueJavascript( ( CHROMIUM_BRANCH and "gmodinterface." or "" ) .. "GotoLine(" .. num .. ")")
    end

    function HTML:SetCode( Code )
        self:QueueJavascript( CHROMIUM_BRANCH  and "gmodinterface.SetCode('" ..  SafeJS( Code ) .. "');" or "SetContent('" ..  SafeJS( Code ) .. "');" ) 
    end    
    
    function HTML:SetError( line ,err )
        ErrorIndicator:SetMouseInputEnabled(true)
        ErrorIndicator:SetText( err .. " :" .. line )
        ErrorIndicator.errLine = line
    end
    
    function HTML:ClearError()
        ErrorIndicator:SetText("")
        ErrorIndicator.errLine = nil
        ErrorIndicator:SetMouseInputEnabled(false)
    end

    HTML:ClearError()

    local loadingpanel = vgui.Create("LUAEDITOR_LoadingPanel",panel)
    loadingpanel:Dock(FILL)

    HTML:QueueJavascript("document.documentElement.style.overflow-y = 'hidden';")
    HTML:AddFunction("gmodinterface","OnThemesLoaded", function()end)    
    HTML:AddFunction("gmodinterface","OnLanguages", function()end)

    HTML:AddFunction("gmodinterface","OnReady", function()
        if OnReadyCallback then OnReadyCallback(HTML) end

        xpcall(function()

                HTML:SetAlpha(255)
                loadingpanel:AlphaTo(0,0.2,0,function() 

                    loadingpanel:Remove() 
                    HTML:RequestFocus()
                end)

        end,function() end)

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
    if input.IsKeyDown( KEY_LCONTROL ) and input.IsKeyDown( KEY_S )
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

vgui.Register("LUAEDITOR",PANEL,"LUAEDITOR_Frame")

concommand.Add("lua_editor",function()
    if LUA_EDITOR_FRAME then return LUA_EDITOR_FRAME:Show() end
    LUA_EDITOR_FRAME = vgui.Create("LUAEDITOR")
    LUA_EDITOR_FRAME:GenerateOptions()
end)
