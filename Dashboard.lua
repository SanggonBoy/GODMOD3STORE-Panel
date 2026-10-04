local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
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
gui.DisplayOrder=999
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local parent=nil
pcall(function() parent=(gethui and gethui()) or game.CoreGui end)
if not (parent and pcall(function() gui.Parent=parent end)) then gui.Parent=pg end

local errLbl=Instance.new("TextLabel")
errLbl.AnchorPoint=Vector2.new(0.5,0)
errLbl.Size=UDim2.new(0.9,0,0,44); errLbl.Position=UDim2.new(0.5,0,0,40)
errLbl.BackgroundColor3=Color3.fromRGB(60,16,20); errLbl.BackgroundTransparency=0.08; errLbl.BorderSizePixel=0
errLbl.Text=""; errLbl.TextWrapped=true; errLbl.Font=Enum.Font.Code; errLbl.TextSize=11
errLbl.TextColor3=Color3.fromRGB(255,160,160); errLbl.Visible=false; errLbl.ZIndex=50; errLbl.Parent=gui
local function showErr(msg)
	pcall(function() errLbl.Text="[GM] "..tostring(msg); errLbl.Visible=true end)
	warn("[GM] "..tostring(msg))
end

local TH={PANEL=Color3.fromRGB(19,19,29),CARD=Color3.fromRGB(26,26,40),ACC=Color3.fromRGB(125,90,255),ACC2=Color3.fromRGB(70,170,255),TEXT=Color3.fromRGB(238,238,246),MUTED=Color3.fromRGB(150,150,175)}
local function cr(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 16); c.Parent=o; return c end
local function elt(cls,props,parent)
	local o=Instance.new(cls)
	if props then for k,v in pairs(props) do o[k]=v end end
	o.Parent=parent
	return o
end
local function stroke(o,col,th) local s=Instance.new("UIStroke"); s.Color=col or TH.ACC; s.Thickness=th or 1.1; s.Transparency=0.22; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o; return s end

local root=Instance.new("Frame")
root.Name="GM_ROOT"
root.Size=UDim2.new(1,0,1,0)
root.BackgroundTransparency=1
root.BorderSizePixel=0
root.Parent=gui

local W,H=470,340
local center=Instance.new("Frame")
center.AnchorPoint=Vector2.new(0.5,0.5)
center.Size=UDim2.new(0,W,0,H)
center.Position=UDim2.new(0.5,0,0.5,0)
center.BackgroundColor3=TH.PANEL
center.BorderSizePixel=0
center.Parent=root
cr(center,16); stroke(center,TH.ACC,1.3)

local uiScale=Instance.new("UIScale"); uiScale.Parent=center
local function applyScale()
	local cam=workspace.CurrentCamera
	if not cam then return end
	local vp=cam.ViewportSize
	local f=math.min((vp.X-32)/W,(vp.Y-32)/H)
	uiScale.Scale=math.clamp(f,0.75,1.1)
end
applyScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
end

local topH=52
local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,topH); top.BackgroundColor3=Color3.fromRGB(24,24,38); top.BorderSizePixel=0; top.Parent=center; cr(top,16)
elt("TextLabel",{Size=UDim2.new(0.85,0,0,18),Position=UDim2.new(0,16,0,9),BackgroundTransparency=1,Text="GODMOD3STORE  ·  Dashboard",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=TH.TEXT,TextXAlignment=Enum.TextXAlignment.Left},top)
elt("TextLabel",{Size=UDim2.new(0.85,0,0,12),Position=UDim2.new(0,16,1,-17),BackgroundTransparency=1,Text="by Alexander Jay (@absrdme)",Font=Enum.Font.Gotham,TextSize=10,TextColor3=TH.MUTED,TextTransparency=0.25,TextXAlignment=Enum.TextXAlignment.Left},top)

