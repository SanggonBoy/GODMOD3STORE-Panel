local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local UserInputService=game:GetService("UserInputService")
local lp=Players.LocalPlayer if not lp then return end

local API_LOGIN=(getgenv and getgenv().GM_API_LOGIN) or "https://zgmkifwoucfuqmiobcbo.supabase.co/functions/v1/login"
local API_VALIDATE=(getgenv and getgenv().GM_API_VALIDATE) or "https://zgmkifwoucfuqmiobcbo.supabase.co/functions/v1/validate"
local HTTP=(syn and syn.request) or request or http_request
if not HTTP then error("[GM] executor tidak punya HTTP request") end

local token=nil
local cheats={}
local labelText=nil
local isVIP=false

local SES_DIR='GODMOD3STORE/session'
local SES_OK=(type(writefile)=='function' and type(readfile)=='function')
local function sesPath()
	return SES_DIR..'/'..tostring(lp.UserId)..'.json'
end
local function saveSession(k)
	if getgenv then pcall(function() getgenv().GM_SAVED_KEY=k end) end
	if not SES_OK or type(k)~='string' or #k<32 then return end
	pcall(function()
		if makefolder then pcall(makefolder,SES_DIR) end
		writefile(sesPath(),HttpService:JSONEncode({k=k,uid=lp.UserId}))
	end)
end
local function loadSession()
	local g=getgenv and getgenv()
	if g and type(g.GM_SAVED_KEY)=='string' and #g.GM_SAVED_KEY>=32 then return g.GM_SAVED_KEY end
	if not SES_OK then return nil end
	local ok,v=pcall(function()
		if isfile and not isfile(sesPath()) then return nil end
		return HttpService:JSONDecode(readfile(sesPath()))
	end)
	if ok and type(v)=='table' and type(v.k)=='string' and #v.k>=32 then return v.k end
	return nil
end
local function clearSession()
	if getgenv then pcall(function() getgenv().GM_SAVED_KEY=nil end) end
	if not SES_OK then return end
	pcall(function() if delfile and isfile and isfile(sesPath()) then delfile(sesPath()) end end)
end

local pg=lp:WaitForChild("PlayerGui")
do
	local scan={pg}
	pcall(function() local h=gethui and gethui(); if h then scan[#scan+1]=h end end)
	pcall(function() if game.CoreGui then scan[#scan+1]=game.CoreGui end end)
	for _,container in ipairs(scan) do
		local old=container:FindFirstChild("GODMOD3STORE_UI")
		if old then old:Destroy() end
	end
end

local gui=Instance.new("ScreenGui")
gui.Name="GODMOD3STORE_UI"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=2000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local parent=nil
pcall(function() parent=(gethui and gethui()) or game.CoreGui end)
if not (parent and pcall(function() gui.Parent=parent end)) then gui.Parent=pg end

local T={
	BG=Color3.fromRGB(10,11,18),
	PANEL=Color3.fromRGB(17,19,29),
	CARD=Color3.fromRGB(23,26,40),
	SIDEBAR=Color3.fromRGB(14,16,25),
	GRAD_A=Color3.fromRGB(0,220,255),
	GRAD_B=Color3.fromRGB(170,80,255),
	TXT=Color3.fromRGB(235,238,248),
	DIM=Color3.fromRGB(150,158,180),
	ACC=Color3.fromRGB(160,120,255),
	OFF=Color3.fromRGB(120,128,150),
	HEAD_H=48,
}

local function mk(cls,props,par)
	local o=Instance.new(cls)
	if props then for k,v in pairs(props) do o[k]=v end end
	if par then o.Parent=par end
	return o
end

local function cr(o,r)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,r or 12)
	c.Parent=o
	return c
end

local function grad(p,rot)
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,T.GRAD_A),
		ColorSequenceKeypoint.new(1,T.GRAD_B)
	}
	g.Rotation=rot and 90 or 0
	g.Parent=p
	return g
end

local function gradText(lbl)
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(0.45,T.GRAD_A),
		ColorSequenceKeypoint.new(1,T.GRAD_B)
	}
	g.Parent=lbl
	return g
