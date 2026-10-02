-- GODMOD3STORE DASHBOARD v2 (by Alexander Jay @absrdme)
-- 1-baris publik (tanpa rahasia) -> di-publish ke GitHub raw:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/RobloxForFun/refs/heads/main/GODMOD3STORE/Dashboard.lua"))()
-- Alur: LOGIN (key) -> OVERVIEW (profil Roblox + VIP/Free + cheat yang di-grant) -> EKSEKUSI (payload dari Storage, lalu loadstring).
-- Profil Roblox diambil langsung dari LocalPlayer (tidak disimpan di DB); badge VIP/Free dari sistem (kolom keys.vip).
-- Bucket payloads private; Edge Function memakai service_role; RLS aktif TANPA policy (anon ditolak).
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local lp=Players.LocalPlayer if not lp then return end

local API_LOGIN=(getgenv and getgenv().GM_API_LOGIN) or "https://zgmkifwoucfuqmiobcbo.supabase.co/functions/v1/login"
local API_VALIDATE=(getgenv and getgenv().GM_API_VALIDATE) or "https://zgmkifwoucfuqmiobcbo.supabase.co/functions/v1/validate"
local HTTP=(syn and syn.request) or request or http_request
if not HTTP then error("[GM] executor tidak punya HTTP request") end

-- State sesi (session-local, TIDAK ditulis ke disk; token 10m di server)
local token=nil
local cheats={}
local labelText=nil
local isVIP=false
local loggedUid=lp.UserId

-- ===== SESI KEY (ingat key -> auto-login boot) =====
-- Simpan key plaintext per UserId di file executor (bukan di DB!). Kalau executor
-- tidak punya file API, fallback ke getgenv() (hilang saat restart executor).
-- Tradeoff: key di mesin sendiri = orang lain yang pegang mesin ini bisa baca file.
-- Hapus otomatis saat: tombol Keluar, atau server bilang key tidak valid/expired.
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
	-- 1) getgenv (bertahan selama executor hidup, lintas reload/teleport)
	local g=getgenv and getgenv()
	if g and type(g.GM_SAVED_KEY)=='string' and #g.GM_SAVED_KEY>=32 then return g.GM_SAVED_KEY end
	-- 2) file (bertahan lintas restart executor)
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

-- UI root
local pg=lp:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("GODMOD3STORE_UI")
if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="GODMOD3STORE_UI"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=999
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local parent=nil
pcall(function() parent=(gethui and gethui()) or game.CoreGui end)
if not (parent and pcall(function() gui.Parent=parent end)) then gui.Parent=pg end

-- Desain dasar (gelap + neon ungu-biru, gaya lisensi/bios)
local TH={BG=Color3.fromRGB(11,11,18),PANEL=Color3.fromRGB(19,19,29),CARD=Color3.fromRGB(26,26,40),ACC=Color3.fromRGB(125,90,255),ACC2=Color3.fromRGB(70,170,255),TEXT=Color3.fromRGB(238,238,246),MUTED=Color3.fromRGB(150,150,175)}
local function cr(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 16); c.Parent=o; return c end
-- helper: buat instance + set properti dari tabel + parent (Instance.new TIDAK menerima tabel properti)
local function elt(cls,props,parent)
	local o=Instance.new(cls)
	if props then for k,v in pairs(props) do o[k]=v end end
	o.Parent=parent
	return o
end
local function stroke(o,col,th) local s=Instance.new("UIStroke"); s.Color=col or TH.ACC; s.Thickness=th or 1.1; s.Transparency=0.22; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o; return s end
local function pad(o,l,r,t,b) local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,l or 16); p.PaddingRight=UDim.new(0,r or 16); p.PaddingTop=UDim.new(0,t or 14); p.PaddingBottom=UDim.new(0,b or 14); p.Parent=o; return p end