local toastLbl=Instance.new("TextLabel")
toastLbl.AnchorPoint=Vector2.new(0.5,0)
toastLbl.Size=UDim2.new(0.9,0,0,26); toastLbl.Position=UDim2.new(0.5,0,0,topH+8)
toastLbl.BackgroundColor3=Color3.fromRGB(24,24,36); toastLbl.BackgroundTransparency=0.06; toastLbl.BorderSizePixel=0
toastLbl.Text=""; toastLbl.Font=Enum.Font.Gotham; toastLbl.TextSize=11; toastLbl.TextColor3=TH.TEXT
toastLbl.TextScaled=false; toastLbl.TextWrapped=true; toastLbl.Visible=false; toastLbl.Parent=root; cr(toastLbl,10)
local function toast(t,err)
	toastLbl.Text=t
	toastLbl.TextColor3=err and Color3.fromRGB(255,135,135) or TH.TEXT
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

local vLogin=Instance.new("Frame"); vLogin.Size=UDim2.new(1,0,1,-topH); vLogin.Position=UDim2.new(0,0,0,topH); vLogin.BackgroundTransparency=1; vLogin.Visible=true; vLogin.Parent=center
local vDash=Instance.new("Frame"); vDash.Size=UDim2.new(1,0,1,-topH); vDash.Position=UDim2.new(0,0,0,topH); vDash.BackgroundTransparency=1; vDash.Visible=false; vDash.Parent=center
local function show(d) vLogin.Visible=(d=="login"); vDash.Visible=(d=="dash") end

local lCard=Instance.new("Frame"); lCard.AnchorPoint=Vector2.new(0.5,0.5); lCard.Size=UDim2.new(0,360,0,196); lCard.Position=UDim2.new(0.5,0,0.5,0); lCard.BackgroundColor3=TH.CARD; lCard.BorderSizePixel=0; lCard.Parent=vLogin; cr(lCard,12)
elt("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,14),BackgroundTransparency=1,Text="Masukkan Key Lisensi",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=TH.TEXT},lCard)
elt("TextLabel",{Size=UDim2.new(1,-22,0,28),Position=UDim2.new(0,11,0,36),BackgroundTransparency=1,Text="Key tidak terikat ke akun Roblox tertentu.\nGunakan key yang diberikan admin.",Font=Enum.Font.Gotham,TextSize=10,TextColor3=TH.MUTED},lCard)

local box=Instance.new("TextBox")
box.Size=UDim2.new(1,-22,0,40); box.Position=UDim2.new(0,11,0,72)
box.BackgroundColor3=Color3.fromRGB(16,16,24); box.Text=""; box.PlaceholderText="GODMOD3-xxxxxxxxxxxxxxxx…"
box.Font=Enum.Font.Code; box.TextSize=11; box.TextColor3=TH.TEXT; box.PlaceholderColor3=Color3.fromRGB(95,95,120)
box.ClearTextOnFocus=false; box.Parent=lCard; cr(box,10); stroke(box,TH.ACC,1)
local lPad=Instance.new("UIPadding"); lPad.PaddingLeft=UDim.new(0,10); lPad.PaddingRight=UDim.new(0,10); lPad.Parent=box

local btn=Instance.new("TextButton")
btn.Size=UDim2.new(1,-22,0,38); btn.Position=UDim2.new(0,11,1,-50)
btn.BackgroundColor3=TH.ACC; btn.AutoButtonColor=false; btn.Text="MASUK  →"; btn.Font=Enum.Font.GothamBold; btn.TextSize=12; btn.TextColor3=Color3.fromRGB(255,255,255); btn.Parent=lCard; cr(btn,10)
stroke(btn,TH.ACC2,1.2)

local pRow=Instance.new("Frame"); pRow.Size=UDim2.new(1,-20,0,58); pRow.Position=UDim2.new(0,10,0,8); pRow.BackgroundColor3=TH.CARD; pRow.Parent=vDash; cr(pRow,12)
local thumb=Instance.new("ImageLabel"); thumb.Size=UDim2.new(0,44,0,44); thumb.Position=UDim2.new(0,7,0.5,-22); thumb.BackgroundColor3=Color3.fromRGB(22,22,34); thumb.BorderSizePixel=0; thumb.Image=""; thumb.Parent=pRow; cr(thumb,22)
elt("TextLabel",{Size=UDim2.new(0.95,0,0,16),Position=UDim2.new(0,60,0,9),BackgroundTransparency=1,Text=lp.DisplayName.."  (@"..lp.Name..")",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=TH.TEXT,TextXAlignment=Enum.TextXAlignment.Left},pRow)
elt("TextLabel",{Size=UDim2.new(0.95,0,0,12),Position=UDim2.new(0,60,0,26),BackgroundTransparency=1,Text="UserId: "..tostring(lp.UserId),Font=Enum.Font.Code,TextSize=10,TextColor3=TH.MUTED,TextXAlignment=Enum.TextXAlignment.Left},pRow)
local badge=elt("TextLabel",{Size=UDim2.new(0,50,0,16),Position=UDim2.new(0,60,1,-19),BackgroundColor3=Color3.fromRGB(90,90,115),Text="FREE",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=Color3.fromRGB(255,255,255)},pRow); cr(badge,7)
local keyLbl=elt("TextLabel",{Size=UDim2.new(0,160,0,11),Position=UDim2.new(1,-166,0,6),BackgroundTransparency=1,Text="",Font=Enum.Font.Code,TextSize=9,TextColor3=TH.MUTED,TextXAlignment=Enum.TextXAlignment.Right},pRow)

elt("TextLabel",{Size=UDim2.new(0.95,0,0,13),Position=UDim2.new(0,10,0,70),BackgroundTransparency=1,Text="Cheat yang kamu miliki",Font=Enum.Font.Gotham,TextSize=11,TextColor3=TH.MUTED,TextXAlignment=Enum.TextXAlignment.Left},vDash)
local sc=Instance.new("ScrollingFrame")
sc.Size=UDim2.new(1,-20,1,-158); sc.Position=UDim2.new(0,10,0,88); sc.BackgroundTransparency=1; sc.BorderSizePixel=0
sc.CanvasSize=UDim2.new(0,0,0,0); sc.ScrollBarThickness=4; sc.ScrollBarImageColor3=TH.ACC; sc.Parent=vDash
local lay=Instance.new("UIListLayout"); lay.Padding=UDim.new(0,6); lay.Parent=sc
local emptyLbl=elt("TextLabel",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Text="Belum ada cheat yang diberikan.\nHubungi admin untuk aktivasi.",Font=Enum.Font.Gotham,TextSize=11,TextColor3=TH.MUTED,TextWrapped=true,Visible=false},sc)