end

local LOGO_ASSET='rbxassetid://0'
local LOGO_FLOAT_URL='https://i.ibb.co.com/gX72Vs7/Whats-App-Image-2026-10-02-at-00-23-28.jpg'
local LOGO_FLOAT_FILE='GODMOD3_float.jpg'

local function resolveLogo()
	if type(LOGO_ASSET)=='string' and LOGO_ASSET~='rbxassetid://0' then return LOGO_ASSET end
	local env=getgenv and getgenv().GM_CACHED_LOGO
	if type(env)=='string' and env~='' then return env end
	local req=(syn and syn.request) or request or http_request
	if type(req)~='function' then return nil end
	local ok=pcall(function()
		if not (isfile and isfile(LOGO_FLOAT_FILE)) then
			local res=req({Url=LOGO_FLOAT_URL,Method='GET'})
			if not res or res.StatusCode~=200 or not res.Body then return end
			if writefile then writefile(LOGO_FLOAT_FILE,res.Body) end
		end
	end)
	if not ok then return nil end
	local okG,gca=pcall(function() return getcustomasset(LOGO_FLOAT_FILE) end)
	if not okG or type(gca)~='string' or gca=='' then return nil end
	if getgenv then getgenv().GM_CACHED_LOGO=gca end
	return gca
end

local cachedLogo=resolveLogo()

local root=mk("Frame",{
	Name="GM_ROOT",
	Size=UDim2.new(1,0,1,0),
	BackgroundTransparency=1,
	BorderSizePixel=0,
},gui)

local W,H=500,370
local main=mk("Frame",{
	Name="Main",
	AnchorPoint=Vector2.new(0.5,0.5),
	Size=UDim2.new(0,W,0,H),
	Position=UDim2.new(0.5,0,0.5,0),
	BackgroundColor3=T.PANEL,
	BorderSizePixel=0,
	Active=true,
},root)
cr(main,16)
local mainStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=0},main)
grad(mainStroke)

local uiScale=mk("UIScale",{},main)
local function applyScale()
	local cam=workspace.CurrentCamera
	if not cam then return end
	local vp=cam.ViewportSize
	local f=math.min((vp.X-32)/W,(vp.Y-32)/H)
	uiScale.Scale=math.clamp(f,0.75,1.05)
end
applyScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
end

local wm=mk("TextLabel",{
	Size=UDim2.new(0,250,0,16),
	Position=UDim2.new(1,-260,1,-22),
	BackgroundTransparency=1,
	Text="by Alexander Jay · @absrdme",
	Font=Enum.Font.Gotham,
	TextSize=11,
	TextColor3=T.DIM,
	TextTransparency=0.35,
	TextXAlignment=Enum.TextXAlignment.Right,
	Active=false,
	ZIndex=1,
},root)

local errLbl=mk("TextLabel",{
	AnchorPoint=Vector2.new(0.5,0),
	Size=UDim2.new(0.9,0,0,38),
	Position=UDim2.new(0.5,0,0,T.HEAD_H+6),
	BackgroundColor3=Color3.fromRGB(60,16,20),
	BackgroundTransparency=0.1,
	BorderSizePixel=0,
	Text="",
	TextWrapped=true,
	Font=Enum.Font.Code,
	TextSize=11,
	TextColor3=Color3.fromRGB(255,160,160),
	Visible=false,
	ZIndex=60,
},main)
cr(errLbl,8)

local function showErr(msg)
	pcall(function() errLbl.Text="[GM] "..tostring(msg); errLbl.Visible=true end)
	warn("[GM] "..tostring(msg))
end

local tb=mk("Frame",{
	Size=UDim2.new(1,0,0,T.HEAD_H),
	BackgroundColor3=T.CARD,
	BorderSizePixel=0,
},main)
cr(tb,16)
mk("UICorner",{CornerRadius=UDim.new(0,6)},tb)