local root=Instance.new("Frame")
root.Size=UDim2.new(1,0,1,0)
root.BackgroundColor3=Color3.fromRGB(0,0,0)
root.BackgroundTransparency=0.18
root.BorderSizePixel=0
root.Parent=gui
local center=Instance.new("Frame")
-- AnchorPoint tengah + Position scale 0.5: wajib supaya UIScale tetap center di layar sempit.
center.AnchorPoint=Vector2.new(0.5,0.5)
center.Size=UDim2.new(0,620,0,430)
center.Position=UDim2.new(0.5,0,0.5,0)
center.BackgroundColor3=TH.PANEL
center.BorderSizePixel=0
center.Parent=root
cr(center,18); stroke(center, TH.ACC, 1.4)
-- Responsif: desain pada 620x430, lalu di-skala agar selalu muat di viewport (HP/tablet/PC).
local uiScale=Instance.new("UIScale"); uiScale.Parent=center
local function applyScale()
	local cam=workspace.CurrentCamera
	if not cam then return end
	local vp=cam.ViewportSize
	local f=math.min((vp.X-24)/620,(vp.Y-24)/430)
	uiScale.Scale=math.clamp(f,0.55,1.5)
end
applyScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
end
local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,56); top.BackgroundColor3=Color3.fromRGB(24,24,38); top.BorderSizePixel=0; top.Parent=center; cr(top,18)
local title=Instance.new("TextLabel")
title.Size=UDim2.new(0.85,0,1,0); title.Position=UDim2.new(0,18,0,0)
title.BackgroundTransparency=1; title.Text="GODMOD3STORE  ·  Dashboard"; title.Font=Enum.Font.GothamBold; title.TextSize=17; title.TextColor3=TH.TEXT; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=top
local sub=Instance.new("TextLabel")
sub.Size=UDim2.new(0.85,0,0,14); sub.Position=UDim2.new(0,18,1,-18)
sub.BackgroundTransparency=1; sub.Text="by Alexander Jay (@absrdme)"; sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=TH.MUTED; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextTransparency=0.25; sub.Parent=top

-- Toast
local toastLbl=Instance.new("TextLabel")
toastLbl.AnchorPoint=Vector2.new(0.5,0)
toastLbl.Size=UDim2.new(0.44,0,0,30); toastLbl.Position=UDim2.new(0.5,0,0,78); toastLbl.BackgroundColor3=Color3.fromRGB(24,24,36)
toastLbl.BackgroundTransparency=0.06; toastLbl.BorderSizePixel=0; toastLbl.Text=""; toastLbl.Font=Enum.Font.Gotham; toastLbl.TextSize=12; toastLbl.TextColor3=TH.TEXT; toastLbl.TextScaled=true; toastLbl.Visible=false; toastLbl.Parent=root; cr(toastLbl,10)
local function toast(t, err) toastLbl.Text=t; toastLbl.TextColor3=err and Color3.fromRGB(255,135,135) or TH.TEXT; toastLbl.Visible=true; task.delay(2.6,function() if toastLbl.Text==t then toastLbl.Visible=false end end) end
local function postJson(url, body)
	local s=HttpService:JSONEncode(body)
	local ok,r=pcall(function() return HTTP({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=s}) end)
	if not ok then warn("[GM] HTTP gagal: "..tostring(r)); return nil,nil end
	local j=nil; pcall(function() j=HttpService:JSONDecode(r and r.Body or "") end)
	return r and tonumber(r.StatusCode), j
end

-- Views: Login / Overview
local vLogin=Instance.new("Frame"); vLogin.Size=UDim2.new(1,0,1,-56); vLogin.Position=UDim2.new(0,0,0,56); vLogin.BackgroundTransparency=1; vLogin.Parent=center
local vDash=Instance.new("Frame"); vDash.Size=UDim2.new(1,0,1,-56); vDash.Position=UDim2.new(0,0,0,56); vDash.BackgroundTransparency=1; vDash.Visible=false; vDash.Parent=center
local function show(d) vLogin.Visible=(d=="login"); vDash.Visible=(d=="dash") end

-- ===== LOGIN =====
local lCard=Instance.new("Frame"); lCard.Size=UDim2.new(0,480,0,260); lCard.Position=UDim2.new(0.5,-240,0.5,-150); lCard.BackgroundColor3=TH.CARD; lCard.BorderSizePixel=0; lCard.Parent=vLogin; cr(lCard,14)
local lHead=Instance.new("TextLabel"); lHead.Size=UDim2.new(1,0,0,22); lHead.Position=UDim2.new(0,0,0,18); lHead.BackgroundTransparency=1
lHead.Text="Masukkan Key Lisensi"; lHead.Font=Enum.Font.GothamBold; lHead.TextSize=15; lHead.TextColor3=TH.TEXT; lHead.Parent=lCard
local lHint=Instance.new("TextLabel"); lHint.Size=UDim2.new(1,-22,0,30); lHint.Position=UDim2.new(0,11,0,42); lHint.BackgroundTransparency=1
lHint.Text="Key tidak terikat ke akun Roblox tertentu.\nGunakan key yang diberikan admin."; lHint.Font=Enum.Font.Gotham; lHint.TextSize=11; lHint.TextColor3=TH.MUTED; lHint.Parent=lCard