local bottom=Instance.new("Frame"); bottom.Size=UDim2.new(1,-20,0,28); bottom.Position=UDim2.new(0,10,1,-36); bottom.BackgroundTransparency=1; bottom.Parent=vDash
local outBtn=Instance.new("TextButton"); outBtn.Size=UDim2.new(0,80,1,0); outBtn.Position=UDim2.new(1,-80,0,0); outBtn.Text="Keluar"; outBtn.Font=Enum.Font.Gotham; outBtn.TextSize=11; outBtn.TextColor3=TH.MUTED; outBtn.BackgroundColor3=Color3.fromRGB(30,30,44); outBtn.Parent=bottom; cr(outBtn,10)

local function paintBadge()
	if isVIP then badge.Text="VIP"; badge.BackgroundColor3=Color3.fromRGB(235,185,55); badge.TextColor3=Color3.fromRGB(28,22,8)
	else badge.Text="FREE"; badge.BackgroundColor3=Color3.fromRGB(90,90,115); badge.TextColor3=Color3.fromRGB(255,255,255) end
	if labelText and #labelText>0 then keyLbl.Text=labelText end
end
local running=false
local function loadThumb()
	pcall(function()
		local u="https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..tostring(lp.UserId).."&size=150x150&format=Png&isCircular=true"
		local r=HTTP({Url=u,Method="GET"}); if not r or r.StatusCode~=200 then return end
		local j=nil; pcall(function() j=HttpService:JSONDecode(r.Body) end)
		local url=j and j.data and j.data[1] and j.data[1].imageUrl
		if url then thumb.Image=url end
	end)