local hdrLogo=mk("ImageLabel",{
	Position=UDim2.new(0,14,0.5,-13),
	Size=UDim2.new(0,26,0,26),
	BackgroundTransparency=1,
	Image=cachedLogo or "",
	ScaleType=Enum.ScaleType.Crop,
	Active=false,
	ZIndex=3,
},tb)
cr(hdrLogo,13)

local t1=mk("TextLabel",{
	BackgroundTransparency=1,
	Position=UDim2.new(0,48,0,0),
	Size=UDim2.new(0,110,1,0),
	Text="GODMOD3",
	Font=Enum.Font.GothamBold,
	TextSize=17,
	TextColor3=Color3.fromRGB(255,255,255),
	TextXAlignment=Enum.TextXAlignment.Left,
	TextTruncate=Enum.TextTruncate.AtEnd,
	ZIndex=3,
},tb)
gradText(t1)

local t2=mk("TextLabel",{
	BackgroundTransparency=1,
	Position=UDim2.new(0,158,0,0),
	Size=UDim2.new(1,-250,1,0),
	Text="- DASHBOARD",
	Font=Enum.Font.Gotham,
	TextSize=13,
	TextColor3=T.DIM,
	TextXAlignment=Enum.TextXAlignment.Left,
	TextTruncate=Enum.TextTruncate.AtEnd,
	ZIndex=3,
},tb)

local bX=mk("TextButton",{
	Position=UDim2.new(1,-74,0.5,-13),
	Size=UDim2.new(0,26,0,26),
	Text="✕",
	Font=Enum.Font.GothamBold,
	TextSize=13,
	TextColor3=T.TXT,
	BackgroundColor3=T.BG,
	BorderSizePixel=0,
	AutoButtonColor=false,
	ZIndex=3,
},tb)
cr(bX,8)

local bMin=mk("TextButton",{
	Position=UDim2.new(1,-40,0.5,-13),
	Size=UDim2.new(0,26,0,26),
	Text="–",
	Font=Enum.Font.GothamBold,
	TextSize=15,
	TextColor3=T.TXT,
	BackgroundColor3=T.BG,
	BorderSizePixel=0,
	AutoButtonColor=false,
	ZIndex=3,
},tb)
cr(bMin,8)

local float=mk("TextButton",{
	Text="",
	Font=Enum.Font.GothamBold,
	TextSize=16,
	TextColor3=T.TXT,
	Size=UDim2.new(0,58,0,58),
	Position=UDim2.new(0,22,1,-80),
	BackgroundColor3=T.CARD,
	BorderSizePixel=0,
	Active=true,
	AutoButtonColor=false,
	ZIndex=100,
},gui)
cr(float,29)
local floatStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=0.15},float)
grad(floatStroke)

local floatImg=mk("ImageLabel",{
	BackgroundTransparency=1,
	Size=UDim2.new(1,-6,1,-6),
	Position=UDim2.new(0,3,0,3),
	Image=cachedLogo or "",
	ScaleType=Enum.ScaleType.Crop,
	Active=false,
	ZIndex=101,
},float)
cr(floatImg,26)

if not cachedLogo then
	float.Text="G3"
	task.spawn(function()
		for _=1,5 do
			task.wait(2.5)
			local l=resolveLogo()
			if l then
				cachedLogo=l
				hdrLogo.Image=l
				floatImg.Image=l
				float.Text=""
				break
			end
		end
	end)
end

local function toggleGui()
	main.Visible=not main.Visible
	wm.Visible=main.Visible
end

bX.MouseButton1Click:Connect(function() main.Visible=false wm.Visible=false end)
bMin.MouseButton1Click:Connect(function() main.Visible=false wm.Visible=false end)