local box=Instance.new("TextBox")
box.Size=UDim2.new(1,-22,0,46); box.Position=UDim2.new(0,11,0,84)
box.BackgroundColor3=Color3.fromRGB(16,16,24); box.Text=""; box.PlaceholderText="GM-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx…"
box.Font=Enum.Font.Code; box.TextSize=12; box.TextColor3=TH.TEXT; box.PlaceholderColor3=Color3.fromRGB(95,95,120)
box.ClearTextOnFocus=false; box.Parent=lCard; cr(box,10); stroke(box, TH.ACC, 1); pad(box,12,12,6,6)

local btn=Instance.new("TextButton")
btn.Size=UDim2.new(1,-22,0,42); btn.Position=UDim2.new(0,11,1,-56)
btn.BackgroundColor3=TH.ACC; btn.AutoButtonColor=false; btn.Text="MASUK  →"; btn.Font=Enum.Font.GothamBold; btn.TextSize=13; btn.TextColor3=Color3.fromRGB(255,255,255); btn.Parent=lCard; cr(btn,10)
local btnStroke=stroke(btn, TH.ACC2, 1.2)

-- ===== OVERVIEW (profil + list cheat + eksekusi) =====
-- Profil (avatar + username + badge)
local pRow=Instance.new("Frame"); pRow.Size=UDim2.new(1,-22,0,64); pRow.Position=UDim2.new(0,11,0,8); pRow.BackgroundColor3=TH.CARD; pRow.Parent=vDash; cr(pRow,12)
local thumb=Instance.new("ImageLabel"); thumb.Size=UDim2.new(0,52,0,52); thumb.Position=UDim2.new(0,8,0.5,-26); thumb.BackgroundColor3=Color3.fromRGB(22,22,34); thumb.BorderSizePixel=0; thumb.Image=""; thumb.Parent=pRow; cr(thumb,26)
local uname=Instance.new("TextLabel"); uname.Size=UDim2.new(0.95,0,0,18); uname.Position=UDim2.new(0,72,0,10); uname.BackgroundTransparency=1; uname.Text=lp.DisplayName.."  (@"..lp.Name..")"; uname.Font=Enum.Font.GothamBold; uname.TextSize=13; uname.TextColor3=TH.TEXT; uname.TextXAlignment=Enum.TextXAlignment.Left; uname.Parent=pRow
local uidLbl=Instance.new("TextLabel"); uidLbl.Size=UDim2.new(0.95,0,0,12); uidLbl.Position=UDim2.new(0,72,0,29); uidLbl.BackgroundTransparency=1; uidLbl.Text="UserId: "..tostring(lp.UserId); uidLbl.Font=Enum.Font.Code; uidLbl.TextSize=10; uidLbl.TextColor3=TH.MUTED; uidLbl.TextXAlignment=Enum.TextXAlignment.Left; uidLbl.Parent=pRow
local badge=Instance.new("TextLabel"); badge.Size=UDim2.new(0,54,0,18); badge.Position=UDim2.new(0,72,1,-20); badge.BackgroundColor3=Color3.fromRGB(90,90,115); badge.Text="FREE"; badge.Font=Enum.Font.GothamBold; badge.TextSize=10; badge.TextColor3=Color3.fromRGB(255,255,255); badge.Parent=pRow; cr(badge,7)
local keyLbl=Instance.new("TextLabel"); keyLbl.Size=UDim2.new(0,180,0,11); keyLbl.Position=UDim2.new(1,-184,0,6); keyLbl.BackgroundTransparency=1; keyLbl.Text=""; keyLbl.Font=Enum.Font.Code; keyLbl.TextSize=9; keyLbl.TextColor3=TH.MUTED; keyLbl.TextXAlignment=Enum.TextXAlignment.Right; keyLbl.Parent=pRow