end

local function renderCheats()
	for _,c in ipairs(sc:GetChildren()) do if c:IsA("Frame") and c.Name=="GM_ROW" then c:Destroy() end end
	if #cheats==0 then emptyLbl.Visible=true; sc.CanvasSize=UDim2.new(0,0,0,40); return end
	emptyLbl.Visible=false
	for _,ch in ipairs(cheats) do
		local row=Instance.new("Frame"); row.Name="GM_ROW"; row.Size=UDim2.new(1,-4,0,56); row.BackgroundColor3=TH.CARD; row.BorderSizePixel=0; row.Parent=sc; cr(row,10)
		elt("TextLabel",{Name="t",Text=ch.title or ch.id,Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,Size=UDim2.new(0.66,0,0,16),Position=UDim2.new(0,12,0,7),TextColor3=TH.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
		elt("TextLabel",{Name="d",Text=(ch.description and #ch.description>0) and ch.description or "",Font=Enum.Font.Gotham,TextSize=10,BackgroundTransparency=1,Size=UDim2.new(0.66,0,0,26),Position=UDim2.new(0,12,0,24),TextColor3=TH.MUTED,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd},row)
		local go=Instance.new("TextButton"); go.Size=UDim2.new(0,80,0,30); go.Position=UDim2.new(1,-88,0.5,-15); go.BackgroundColor3=TH.ACC; go.AutoButtonColor=false; go.Text="EKSEKUSI  ▶"; go.Font=Enum.Font.GothamBold; go.TextSize=11; go.TextColor3=Color3.fromRGB(255,255,255); go.Parent=row; cr(go,9)
		go.MouseButton1Click:Connect(function()
			if running then toast("Sedang menjalankan…"); return end
			local cur=token; if not cur or #cur~=64 then toast("Sesi habis. Login ulang.",true); show("login"); return end
			running=true; go.Text="…"; go.BackgroundColor3=Color3.fromRGB(80,80,110)
			task.spawn(function()
				local code,data=postJson(API_VALIDATE,{t=cur,c=ch.id})
				if code~=200 or not (data and data.ok and data.payload and #data.payload>0) then
					running=false; go.Text="EKSEKUSI  ▶"; go.BackgroundColor3=TH.ACC
					local msg=(data and data.reason) or ("HTTP "..tostring(code))
					if msg:find("Sesi") or msg:find("berakhir") then token=nil; cheats={}; show("login") end
					toast("Gagal: "..tostring(msg),true); return
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
	sc.CanvasSize=UDim2.new(0,0,0,math.max(40,tonumber(y) or 0))
end

local function doLogin(forceKey)
	local key
	if type(forceKey)=='string' then key=forceKey
	else key=box.Text:gsub("^%s+",""):gsub("%s+$","") end
	if #key<32 then toast("Key minimal 32 karakter.",true); return end
	btn.Text="…"; btn.BackgroundColor3=Color3.fromRGB(80,80,110)
	local code,data=postJson(API_LOGIN,{k=key,u=lp.UserId})
	btn.Text="MASUK  →"; btn.BackgroundColor3=TH.ACC
	if code~=200 or not (data and data.ok and data.token) then
		local msg=(data and data.reason) or ("HTTP "..tostring(code))
		if msg=="Key tidak valid" or msg=="Key expired" or msg=="Key terikat ke akun lain" then clearSession() end
		toast("Gagal: "..tostring(msg),true); return
	end
	saveSession(key)
	token=data.token; labelText=data.label
	isVIP=(data.vip==true)
	cheats=(type(data.cheats)=="table") and data.cheats or {}
	if type(labelText)~="string" then labelText="" end
	loadThumb()
	local ok,err=pcall(function() paintBadge(); renderCheats() end)
	if not ok then showErr("renderCheats: "..tostring(err)); return end
	show("dash"); toast("Login berhasil  ·  "..(isVIP and "VIP" or "FREE")..(labelText~="" and ("  ·  "..labelText) or ""))
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
	box.Text=""; show("login"); toast("Sesi ditutup & key dihapus.")
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