do
	local dg,sp,si,mvd=false,nil,nil,0
	float.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then
			dg=true; mvd=0; sp=float.Position; si=io.Position
		end
	end)
	float.InputEnded:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dg=false end
	end)
	UserInputService.InputChanged:Connect(function(io)
		if dg and sp and si and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then
			local d=io.Position-si
			mvd=mvd+math.abs(d.X)+math.abs(d.Y)
			float.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	float.MouseButton1Click:Connect(function()
		if mvd<8 then toggleGui() end
	end)
end

do
	local dg,sp,si=false,nil,nil
	tb.InputBegan:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then
			dg=true; sp=main.Position; si=io.Position
		end
	end)
	tb.InputEnded:Connect(function(io)
		if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dg=false end
	end)
	UserInputService.InputChanged:Connect(function(io)
		if dg and sp and si and (io.UserInputType==Enum.UserInputType.MouseMovement or io.UserInputType==Enum.UserInputType.Touch) then
			local d=io.Position-si
			main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end

local toastLbl=mk("TextLabel",{
	AnchorPoint=Vector2.new(0.5,0),
	Size=UDim2.new(0.9,0,0,28),
	Position=UDim2.new(0.5,0,0,T.HEAD_H+8),
	BackgroundColor3=Color3.fromRGB(24,24,36),
	BackgroundTransparency=0.08,
	BorderSizePixel=0,
	Text="",
	Font=Enum.Font.Gotham,
	TextSize=12,
	TextColor3=T.TXT,
	Visible=false,
	ZIndex=80,
},root)
cr(toastLbl,10)
local toastStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.2,Transparency=0.4},toastLbl)
grad(toastStroke)

local function toast(t,err)
	toastLbl.Text=t
	toastLbl.TextColor3=err and Color3.fromRGB(255,135,135) or T.TXT
	toastLbl.Visible=true
	task.delay(2.6,function() if toastLbl.Text==t then toastLbl.Visible=false end end)
end

local function postJson(url,body)
	local s=HttpService:JSONEncode(body)
	local ok,r=pcall(function() return HTTP({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=s}) end)
	if not ok then warn("[GM] HTTP gagal: "..tostring(r)); return nil,nil end
	local j=nil; pcall(function() j=HttpService:JSONDecode(r and r.Body or "") end)
	return r and tonumber(r.StatusCode), j
end

local vLogin=mk("Frame",{
	Size=UDim2.new(1,0,1,-T.HEAD_H),
	Position=UDim2.new(0,0,0,T.HEAD_H),
	BackgroundTransparency=1,
	Visible=true,
},main)

local vDash=mk("Frame",{
	Size=UDim2.new(1,0,1,-T.HEAD_H),
	Position=UDim2.new(0,0,0,T.HEAD_H),
	BackgroundTransparency=1,
	Visible=false,
},main)

local function show(d)
	vLogin.Visible=(d=="login")
	vDash.Visible=(d=="dash")
end

local lCard=mk("Frame",{
	AnchorPoint=Vector2.new(0.5,0.5),
	Size=UDim2.new(0,390,0,210),
	Position=UDim2.new(0.5,0,0.5,0),
	BackgroundColor3=T.CARD,
	BorderSizePixel=0,
},vLogin)
cr(lCard,14)
local lCardStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.2,Transparency=0.4},lCard)
grad(lCardStroke)

local lTitle=mk("TextLabel",{
	Size=UDim2.new(1,0,0,22),
	Position=UDim2.new(0,0,0,16),
	BackgroundTransparency=1,
	Text="Masukkan Key Lisensi",
	Font=Enum.Font.GothamBold,
	TextSize=15,
	TextColor3=Color3.fromRGB(255,255,255),
},lCard)
gradText(lTitle)

local box=mk("TextBox",{
	Size=UDim2.new(1,-24,0,42),
	Position=UDim2.new(0,12,0,80),
	BackgroundColor3=T.BG,
	Text="",
	PlaceholderText="GODMOD3-xxxxxxxxxxxxxxxx…",
	Font=Enum.Font.Code,
	TextSize=12,
	TextColor3=T.TXT,
	PlaceholderColor3=Color3.fromRGB(110,118,140),
	ClearTextOnFocus=false,
	BorderSizePixel=0,
},lCard)
cr(box,10)
local boxStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.2,Transparency=0.35},box)
grad(boxStroke)
local lPad=Instance.new("UIPadding")
lPad.PaddingLeft=UDim.new(0,12)
lPad.PaddingRight=UDim.new(0,12)
lPad.Parent=box