local listTitle=Instance.new("TextLabel"); listTitle.Size=UDim2.new(0.95,0,0,14); listTitle.Position=UDim2.new(0,11,0,82); listTitle.BackgroundTransparency=1; listTitle.Text="Cheat yang kamu miliki"; listTitle.Font=Enum.Font.Gotham; listTitle.TextSize=12; listTitle.TextColor3=TH.MUTED; listTitle.TextXAlignment=Enum.TextXAlignment.Left; listTitle.Parent=vDash
local sc=Instance.new("ScrollingFrame");
-- fill dinamis: list selalu terlihat penuh tanpa overlap, tinggi = sisa ruang view - footer
sc.Size=UDim2.new(1,-22,1,-150); sc.Position=UDim2.new(0,11,0,102); sc.BackgroundTransparency=1; sc.BorderSizePixel=0; sc.CanvasSize=UDim2.new(0,0,0,0); sc.ScrollBarThickness=4; sc.ScrollBarImageColor3=TH.ACC; sc.Parent=vDash
local lay=Instance.new("UIListLayout"); lay.Padding=UDim.new(0,8); lay.Parent=sc
local emptyLbl=Instance.new("TextLabel"); emptyLbl.Size=UDim2.new(1,0,0,40); emptyLbl.BackgroundTransparency=1; emptyLbl.Text="Belum ada cheat yang diberikan.\nHubungi admin untuk aktivasi."; emptyLbl.Font=Enum.Font.Gotham; emptyLbl.TextSize=11; emptyLbl.TextColor3=TH.MUTED; emptyLbl.TextWrapped=true; emptyLbl.Visible=false; emptyLbl.Parent=sc