local btn=mk("TextButton",{
	Size=UDim2.new(1,-24,0,40),
	Position=UDim2.new(0,12,1,-52),
	BackgroundColor3=Color3.fromRGB(255,255,255),
	AutoButtonColor=false,
	Text="",
	BorderSizePixel=0,
},lCard)
cr(btn,10)
grad(btn)

local btnLbl=mk("TextLabel",{
	Size=UDim2.new(1,0,1,0),
	BackgroundTransparency=1,
	Text="MASUK  →",
	Font=Enum.Font.GothamBold,
	TextSize=13,
	TextColor3=Color3.fromRGB(255,255,255),
	ZIndex=2,
},btn)

local pRow=mk("Frame",{
	Size=UDim2.new(1,-24,0,62),
	Position=UDim2.new(0,12,0,10),
	BackgroundColor3=T.CARD,
	BorderSizePixel=0,
},vDash)
cr(pRow,12)
local pRowStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=0.5},pRow)
grad(pRowStroke)

local thumb=mk("ImageLabel",{
	Size=UDim2.new(0,46,0,46),
	Position=UDim2.new(0,8,0.5,-23),
	BackgroundColor3=T.BG,
	BorderSizePixel=0,
	Image="",
},pRow)
cr(thumb,23)

mk("TextLabel",{
	Size=UDim2.new(0.9,0,0,18),
	Position=UDim2.new(0,62,0,10),
	BackgroundTransparency=1,
	Text=lp.DisplayName.."  (@"..lp.Name..")",
	Font=Enum.Font.GothamBold,
	TextSize=13,
	TextColor3=T.TXT,
	TextXAlignment=Enum.TextXAlignment.Left,
},pRow)

mk("TextLabel",{
	Size=UDim2.new(0.9,0,0,14),
	Position=UDim2.new(0,62,0,29),
	BackgroundTransparency=1,
	Text="UserId: "..tostring(lp.UserId),
	Font=Enum.Font.Code,
	TextSize=11,
	TextColor3=T.DIM,
	TextXAlignment=Enum.TextXAlignment.Left,
},pRow)

local badge=mk("TextLabel",{
	Size=UDim2.new(0,54,0,18),
	Position=UDim2.new(1,-64,0,8),
	BackgroundColor3=Color3.fromRGB(90,90,115),
	Text="FREE",
	Font=Enum.Font.GothamBold,
	TextSize=11,
	TextColor3=Color3.fromRGB(255,255,255),
	BorderSizePixel=0,
},pRow)
cr(badge,8)

local keyLbl=mk("TextLabel",{
	Size=UDim2.new(0,180,0,14),
	Position=UDim2.new(1,-190,1,-20),
	BackgroundTransparency=1,
	Text="",
	Font=Enum.Font.Code,
	TextSize=10,
	TextColor3=T.DIM,
	TextXAlignment=Enum.TextXAlignment.Right,
},pRow)

local cheatTitle=mk("TextLabel",{
	Size=UDim2.new(1,-24,0,16),
	Position=UDim2.new(0,14,0,78),
	BackgroundTransparency=1,
	Text="Cheat yang kamu miliki",
	Font=Enum.Font.GothamBold,
	TextSize=12,
	TextColor3=Color3.fromRGB(255,255,255),
	TextXAlignment=Enum.TextXAlignment.Left,
},vDash)
gradText(cheatTitle)

local sc=mk("ScrollingFrame",{
	Size=UDim2.new(1,-24,1,-170),
	Position=UDim2.new(0,12,0,98),
	BackgroundTransparency=1,
	BorderSizePixel=0,
	CanvasSize=UDim2.new(0,0,0,0),
	ScrollBarThickness=4,
	ScrollBarImageColor3=T.GRAD_B,
},vDash)
local lay=mk("UIListLayout",{Padding=UDim.new(0,8),Parent=sc})
local emptyLbl=mk("TextLabel",{
	Size=UDim2.new(1,0,0,40),
	BackgroundTransparency=1,
	Text="Belum ada cheat yang diberikan.\nHubungi admin untuk aktivasi.",
	Font=Enum.Font.Gotham,
	TextSize=12,
	TextColor3=T.DIM,
	TextWrapped=true,
	Visible=false,
},sc)