local bottom=Instance.new("Frame"); bottom.Size=UDim2.new(1,-22,0,32); bottom.Position=UDim2.new(0,11,1,-36); bottom.BackgroundTransparency=1; bottom.Parent=vDash
local outBtn=Instance.new("TextButton"); outBtn.Size=UDim2.new(0,90,1,0); outBtn.Position=UDim2.new(1,-90,0,0); outBtn.Text="Keluar"; outBtn.Font=Enum.Font.Gotham; outBtn.TextSize=12; outBtn.TextColor3=TH.MUTED; outBtn.BackgroundColor3=Color3.fromRGB(30,30,44); outBtn.Parent=bottom; cr(outBtn,10)

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
	if #cheats==0 then emptyLbl.Visible=true; sc.CanvasSize=UDim2.new(0,0,0,44); return end
	emptyLbl.Visible=false
	for _,ch in ipairs(cheats) do
		local row=Instance.new("Frame"); row.Name="GM_ROW"; row.Size=UDim2.new(1,0,0,62); row.BackgroundColor3=TH.CARD; row.BorderSizePixel=0; row.Parent=sc; cr(row,12)
		elt("TextLabel",{Name="t",Text=ch.title or ch.id,Font=Enum.Font.GothamBold,TextSize=13,BackgroundTransparency=1,Size=UDim2.new(0.72,0,0,18),Position=UDim2.new(0,14,0,8),TextColor3=TH.TEXT,TextXAlignment=Enum.TextXAlignment.Left},row)
		elt("TextLabel",{Name="d",Text=(ch.description and #ch.description>0) and ch.description or "",Font=Enum.Font.Gotham,TextSize=10,BackgroundTransparency=1,Size=UDim2.new(0.72,0,0,28),Position=UDim2.new(0,14,0,26),TextColor3=TH.MUTED,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},row)
		local go=Instance.new("TextButton"); go.Size=UDim2.new(0,86,0,32); go.Position=UDim2.new(1,-96,0.5,-16); go.BackgroundColor3=TH.ACC; go.AutoButtonColor=false; go.Text="EKSEKUSI  ▶"; go.Font=Enum.Font.GothamBold; go.TextSize=11; go.TextColor3=Color3.fromRGB(255,255,255); go.Parent=row; cr(go,10)
		go.MouseButton1Click:Connect(function()
			if running then toast("Sedang menjalankan…"); return end
			local cur=token; if not cur or #cur~=64 then toast("Sesi habis. Login ulang.", true); show("login"); return end
			running=true; go.Text="…"; go.BackgroundColor3=Color3.fromRGB(80,80,110)
			task.spawn(function()
				local scode, data=postJson(API_VALIDATE, {t=cur, c=ch.id})
				if scode~=200 or not (data and data.ok and data.payload and #data.payload>0) then
					running=false; go.Text="EKSEKUSI  ▶"; go.BackgroundColor3=TH.ACC
					local msg=data and data.reason or ("HTTP "..tostring(scode))
					if msg:find("Sesi") or msg:find("berakhir") then token=nil; cheats={}; show("login") end
					toast("Gagal: "..tostring(msg), true); return
				end
				-- BERSIHKAN dashboard SEBELUM eksekusi agar HUD baru (payload) tidak tumpuk.
				local p=ch and ch.id or "?"
				running=false
				-- teruskan token ke payload -> payload jalankan kill-switch (revoke = mati)
				if getgenv then
					getgenv().GM_TOKEN=cur
					getgenv().GM_API_VALIDATE=API_VALIDATE
				end
				pcall(function() toastLbl.Visible=false end)
				pcall(function() gui:Destroy() end)
				local ok, err=pcall(function() loadstring(data.payload)() end)
				if not ok then warn("[GM] loadstring cheat "..p.." gagal: "..tostring(err)) end
			end)
		end)
	end
	local _,y=pcall(function() return lay.AbsoluteContentSize.Y end)
	sc.CanvasSize=UDim2.new(0,0,0, math.max(44, tonumber(y) or 0))
end

local function doLogin(forceKey)
	local key
	if type(forceKey)=='string' then
		key=forceKey
	else
		key=box.Text:gsub("^%s+",""):gsub("%s+$","")
	end
	if #key<32 then toast("Key minimal 32 karakter.", true); return end
	btn.Text="…"; btn.BackgroundColor3=Color3.fromRGB(80,80,110)
	local scode, data=postJson(API_LOGIN, {k=key, u=lp.UserId})
	btn.Text="MASUK  →"; btn.BackgroundColor3=TH.ACC
	if scode~=200 or not (data and data.ok and data.token) then
		local msg=data and data.reason or ("HTTP "..tostring(scode))
		if msg=="Key tidak valid" or msg=="Key expired" or msg=="Key terikat ke akun lain" then
			clearSession() -- key mati -> simpan tidak kekal, paksa masukkan key baru
		end
		toast("Gagal: "..tostring(msg), true); return
	end
	saveSession(key)
	token=data.token; labelText=data.label
	isVIP=data.vip==true
	cheats=(type(data.cheats)=="table") and data.cheats or {}
	if type(labelText)~="string" then labelText="" end
	loadThumb()
	local ok,err=pcall(function() paintBadge(); renderCheats() end)
	if not ok then toast("Render gagal: "..tostring(err), true); warn("[GM] doLogin renderCheats: "..tostring(err)); return end
	show("dash"); toast("Login berhasil  ·  "..(isVIP and "VIP" or "FREE")..(labelText~="" and ("  ·  "..labelText) or ""))
	pcall(function() box.Text="" end)
end

btn.MouseButton1Click:Connect(function()
	local ok,err=pcall(doLogin)
	if not ok then toast("Login gagal: "..tostring(err), true); warn("[GM] doLogin error: "..tostring(err)) end
end)
box.FocusLost:Connect(function(enter)
	if enter then
		local ok,err=pcall(doLogin)
		if not ok then toast("Login gagal: "..tostring(err), true); warn("[GM] doLogin error: "..tostring(err)) end
	end
end)
outBtn.MouseButton1Click:Connect(function()
	token=nil; cheats={}; labelText=nil; isVIP=false
	clearSession()
	box.Text=""; show("login"); toast("Sesi ditutup & key dihapus.")
end)

-- Auto-login: kalau ada key tersimpan, langsung masuk dashboard tanpa mengetik ulang.
show("login")
do
	local saved=loadSession()
	if saved then
		box.Text=saved
		task.spawn(function()
			local ok,err=pcall(doLogin,saved)
			if not ok then toast("Login gagal: "..tostring(err), true); warn("[GM] auto-login error: "..tostring(err)) end
		end)
	end
end
print("[GM] GODMOD3STORE dashboard loaded (by Alexander Jay @absrdme) — masukkan key lalu pilih cheat.")