local bottom=mk("Frame",{
	Size=UDim2.new(1,-24,0,32),
	Position=UDim2.new(0,12,1,-42),
	BackgroundTransparency=1,
},vDash)

local outBtn=mk("TextButton",{
	Size=UDim2.new(0,90,1,0),
	Position=UDim2.new(1,-90,0,0),
	Text="Keluar",
	Font=Enum.Font.GothamBold,
	TextSize=12,
	TextColor3=T.DIM,
	BackgroundColor3=T.CARD,
	BorderSizePixel=0,
	AutoButtonColor=false,
},bottom)
cr(outBtn,10)
local outStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=0.6},outBtn)
grad(outStroke)

local function paintBadge()
	if isVIP then
		badge.Text="VIP"
		badge.BackgroundColor3=Color3.fromRGB(240,190,50)
		badge.TextColor3=Color3.fromRGB(24,18,6)
	else
		badge.Text="FREE"
		badge.BackgroundColor3=Color3.fromRGB(80,85,110)
		badge.TextColor3=Color3.fromRGB(255,255,255)
	end
	if labelText and #labelText>0 then keyLbl.Text=labelText end
end

local running=false
local function loadThumb()
	pcall(function()
		local u="https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..tostring(lp.UserId).."&size=150x150&format=Png&isCircular=true"
		local r=HTTP({Url=u,Method="GET"})
		if not r or r.StatusCode~=200 then return end
		local j=nil; pcall(function() j=HttpService:JSONDecode(r.Body) end)
		local url=j and j.data and j.data[1] and j.data[1].imageUrl
		if url then thumb.Image=url end
	end)
end

local function renderCheats()
	for _,c in ipairs(sc:GetChildren()) do
		if c:IsA("Frame") and c.Name=="GM_ROW" then c:Destroy() end
	end
	if #cheats==0 then
		emptyLbl.Visible=true
		sc.CanvasSize=UDim2.new(0,0,0,50)
		return
	end
	emptyLbl.Visible=false
	for _,ch in ipairs(cheats) do
		local row=mk("Frame",{
			Name="GM_ROW",
			Size=UDim2.new(1,-4,0,58),
			BackgroundColor3=T.CARD,
			BorderSizePixel=0,
		},sc)
		cr(row,12)
		local rowStroke=mk("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=0.55},row)
		grad(rowStroke)

		mk("TextLabel",{
			Name="t",
			Text=ch.title or ch.id,
			Font=Enum.Font.GothamBold,
			TextSize=13,
			BackgroundTransparency=1,
			Size=UDim2.new(0.66,0,0,18),
			Position=UDim2.new(0,14,0,8),
			TextColor3=T.TXT,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},row)

		mk("TextLabel",{
			Name="d",
			Text=(ch.description and #ch.description>0) and ch.description or "",
			Font=Enum.Font.Gotham,
			TextSize=11,
			BackgroundTransparency=1,
			Size=UDim2.new(0.66,0,0,26),
			Position=UDim2.new(0,14,0,27),
			TextColor3=T.DIM,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextWrapped=true,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},row)

		local go=mk("TextButton",{
			Size=UDim2.new(0,92,0,32),
			Position=UDim2.new(1,-100,0.5,-16),
			BackgroundColor3=Color3.fromRGB(255,255,255),
			AutoButtonColor=false,
			Text="",
			BorderSizePixel=0,
		},row)
		cr(go,10)
		grad(go)

		local goLbl=mk("TextLabel",{
			Size=UDim2.new(1,0,1,0),
			BackgroundTransparency=1,
			Text="EKSEKUSI  ▶",
			Font=Enum.Font.GothamBold,
			TextSize=11,
			TextColor3=Color3.fromRGB(255,255,255),
			ZIndex=2,
		},go)

		go.MouseButton1Click:Connect(function()
			if running then toast("Sedang menjalankan…"); return end
			local cur=token
			if not cur or #cur~=64 then
				toast("Sesi habis. Login ulang.",true)
				show("login")
				return
			end
			running=true
			goLbl.Text="…"
			task.spawn(function()
				local code,data=postJson(API_VALIDATE,{t=cur,c=ch.id})
				if code~=200 or not (data and data.ok and data.payload and #data.payload>0) then
					running=false
					goLbl.Text="EKSEKUSI  ▶"
					local msg=(data and data.reason) or ("HTTP "..tostring(code))
					if msg:find("Sesi") or msg:find("berakhir") then
						token=nil; cheats={}; show("login")
					end
					toast("Gagal: "..tostring(msg),true)
					return
				end
				local p=(ch and ch.id) or "?"
				running=false
				if getgenv then
					getgenv().GM_TOKEN=cur
					getgenv().GM_API_VALIDATE=API_VALIDATE
				end
				pcall(function() toastLbl.Visible=false end)
				pcall(function() gui:Destroy() end)
				local ok,err=pcall(function() loadstring(data.payload)() end)
				if not ok then warn("[GM] loadstring cheat "..p.." gagal: "..tostring(err)) end
			end)
		end)
	end
	local _,y=pcall(function() return lay.AbsoluteContentSize.Y end)
	sc.CanvasSize=UDim2.new(0,0,0,math.max(50,tonumber(y) or 0))
end

local function doLogin(forceKey)
	local key
	if type(forceKey)=='string' then
		key=forceKey
	else
		key=box.Text:gsub("^%s+",""):gsub("%s+$","")
	end
	if #key<32 then toast("Key minimal 32 karakter.",true); return end
	btnLbl.Text="…"
	local code,data=postJson(API_LOGIN,{k=key,u=lp.UserId})
	btnLbl.Text="MASUK  →"
	if code~=200 or not (data and data.ok and data.token) then
		local msg=(data and data.reason) or ("HTTP "..tostring(code))
		if msg=="Key tidak valid" or msg=="Key expired" or msg=="Key terikat ke akun lain" then
			clearSession()
		end
		toast("Gagal: "..tostring(msg),true)
		return
	end
	saveSession(key)
	token=data.token
	labelText=data.label
	isVIP=(data.vip==true)
	cheats=(type(data.cheats)=="table") and data.cheats or {}
	if type(labelText)~="string" then labelText="" end
	loadThumb()
	local ok,err=pcall(function() paintBadge(); renderCheats() end)
	if not ok then showErr("renderCheats: "..tostring(err)); return end
	show("dash")
	toast("Login berhasil  ·  "..(isVIP and "VIP" or "FREE")..(labelText~="" and ("  ·  "..labelText) or ""))
	pcall(function() box.Text="" end)
end

btn.MouseButton1Click:Connect(function()
	local ok,err=pcall(doLogin)
	if not ok then toast("Login gagal: "..tostring(err),true); showErr("doLogin: "..tostring(err)) end
end)
box.FocusLost:Connect(function(enter)
	if enter then
		local ok,err=pcall(doLogin)
		if not ok then toast("Login gagal: "..tostring(err),true); showErr("doLogin: "..tostring(err)) end
	end
end)
outBtn.MouseButton1Click:Connect(function()
	token=nil; cheats={}; labelText=nil; isVIP=false
	clearSession()
	box.Text=""
	show("login")
	toast("Sesi ditutup & key dihapus.")
end)

task.spawn(function()
	while gui and gui.Parent do
		task.wait(1)
		if not gui.Parent then
			pcall(function() gui.Parent=(gethui and gethui()) or pg end)
		end
	end
end)

show("login")
do
	local saved=loadSession()
	if saved then
		box.Text=saved
		task.spawn(function()
			local ok,err=pcall(doLogin,saved)
			if not ok then toast("Login gagal: "..tostring(err),true); showErr("auto-login: "..tostring(err)) end
		end)
	end
end
print("[GM] GODMOD3STORE dashboard v3 loaded (by Alexander Jay @absrdme) — masukkan key lalu pilih cheat.")
