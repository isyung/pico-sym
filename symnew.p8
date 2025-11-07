pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	poke(0x5f2e,1)
	poke(0x5f2d,1)
	my=0
	mx=63
	mb_prev = 0
	clicked = false
	held=false
	sp=1
	cell=8
	rndcols()
	init_fx()
	inittb()
	initplr()--holds rate
	initsym()
	initcanv()
	initopp()
	initmsg()
	debug=""
	debug2=""
	curs={
		name="cursor",
		s=1,
		col=selected.col,
	}
	turn_ready = false

end

function selected_used()
  if not selected_idx then return false end
  local b = buttons[selected_idx]
  return b and b.used or false
end

function _update()
 curs.col=selected.col
	mx=stat(32)
	my=stat(33)
	mb=stat(34)
	clicked=(mb&1)==1 and (mb_prev&1)==0
	held=(mb&1)==1
	if held then
		if over(canv) then
			if not occupied() and not selected_used() then
				-- allow heal symbols always, others only if player has >1 health
				if selected.col == cols.grn or plr.hth > 1 then
local cx, cy = getcell()
local def = buttons[selected_idx].sym   -- prototype only

placed = spawn(def,cx,cy,symnum)
--placed = {
--  x=cx, y=cy,
--  s=selected.s,
--  col=selected.col,
--  name=selected.name,
--  tags=selected.tags,
--  parts = (bs and bs.parts) or selected.parts, -- may be nil for 1-tile
--  num=symnum,
--  trig=1
--}
					addsym()
					symnum += 1
				elseif clicked then
					msgcol = 8
					msg = "tired"
					sfx(1)
					s(mx,my,4,4)
				end
			elseif clicked then
				msgcol = 8
				msg = "no room"
				sfx(1)
			end
		else
			msgcol = 0
			msg = ""
		end
	end
	show()
	if btnp(❎)then
	_init()
	end

	mb_prev = mb
	updatetb()
	updateplr()
	updatesym()
	updateopp()
	updateshow()
	update_particles()
	frame +=1
	update_bumps()
	update_scans()
	fcount=0
end

function _draw()
	cls(1)
	drawcanvui()

	for s in all(shown) do
		if over(s) then
		drawprev(s)
		end
	end
	drawhigh()
	if debug !=""then
		print("ms "..tostr(debug),60,100,selected.col[1])
	end
	print(debug2,60,110,selected.col[1])
	drawplr()
	drawtb()
	drawopp()
	draw_fx()
	draw_particles()
	drawsym(curs,mx-1,my,true)--cursor not symbol
	drawmsg(msg,mx,my,11)
end

function outline(outcol,s,x,y,w,h,flip_h)
	allcol(outcol)
	local f=flip_h or false
	for o in all(offs) do
		spr(s,x+o[1],y+o[2],w,h,f)
	end
	pal()
	spr(s,x,y,w,h,f)
end

function getcell()
	if over(canv) then
		local cx = flr((mx - canv.x) / cell) * cell
		local cy = flr((my - canv.y) / cell) * cell
		return cx, cy
	end
end

function palyj()
	pal({[0]=0,1,2,3,-7,5,6,7,8,9,10,11,12,13,-8,-5},1)
end


function d6()
  return flr(rnd(6))+1
end

function str_width(s)
  return #tostr(s)*4
end

function deepcopy(t, seen)
  if type(t)~="table" then return t end
  seen=seen or {}; if seen[t] then return seen[t] end
  local n={}; seen[t]=n
  for k,v in pairs(t) do n[deepcopy(k,seen)] = deepcopy(v,seen) end
  return n
end

-->8
--symbol

function initsym()
	placed={}
	symnum=0
	-- 4 offsets for outline
	offs={
		{1,0},{-1,0},
		{0,1},{0,-1}
	}
	for i=1,#symdefs do
		bake_parts(symdefs[i], cell)
	end
	symtimer=rate
	symphase=0
end

function allcol(col)
	local palall={}--pal 2 make cols blk
	for i=0,15 do palall[i]=col end
	pal(palall)
end

function addsym()
	if not placed or placed.x==nil or placed.y==nil then return end

	local cx, cy = placed.x,placed.y
	local b=buttons[selected_idx]
	local p=placed
	plr.state="str"
	timer=rate
	plr.hth-=1
	add(canv.syms, p)  
--	if b.sym.parts then
--		add(canv.syms, {
--			x=cx,
--			y=cy,
--			s=p.s,
--			col=p.col,
--			name=p.name,
--			tags=p.tags,
--			parts=p.parts,
--			num=p.num,
--			trig=1
--		})
--		for a=2,#b.sym.parts do
--				local ox,oy=
--					b.sym.msk[a][1]*cell,
--					b.sym.msk[a][2]*cell
--					
--				add(canv.syms, {
--					x=cx+ox,
--					y=cy+oy,
--					col=p.col,
--					name=p.name,
--					tags=p.tags,
--					num=p.num,
--					trig=1
--				})
--			end
--	end
	local cols = sym_colors(p)
	local bx,by,bw,bh=sym_bbox(p, cx+canv.x, cy+canv.y)
	el(bx, by, bw, bh, cols)
	--s(bx, by, bw, bh,cols)
	sfx(0)
	local res = onadd(selected, cx, cy)
	
	msg     = res.msg
	msgcol  = res.msgcol
	showmsg(canv.x, canv.y+100)
	
	if selected_idx and b then
		b.uses-= 1
		if b.uses<1 then
			b.used=true
		end
	end
	updatesat()
	--updatestats()
end

function bake_parts(sym, cell)
	if sym.atl and sym.msk then
		sym.parts={}
		for i=1,#sym.atl do
			add(sym.parts, {
				id=sym.atl[i],
				px=sym.msk[i][1]*cell,
				py=sym.msk[i][2]*cell
			})
		end
	else
		sym.parts={{id=sym.s, px=0, py=0}}
	end
end

function drawsym(sym,x,y,is_icon)
	local parts
	local dy = 0
 if sym.num and bumps[sym.num] then
 	dy = bump_dy 
 end
	if is_icon then
		--force single tile
		parts={{id=sym.s,px=0,py=0}}
	else
		--make it parts if i made 1
		parts=sym.parts or
		{{id=sym.s, px=0, py=0}}
	end
	
	local c=sym.col
	--change all to blck:
	allcol(0)
	--for every part:
	for p in all(parts) do
		local bx=x+p.px
		local by=y+p.py
		--draw outline 4x
		for o in all(offs) do
			spr(p.id, bx+o[1], by+o[2]+dy, 1, 1)
		end
	end
	
	pal() --reset
	if sym.trig and sym.trig<1 then
		pal({
			[7]=c[2],-- chnge white to c
			[6]=c[2],-- chnge grey to c2
			[14]=c[1] -- chnge pnk to white
		})
	else
		pal({
			[7]=c[1],-- chnge white to c
			[6]=c[2],-- chnge grey to c2
			[14]=7 -- chnge pnk to white
		})
	end
	
	--draw parts (hwvr many)
	for p in all(parts) do
		spr(p.id,x+p.px,y+p.py+dy,1,1)
	end
	pal()
end

function adjsym(sym)
  if not sym then return {} end
  local list = build_scan(sym)
  local seen, out = {}, {}
  for c in all(list) do
    if c.hit then
      local n   = c.ref
      local key = (n and n.num) or n
      if not seen[key] then
        seen[key] = true
        add(out, n)
      end
    end
  end
  return out
end

function updatesym()
symtimer-=1
	if symtimer<=0 then
		symtimer=rate
		symphase+=1
		if symphase>4 then
		symphase=0
		end
	end
end

function sym_colors(sym)
  local c1 = (sym.col and sym.col[1]) or 7
  local c2 = (sym.col and sym.col[2]) or 6
  return {c1, c2, 7}
end

-->8
--canvas

function initcanv()
	ccols=3
	crows=4
	canv={
		w=ccols*cell,
		h=crows*cell,
		x=0,
		y=0,
		syms={},
		att=0,
		def=0,
		cash=0,
		heal=0,
		pois=0
	}
	shown={}

	showbtn={
			w   =btn_size*2,
			h   =btn_size/1.5,
			x   =100,
			y   =100,
			lbl="done",
			is_selected=false,
			uses=1000,
			used=false,
		}
		
	last_att = 0
	last_def = 0
	onshow_pending = true
end

function updateshow()
		if over(showbtn) and held then
			showbtn.is_selected = true
		else
			showbtn.is_selected = false
		end
end

function drawcanvui()
	local x,y,w,h,tbr,m
	w=(canv.w)-1
	h=(canv.h)-1
	--right edge of toolbar
	tbr=(tbx+tbcols*(btn_size))
	--canv will b in center of m
	m=(128-tbr)
	--x=flr((tbr+(m/2)-(w/2))/8)*cell
	x=8.5*cell
	y=flr((64-(h/2))/8)*cell
	
	canv.x=x
	canv.y=y
	
	
	drawcanv(x,y,w,h,canv)
	drawmsk()
	showbtn.x=canv.x-
	(showbtn.w/2)+(canv.w/2) + 1
	showbtn.y=canv.y+canv.h + 4
	draw_btn(showbtn)
	drawminis()
	drawstats(canv)
end

function updatestats()
	local t={
		att=0,
		def=0,
		heal=0,
		cash=0,
		pois=0
	}
	for s in all(canv.syms) do
		local r=s.col and s.col[3]
		if t[r] then t[r]+=1 end
	end
	canv.att,canv.def,
	canv.heal,canv.cash,
	canv.pois
	=
	t.att,t.def,t.heal,
	t.cash,t.pois
end

function drawstats(t,ox,oy)--must have w,h
	local a,b=tostr(t.att),tostr(t.def)
	local total=str_width(a)+str_width("/")+str_width(b)
	local x=t.x+(t.w-total)/2
	local y=t.y-7
	local ox=ox or 0
	local oy=oy or 0
	print(a,x+ox,y+oy,8)   -- red
	x+=str_width(a)
	print("/",x+ox,y+oy,7)
	x+=str_width("/")
	print(b,x+ox,y+oy,12)  -- blue
end


function drawcanv(x,y,w,h,src)
local c=src or canv
	rectfill(x-1,y-1,x+w+2,y+h+2,7)	
	for s in all(c.syms) do
  drawsym(s, x+s.x, y+s.y)  -- no is_icon flag here
	end
end

function drawhigh()
	if over(canv) then
		local cx,cy = getcell()
		spr(2,cx+canv.x,cy+canv.y,1,1)
	end
end

function drawmsk()
local x,y=canv.x-1,canv.y-1
local rit=canv.x+canv.w+2
local bot=canv.y+canv.h+2
local thick=20
local col=1
rectfill(
rit,y-thick,
rit+thick,bot-1+thick,col)
rectfill(
x-thick,bot,
rit+thick,bot+thick,col)
rectfill(
x-thick,y-thick,
rit-1,y-1,col)
rectfill(
x-thick,y,
x-1,bot-1,col)

end


function over(thing)
	local w,h,o
	w=(thing.w)-1
	h=(thing.h)-1
	if mx >= thing.x and
		mx <= thing.x+w and
		my >= thing.y and
		my <= thing.y+h then
		o=true
	else
		o=false
	end
	return o
end
function occupied()
	local cx, cy = getcell()  -- these should already be local canvas coords
	local sym = selected or (buttons[selected_idx] and buttons[selected_idx].sym)
	if not sym then return false end

	local cand_parts = sym.parts or {{px=0, py=0}}

	for p in all(cand_parts) do
		local tx = cx + p.px
		local ty = cy + p.py

		-- check if any part is off the canvas (local grid bounds)
		if tx < 0 or ty < 0 or 
		   tx >= canv.w or ty >= canv.h then
			return true
		end

		-- overlap check (still local space)
		for s in all(canv.syms) do
			local s_parts = s.parts or {{px=0, py=0}}
			for sp in all(s_parts) do
				local sx = s.x + sp.px
				local sy = s.y + sp.py
				if sx == tx and sy == ty then
					return true
				end
			end
		end
	end

	return false
end



function drawbar(x,y,h,w,val,maxval)
	local col
	local vfac=(w-1)*(val/maxval)--max val
	local v=mid(1,vfac,w-1)
	rectfill(x,y,x+w,y-h,0)--outline
	rectfill(x+1,y-1,x+w-1,y-h+1,5)--bg
	if val<(maxval/2)then
		col=8
	else
		col=11
	end
	if val>0 then
		rectfill(x+1,y-1,
		x+v,y-h+1,col)--fill
	end
end

function show()
	if over(showbtn) and clicked then

	
	onshow_ctx = {
		weak=opp.weak,
		sel=selected and selected.name,
		oppsym=opp.sym and opp.sym.name,
		sh0=opp.def,  
	}
	

		
		onshow_pending = true
		show_fx = true
		show_ord = 0
		build_onshow_scan()
	end
	-- run exactly one step per frame:
	onshow_tick()
end

function drawminis()
	local gap = 3
	local i = 0
	for m in all(shown) do
		local mw,mh=m.w,m.h
		local mx,my=i*(mw+gap),127-mh-1
		rectfill(mx,my,mx+mw+1,127,7)
		rectfill(mx,my,mx+mw+1,127,7)

		m.x,m.y=mx,my
		for s in all(m.syms) do
			-- iterate parts; 1x1 fallback
			local parts=s.parts or {{px=0,py=0}}
			for p in all(parts) do
				-- convert world px -> mini cell coords
				local gx = flr((s.x + p.px)/cell) + 1
				local gy = flr((s.y + p.py)/cell) + 1
				-- pick a color (same() works with your {c1,c2,...})
				local col = same(s.col, cols.wht) and s.col[2] or s.col[1]
				pset(mx+gx, my+gy, col)
			end
		end
		i+=1
	end
end

function drawprev(cnv)
	local x,y,w,h=
	2,84,cnv.w*cell,cnv.h*cell
	drawcanv(x,y,w,h,cnv)
	drawstats(cnv,0,-1)
end



-->8
--message
function initmsg()
	msg="click"
	msgtimer=0
	msgcol=11
	msgx,msgy=0,0  -- where to draw the click msg
end

function drawmsg(msg,x,y)

	if clicked then
		msgtimer=10
		msgx,msgy=mx+5,my+5
	end
	
	if msgtimer > 0 then
		print(msg,msgx,msgy,msgcol)
		msgtimer-=1
	end 
	

end

function showmsg(x,y)
	msgtimer=10
	msgx,msgy=x,y
end


-->8
--toolbar
function inittb()
	tbx=8
	tby=16
	tbrows=5
	tbcols=2
	cap=10 -- max amount of btns
	
	buttons={}
	
	high_col = 7
	base_col = 6
	shade_col = 5
	sym=symdefs[1]
	btn_size = 2*cell
	populatetb()
end

function drawtb()
	for i=1,#buttons do
		local b=buttons[i]
		draw_btn(b)
	end
end


function draw_btn(b)
	local x,y=b.x,b.y
	local w,h=b.w,b.h
	local hovered=over(b)
	local selected=b.is_selected
	local pressed=selected and hovered and held
	local used=b.used
	local sym=b.sym
	local tw=b.lbl and print(b.lbl,0,-10) or 0
	
	-- background painter
	local function paint(state)
			rectfill(x,y,x+w-2,y+h-2,high_col)
		if state=="hovered" then
			rectfill(x+1,y+1,x+w-2,y+h-2,shade_col)
			rectfill(x+1,y+1,x+w-3,y+h-3,high_col)
		elseif state=="pressed" then
			rectfill(x,y,x+w-3,y+h-3,shade_col)
			rectfill(x+1,y+1,x+w-3,y+h-3,13)
		elseif state=="selected" then -- idle/selected
			rectfill(x,y,x+w-3,y+h-3,shade_col)
			rectfill(x+1,y+1,x+w-3,y+h-3,base_col)
		else
			rectfill(x+1,y+1,x+w-2,y+h-2,shade_col)
			rectfill(x+1,y+1,x+w-3,y+h-3,base_col)
		end
	end
	
	local state=
		(pressed or used) and "pressed"
		or selected and "selected"
		or hovered and "hovered"
		or "idle"
	
	paint(state)
	
	-- content (shared)
	if sym then
		drawsym(sym,
			x+(w/2)-5,
			y+(h/2)-5,true)
	elseif b.lbl then
		print(
			b.lbl,
			x+(w/2)-(tw/2),
			y+(h/2)-3,
			0
			)
	end
	if hovered and b.sym then
		local e=b.sym.col[3]
		local txt=e
		 if e then
		 					print(txt,
					(tbx+tbrows*cell)-7,
		  	y, b.sym.col[1])
			end
		  	
		if b.sym.tags then
			for i=1,#b.sym.tags do
				local tx=b.sym.tags[i]
		  	print(tx)
			end
		end

	end
end


function updatetb()
	if not clicked then return end
	for i=1,#buttons do
		local b=buttons[i]
		if over(b) then
			if selected_idx and 
				buttons[selected_idx] then
				buttons[selected_idx].is_selected = false
			end
			selected_idx=b.idx
			b.is_selected = true
			selected=b.sym
			debug=""
			break
		end
	end
end

function populatetb()
	shuff(symdefs)
	buttons = {}  -- reset
	local n=min(#symdefs,cap)--whichev is smaller
	for i=1,n do
		local r=flr((i-1)/tbcols)--which row?
		local c=(i-1)%tbcols--which col?
		local x=tbx+c*btn_size
		local y=tby+r*btn_size
		
		add(buttons,{
			idx=i,
			w   =btn_size,
			h   =btn_size,
			x   =x,
			y   =y,
			sym =symdefs[i],
			is_selected=false,
			uses=100,
			used=false,
		})
	end
	--default slection so no crash
	selected_idx=1
	buttons[1].is_selected=true
	selected=buttons[1].sym
end
-->8
--symbol defs

cols={
	blu={12,1,"def"},
	grn={11,3,"heal"},
	wht={7,6,"none"},
	red={8,2,"att"},
	org={9,4,"cash"},
	yel={10,9,"pois"},
	--gry={6,5}
}


symdefs={
	{
		name="frog",
		s=17,
		col=cols.wht,
		tags={"score_adj"},
		inst=false
	},
--	{
--		name="snake",
--		s=11,
--		col=cols.wht,
--		tags={"count_adj"},
--	},
	{
		name="dog",
		s=21,
		atl={23,39,40},
		msk={{0,0},{0,1},{1,1}},
		col=cols.wht,
		tags={"count_adj"},
		inst=true,
	},
	{
		name="rabbit",
		s=22,
		atl={37,38},
		msk={{0,0},{1,0}},
		col=cols.wht,
		inst=true,
		tags={"count_adj"}
	},
	{
		name="apple",
		s=34,
		col=cols.red,
		tags={"trig_adj"},
		inst=true
	},
	{
		name="orange",
		s=19,
		col=cols.org,
		inst=true,
		tags={"refr_adj"},
	},
	{
		name="pear",
		s=18,
		col=cols.org,
	},
	{
		name="cherry",
		s=35,
		col=cols.org,
	},
	{
		name="grape",
		s=36,
		col=cols.org,
		tags={"count_adj"},

	},
	{
		name="fish",
		s=33,
		col=cols.org,
		inst=true,
		tags={"count_adj"},
	},
	{
		name="skull",
		s=20,
		col=cols.org,
		--tags={"delete_prev"},
		tags={"del_adj"},
	}
}


function spawn(def,x,y,num)
	-- copy color so later rndcols() won't mutate past stuff
	local col=def.col
	-- copy parts (if any)
	local parts=nil
	if def.parts then
		parts={}
		for i=1,#def.parts do
			local p=def.parts[i]
			parts[i]={
				id=p.id,
				px=p.px,
				py=p.py
			}
		end
	end
	return {
		x=x,y=y,s=def.s,col=col,
		name=def.name,tags=def.tags,
		parts=parts, num=num, trig=1,
		inst=def.inst
	}
end

function same(a,b)
	if a == b then return true end -- same table reference
	if not a or not b then
		return false 
	end
	return a[1]==b[1] and a[2]==b[2]
end


function eff_del_adj(sym)
	if not sym then return {} end
	local adj=adjsym(sym)
	local seen={}
	for s in all(adj) do if s.num then seen[s.num]=true end end
	for s in all(canv.syms) do if s.num and seen[s.num] then del(canv.syms,s) end end
	return {} -- no stat add
end

-- add +1 trig to each unique adjacent sym around `sym`
function eff_refr_adj(sym)
  if not sym then return end
  local list = build_scan(sym)
  local seen = {}
  for c in all(list) do
    if c.hit then
      local n = c.ref
      local key = (n and n.num) or n
      if not seen[key] then
        seen[key] = true
        n.trig = (n.trig or 0) + 1
        -- tiny visual ping (optional)
        fx_cell(n.x, n.y, true)
      end
    end
  end
end

function eff_delete_prev()
	if #canv.syms >= 2 then
		del(canv.syms,
		canv.syms[#canv.syms-1])
	end
	return {}
end


function eff_count_adj(sym)
	return to_stat(sym,#adjsym(sym))
end

function eff_score_adj(sym)
  if not sym then return {att=0, def=0, cash=0, heal=0, pois=0} end

  local list = build_scan(sym)
  local seen = {}
  local d = {att=0, def=0, cash=0, heal=0, pois=0}

  for c in all(list) do
    if c.hit then
      local n = c.ref
      local key = (n and n.num) or n
      if not seen[key] then
        seen[key] = true

        -- optional gate: only count neighbors that still have trig
        -- if (n.trig or 0) <= 0 then goto _cont end

        local r = (n and n.col and n.col[3]) or "none"
        if d[r] ~= nil then
          d[r] += 1   -- +1 per adjacent sym of that role
        end
      end
    end
    ::_cont::
  end

  return d
end
 


function apply_eff(e)
	if e.att then canv.att += e.att end
	if e.def then canv.def += e.def end
	if e.cash then plr.cash += e.cash end
	if e.heal then plr.hth += e.heal end
	if e.pois then canv.pois += e.pois end
end

function eff_role(n)
	local d={att=0,
	def=0,cash=0,heal=0,pois=0}
	if n and n.col and n.col[3]
		and d[n.col[3]]~=nil 
		then d[n.col[3]] = 1
	end
	return d
end

function onadd(selected,cx,cy)
	local s=selected
	local p=placed
	local res={msg="added "..s.name,msgcol=s.col[2]}
	
	if s.inst then
		start_cascade()
		trig(p) -- -1 p.trig
	end
	return res
end

function rndcols()
	local keys={}
	for k in pairs(cols) do
		add(keys,k)
	end
	
	for i=1,#symdefs do
		local r=flr(rnd(#keys))+1
		local k=keys[r]
		symdefs[i].col=cols[k]
	end
end

function shuff(t)
	local n = #t
	while n > 1 do
		local k = flr(rnd(n)) + 1 -- get a random index from 1 to n
		local temp = t[n]         -- swap the current element with the random element
		t[n] = t[k]
		t[k] = temp
		n = n - 1                 -- decrement n to process the next element
	end
	return t
end

function to_stat(sym, n)
	local s = (sym and sym.col and sym.col[3]) or "none"
	-- map unknown roles to nothing (ignore) or add a canv.none if you want
	if s=="att" or s=="def" or s=="cash" or s=="heal" or s=="pois" then
		return {[s]=n}
	end
	return {} -- ignore "none"
end

-->8
--player
function initplr()
plr={
	on=false,
	hth=10,
	maxhth=10,
	cash=0,
	kills=0,
	col=cols.blu,
	w=2,
	h=3,
	state="idl",
	idx=1,
	lastidx=1,
	frames={
		idl={
		64
		},
		mov1={
			66,
			68,
			70,
			72,
			74
		},
		mov2={
			66,
			68,
			70,
			72,
			74
		},
		fx={
			active=false,
			idx=1,
			timer=0,
			mov1={192,192,194,196,198},
			off1={
				{2,8},{2,8},
				{4,9},{6,11},
				{7,10}
			},
		}
	}
}

rate=4
timer=rate
fx_init_actor(plr)

end

function set_state(s)
	if plr.state!=s then
		plr.state=s
		plr.idx=1
		timer=rate
	end
end

function start_fx()
	local fx=plr.frames.fx
	fx.active=true
	fx.idx=1
	fx.timer=rate
end

function updateplr()
	local pf=plr.frames
	plr.hth=min(plr.hth,plr.maxhth)
	plr.x=canv.x-25
	plr.y=canv.y+11
	timer-=1
	pf.fx.timer-=1
	
	if timer<=0 then
		if plr.idx >= #pf.mov1 then
			plr.idx=1
			plr.state="idl"
		else
		plr.idx+=1
		end
		timer=rate
	end
	
  if (not pf.fx.active) and 
  (plr.lastidx < 3) and 
  (plr.idx >= 3) then
    start_fx()
  end
	--fx
	local fx=pf.fx
	if fx.active then
		fx.timer -= 1
		if fx.timer <= 0 then
			fx.idx += 1
			if fx.idx > #fx.mov1 then
				-- finished
				fx.active=false
				fx.idx=1
				fx.timer=0
			else
				fx.timer = rate
			end
		end
	end
	
	-- remember last index for next tickヌ█▥s edge check
plr.lastidx = plr.idx
 if plr.dead then
  plr.y += plr.vy or 0
  plr.vy += 0.2
  return
end
fx_update(plr)
	fx_update(plr)

end

function drawplr()
	allcol(0)
	local s
	local fx=plr.frames.fx

	if plr.state=="idl" then
		s=plr.frames.idl
		if plr.idx > #s then plr.idx=1 end
	else
		s=plr.frames.mov1
	end
	for o in all(offs) do
		spr(s[plr.idx],plr.x+o[1],plr.y+o[2],2,3)
	end
	pal()
	pal({
		[7]=selected.col[1],-- chnge white to c
	})
	spr(s[plr.idx],plr.x,plr.y,2,3)
	if fx.active then
		spr(fx.mov1[fx.idx],
		plr.x+fx.off1[fx.idx][1],
		plr.y+fx.off1[fx.idx][2],2,3)
	end
	pal()
	drawbar(plr.x+2,plr.y+26,3,12,
	plr.hth,plr.maxhth)
	print("$"..plr.cash,1,1,cols.org[1])
	print("kills:"..plr.kills,40,1,cols.red[1])

end
-->8
--opp
function initopp()
	opp={
		x=105,
		y=56,
		s=79,
		w=cell,
		h=3*cell,
		sym={},
		sat=10,
		dead=false,
		hth=10,
		maxhth=10,
		weak=d6()<4,
		att=d6(),
		def=d6()
	}
	
	fx_init_actor(opp)
	oppsym()
	opp_turn = {
  pending=false,
  windup=12,   -- frames to telegraph
  ttl=0,
  dmg=0
}
	
end

-- pick a fresh opponent state
function opp_new()
	opp.att  = d6()
	opp.def  = d6()
end

-- pick the symbol from defs without mutating the def table
function oppsym()
	local sd = symdefs[d6()]
	-- minimal clone so we don't scribble on symdefs
	opp.sym = {s=sd.s, col=sd.col, name=sd.name, parts=sd.parts}
end

function updateopp()
  if opp.dead then
    opp.y += opp.vy or 0
    opp.vy += 0.4
    if opp.y > 150 then opp.y = 150 end
    return
  end

  -- always tick fx + opp turn state
  fx_update(opp)
  update_opp_turn()          -- <<< you were missing this call

  -- start turn once after player show resolves
  if turn_ready and not opp_turn.pending then
    start_opp_turn()
    turn_ready = false
  end
end

function updatesat()
--local match=0
--	for s in all(canv.syms) do
--		if s.name == opp.sym.name then
--			match+=1
--		end
--	end
--	opp.sat=match
end

function drawopp()
  local x,y = opp.x, opp.y

  -- compute fx offsets first
  local ox, oy = fx_offset(opp)
  local doflash = false

  -- telegraph lean during windup
  if opp_turn.pending and opp_turn.ttl > 0 then
    ox += 1
    if frame%2==0 then
      pal(7,10,1)
      doflash = true
    end
  end

  -- outline body (your big sprite)
  outline(0, opp.s, x+ox, y+oy, 1, 3)

  -- thought bubble
  outline(0, 206, x+ox+7, y+oy-15, 2, 2, true)

  -- preview sym (now uses offset)
  drawsym(opp.sym, x+ox+10, y+oy-14, true)

  -- 50/50 draw x (keeps your color tweak)
  if not opp.weak then
    if same(opp.sym.col, cols.red) then
      pal({[8]=13,[2]=13})
    end
    spr(239, x+ox+11, y+oy-14, 1,1,true)
    pal()
  end

  -- hp bar & text (use offset so ko fall is obvious)
  drawbar(x+ox-2, y+oy+29, 3, 12, opp.hth, opp.maxhth)
  print("hp:"..opp.hth, x+ox, y+oy+31)
  drawstats(opp)

  if doflash then pal() end
end


function start_opp_turn()
  if opp.dead then return end
  opp_turn.pending = true
  opp_turn.ttl     = opp_turn.windup
  -- base damage: use opp.att; subtract player's shield if u add one later
  opp_turn.dmg     = max(0, (opp.att or 0) - (plr.def or 0))
  -- optional: brief charge sound
  sfx(7)
end

function update_opp_turn()
  if not opp_turn.pending then return end
  if opp_turn.ttl > 0 then
    opp_turn.ttl -= 1
    return
  end

  -- resolve the hit
  local dmg = opp_turn.dmg or 0
  if dmg > 0 then
    plr.hth = max(0, (plr.hth or 0) - dmg)
    fx_start_hit(plr, dmg, 0)
  else
    -- whiff / no damage cue
    sfx(3)
  end

  -- ko check for player
  if plr.hth <= 0 and not plr.dead then
    plr.hth = 0
    plr.dead = true
    sfx(6)
    -- tiny toss if u want parity with opp ko
    plr.vy = -2
  end

  opp_turn.pending = false
end
-->8
--fx
-- attach fx state to any actor table (plr, opp, etc.)
function fx_init_actor(a)
  a.fx = {
    hit_frames   = 8,    -- shake duration
    flash_frames = 10,   -- hp-hit flicker duration
    shake_px     = 1,    -- shake intensity in pixels
    hit_ttl      = 0,
    flash_ttl    = 0
  }
end

-- start fx when the actor is attacked
-- dmg > 0  => hp actually lost (flash)
-- sh_absorb > 0 => shield absorbed (still shake)
function fx_start_hit(a, dmg, sh_absorb)
  if not a or not a.fx then return end
  if (dmg > 0) or (sh_absorb > 0) then
    a.fx.hit_ttl = a.fx.hit_frames
    sfx(dmg > 0 and 5 or 4)  -- pick your sfx ids
  end
  if dmg > 0 then
    a.fx.flash_ttl = a.fx.flash_frames
  end
end

-- tick down per frame (call in update_*)
function fx_update(a)
  if not a or not a.fx then return end
  if a.fx.hit_ttl   > 0 then a.fx.hit_ttl   -= 1 end
  if a.fx.flash_ttl > 0 then a.fx.flash_ttl -= 1 end
end

-- returns per-frame screen offset (shake)
function fx_offset(a)
  if not a or not a.fx or a.fx.hit_ttl <= 0 then return 0,0 end
  local t = (a.fx.hit_frames - a.fx.hit_ttl)
  local px = a.fx.shake_px or 1
  return flr(sin(t*2.3)*px), flr(cos(t*2.9)*px)
end

-- optional palette flash helpers (wrap your draw)
function fx_flash_begin(a)
  if not a or not a.fx then return false end
  if a.fx.flash_ttl > 0 and (frame%2==0) then
    -- tweak palette indices as you like
    pal(7,10,1)  -- mid -> bright
    pal(6, 7,1)
    return true
  end
  return false
end

function fx_flash_end(did)
  if did then pal() end
end

-- global particle list
particles = {}

-- update + draw all particles each frame
function update_particles()
	for p in all(particles) do
		p:update()
	end
end

function draw_particles()
	for p in all(particles) do
		p:draw()
	end
end


function spawn_streak(x,y,color)
  local ang=rnd()
  local spd=.7+rnd(3)         
  local dx,dy=cos(ang)*spd, sin(ang)*spd
  local g=0.3                 

  add(particles,{
    x=x, y=y, dx=dx, dy=dy, life=0, max=8+rnd(4),
    update=function(self)
      self.x+=self.dx
      self.y+=self.dy
      self.dy+=g
      self.dx*=0.8
      self.dy*=0.8
      self.life+=1
      if self.life>self.max then del(particles,self) end
    end,
    draw=function(self)
      -- short bright streak
      line(self.x,self.y,self.x-self.dx*.6,self.y-self.dy*.6,color)
    end
  })
end

function el(x,y,w,h,cols)
  local density = 0.24  
  local count = max(1, flr(w*h*density))
  for i=1,count do
    local px=x+rnd(w)
    local py=y+rnd(h)
    local c=rnd({cols[1], cols[2], cols[2]}) -- bias to col[1]/[2], less white
    spawn_streak(px,py,c)
  end
end
-- ヌあち ring burst (colorized)
function s(x,y,w,h)
  local c1 = 6 -- edge
  local c2 = 7  -- fill

  local cx=x+(w/2)-2
  local cy=y+(h/2)-2
  for i=1,1do
    local ang=rnd()
    local spd=0.46+rnd(0.4)
    local dx,dy=cos(ang)*spd,sin(ang)*spd
    add(particles,{
      x=cx, y=cy, dx=dx, dy=dy, r=2+rnd(2), life=0, max=12,
      update=function(self)
        self.x+=self.dx
        self.y+=self.dy
        self.r*=0.87
        self.life+=1
        if self.life>self.max or self.r<0.4 then del(particles,self) end
      end,
      draw=function(self)
        -- colored outline + fill (no hardcoded white)
        circ(self.x,self.y,self.r,c1)
        circfill(self.x,self.y,self.r*0.55,c2)
      end
    })
  end
end


-- use sym.col[1]/[2], plus a neutral fallback as 3rd
--function sym_colors(sym)
--  local c1 = (sym.col and sym.col[1]) or 7
--  local c2 = (sym.col and sym.col[2]) or 6
--  return {c1, c2, 7}
--end

-- bounding box in pixels for a (possibly multi-part) sym at (x,y)
function sym_bbox(sym, x, y)
  local parts = sym.parts or {{px=0, py=0}}
  local minx, miny =  32767,  32767
  local maxx, maxy = -32768, -32768
  for p in all(parts) do
    local px = x + p.px
    local py = y + p.py
    -- each part is 1 tile (cell れ❎ cell)
    minx = min(minx, px)
    miny = min(miny, py)
    maxx = max(maxx, px + cell)
    maxy = max(maxy, py + cell)
  end
  return minx, miny, (maxx - minx), (maxy - miny)
end

-->8
-- scanning

function init_fx()
	frame = 0
	trig_step_frames =3
	active_scans = active_scans or {}
	fxq = fxq or {}
	scan_fx_frames = 6  -- how many frames each scan cell stays visible
	-- how long the bump lasts + how far (in pixels)
	bump_frames = 6
	bump_dy = -1
	
	-- num -> ttl frames
	bumps = bumps or {}
	trig_post_frames = scan_fx_frames  -- wait this many frames after last pling
	decq = decq or {} 
	
	-- on-show scan/queue
	show_scan   = nil-- {ix,iy,cols,rows}
	show_seen   = nil-- map num->true (dedupe multi-cell syms)
	trig_q      = {}-- fifo of syms to trigger
	trig_curr   = nil-- currently triggering sym
	trig_epoch = 0
	show_fxq=show_fxq or {}-- boxes for on-show order only
 show_box_ttl=6-- same feel as scan_fx_frames
	
end

function start_cascade()
  trig_epoch += 1
end

function run_adj_effects(src, n)
  if not n then return end
  bump_group(n)
  for t in all(src.tags or {}) do
    if     t=="count_adj" then apply_eff(to_stat(src,1))
    elseif t=="score_adj" then apply_eff(eff_role(n))
    elseif t=="del_adj"   then del_group(n)
    elseif t=="refr_adj"  then n.trig=min((n.trig or 0)+1,1)              -- <=1 cap
    elseif t=="trig_adj"  then if n._epoch != trig_epoch then trig(n) end
    end
  end
end
function has_adj_tag(sym)
  for t in all(sym.tags or {}) do
    if
     t=="count_adj" or
     t=="score_adj" or
     t=="del_adj" or
     t=="trig_adj" or
     t=="refr_adj"then
      return true
    end
  end
  return false
end



-- make a quick map num->true for dedupe per runner
function mark_seen(seen, s)
  if s and s.num then
    if seen[s.num] then return true end
    seen[s.num]=true
  end
  return false
end

-- 1-frame fx ping for a cell
function fx_cell(x,y,hit)
  add(fxq, {
  x=x,
  y=y,
  hit=hit,
  ttl=scan_fx_frames})
  
    -- play a blip sfx on spawn
  if hit then
    sfx(0)   --paint sound - maybe diff sound  for hits
  else
    sfx(2)   --miss sound
  end
end

-- returns list of cells around sym we will "scan" in order,
-- each entry {x=..,y=..,hit=bool,ref=sym_or_nil}
-- unique perimeter scan around the whole sym (no self cells, no dups)
function build_scan(sym)
  local list = {}
  if not sym then return list end

  -- 1) collect occupied cells for this sym
  local occ = {} -- key "x:y" -> true
  local sp = sym.parts or {{px=0,py=0}}
  for p in all(sp) do
    local x = sym.x + p.px
    local y = sym.y + p.py
    occ[x..":"..y] = true
  end

  -- 2) collect occupied cells for other syms (for hit lookup)
  local others = {} -- key "x:y" -> ref (neighbor sym)
  for c in all(canv.syms) do
    if c ~= sym and not (sym.num and c.num and sym.num==c.num) then
      local cp = c.parts or {{px=0,py=0}}
      for q in all(cp) do
        local x = c.x + q.px
        local y = c.y + q.py
        -- only record first ref; enough for hits
        local k = x..":"..y
        if not others[k] then others[k] = c end
      end
    end
  end

  -- 3) perimeter = neighbors of our occupied cells, excluding our own cells, deduped
  local seen = {} -- perimeter de-dupe
  local dirs = {{cell,0},{-cell,0},{0,cell},{0,-cell}}
  for p in all(sp) do
    local ax = sym.x + p.px
    local ay = sym.y + p.py
    for d in all(dirs) do
      local x = ax + d[1]
      local y = ay + d[2]
      local k = x..":"..y
      -- skip our own body; only push each perimeter cell once
    if in_canvas_local(x, y) and not occ[k] and not seen[k] then
        local ref = others[k] -- hit if a neighbor occupies that cell
        add(list, {x=x, y=y, hit=(ref!=nil), ref=ref})
        seen[k] = true
      end
    end
  end

  return list
end


-- opts.preview: visualize only (no state change, no trig--)
-- opts.reason : "on_add"|"manual"|"on_show" (optional)
function trig(sym)
  if not sym then return end
  
   if sym._epoch == trig_epoch then
    sym._trig_done = true
    return
  end
  sym._epoch = trig_epoch
  sym._trig_done = false
  

  local trigv = sym.trig or 1
  if trigv <= 0 then
    -- nothing to do: mark done so the queue advances
    sym._trig_done = true
    return
  end

  local role = (sym.col and sym.col[3]) or "none"

  if has_adj_tag(sym) then
    local list = build_scan(sym)

    if sym.inst then
      -- instant path
      pling_scan(list)

      local seen = {}

      for c in all(list) do
        if c.hit then
          local n = c.ref
          local key = (n and n.num) or n
          if not seen[key] then
									run_adj_effects(sym, n)
            seen[key] = true
          end
        end
      end

      sym.trig = max(0, trigv-1)
      sym._trig_done = true      -- <<< ensure done on instant path
      return
    end

    -- slow (phased) path
    add(active_scans, {
      sym=sym, role=role, list=list, idx=1,
      seen={}, done=false, bumped={}
    })
    return                         -- <<< done flag set when runner finishes
  else
    -- self (no-adj) path
    local size = (sym.parts and #sym.parts>0) and #sym.parts or 1
    fx_cell(sym.x, sym.y, true)
    apply_eff(to_stat(sym, size))
    sym.trig = max(0, trigv-1)
    sym._trig_done = true          -- <<< ensure done on self path
    return
  end
end


function update_scans()
  -- call inside _update()
  if (#active_scans==0) return

  -- gate by frame pacing
  if (frame%trig_step_frames)!=0 then return end

  for r in all(active_scans) do
    local cell = r.list[r.idx]
    if not cell then r.done=true goto _cont end

    -- draw fx for this cell
    fx_cell(cell.x, cell.y, cell.hit)

    -- apply effect if it's a hit and not preview
	if cell.hit and not r.preview then
	  local n = cell.ref
	   if not mark_seen(r.seen, n) then
    run_adj_effects(r.sym, n)
  end
	end

    r.idx += 1
    if r.idx>#r.list then r.done=true end
    ::_cont::
  end

  -- cleanup + decrement trig
for i=#active_scans,1,-1 do
  local r = active_scans[i]
  if r.done then
    if r.want_refr then refr_adj(r.sym, 1) end  -- arm neighbors now
    if not r.preview then
      r.sym.trig = max(0,(r.sym.trig or 1)-1)
    end
    r.sym._trig_done = true
    deli(active_scans,i)
  end
end

end

function draw_fx()
  local cx, cy = canv.x, canv.y
  local cw, ch = canv.w, canv.h

  -- 1) instant path fx (miss-only s())
  for i=#fxq,1,-1 do
    local f = fxq[i]
    local gx, gy = cx + f.x, cy + f.y
    if gx>=cx and gy>=cy and gx+cell<=cx+cw and gy+cell<=cy+ch then
      if not f.hit then
        -- instant placement: show s() for miss only
        s(gx, gy, cell, cell)
      end
    end
    f.ttl -= 1
    if f.ttl<=0 then deli(fxq,i) end
  end

  -- 2) on-show order boxes (one per cell, green hit / red miss)
  for i=#show_fxq,1,-1 do
    local f = show_fxq[i]
    local gx, gy = cx + f.x, cy + f.y
    if gx>=cx and gy>=cy and gx+cell<=cx+cw and gy+cell<=cy+ch then
      -- if your s() supports color as a 5th arg, pass it; else wrap with pal()
  					spr(3, gx, gy)                   -- sprite 2 for missed cell
    end
    f.ttl -= 1
    if f.ttl<=0 then deli(show_fxq,i) end
  end
end

function pling_scan(list)
  for c in all(list) do
    fx_cell(c.x, c.y, c.hit) -- fx_cell already converts to canvas-local + uses scan_fx_frames
  end
end

function del_group(ref)
  if not ref or not ref.num then return end
  for i=#canv.syms,1,-1 do
    local s=canv.syms[i]
    if s and s.num==ref.num then deli(canv.syms,i) end
  end
end

function refr_adj(sym, amt)
  if not sym then return end
  amt = amt or 1
  local nbrs = adjsym(sym)
  local seen = {}
  for n in all(nbrs) do
    local key = n.num or n
    if not seen[key] then
      seen[key] = true
      n.trig = min((n.trig or 0)+amt,1)
      -- optional mini ping:
      -- fx_cell(n.x, n.y, true)
    end
  end
end

function bump_group(ref)
  if not ref or not ref.num then return end
  bumps[ref.num] = bump_frames
end

function update_bumps()
  -- call this once per _update/_update60
  for k,v in pairs(bumps) do
    v -= 1
    if v <= 0 then bumps[k]=nil else bumps[k]=v end
  end
end

function sym_at_cell(ix, iy)
  local px, py = ix*cell, iy*cell
  for s in all(canv.syms) do
    if s.x==px and s.y==py then return s end
  end
end

function build_onshow_scan()
  show_scan = {
    ix=0, iy=0,
    cols=flr(canv.w/cell),
    rows=flr(canv.h/cell)
  }
  show_seen = {}
  trig_q    = {}
  trig_curr = nil
end


function onshow_tick()
	-- if one is running, wait until it marks done
	if trig_curr then
		if trig_curr._trig_done then
			trig_curr = nil
		else
			return -- still running, don't scan/enqueue or start next
		end
	end
	
	-- no active sym: if queue has items, start next
	if #trig_q > 0 then
		trig_curr = deli(trig_q, 1)
		trig_curr._trig_done = false
		start_cascade()
		trig(trig_curr) -- trig(sym) must set _trig_done=true when finished
		return
	end
	
	-- no active + empty queue: advance scan by exactly one cell
-- no active + empty queue: advance scan by exactly one cell
if show_scan then
  if (frame % trig_step_frames) != 0 then return end

  local ix,iy = show_scan.ix, show_scan.iy
  local s = sym_at_cell(ix, iy)

  local will_trigger = false
  if s then
    local key = s.num or s
    if (s.trig or 0) > 0 and not show_seen[key] then
      will_trigger = true
      add(trig_q, s)
      show_seen[key] = true
    end
  end

  -- draw sprite 2 for empties or exhausted / already-queued cells
  if not will_trigger then
    fx_show_cell(ix*cell, iy*cell, false)  -- plays sfx(3) and queues sprite 2
  end

  -- step scan head (row-major)
  ix += 1
  if ix >= show_scan.cols then ix=0 iy+=1 end
  show_scan.ix, show_scan.iy = ix, iy

  if iy >= show_scan.rows then
    show_scan = nil
  end
end
  -- === all done gate ===
  if onshow_pending
  and show_scan == nil
  and not trig_curr
  and #trig_q == 0
  and #active_scans == 0 then
  	local raw = canv.att
			local sh  = opp.def
			local dmg = max(0,raw-sh)
			local sh_absorb = min(raw, sh)

			
	

    
    -- final, post-sequence stats (now theyre correct)
			opp.def = max(0,sh-raw)
			opp.hth -= dmg
			
			fx_start_hit(opp, dmg, sh_absorb)  -- <ヌ█⬆️ one line

		if opp.weak then
			if same(selected.name,opp.sym.name) then
			opp.hth-=2
			end
		end
    
    add(shown, {
      w    = (canv.w/cell),
      h    = (canv.h/cell),
      syms = deepcopy(canv.syms),  -- optional: keep a copy
      att  = canv.att or 0,
      def  = canv.def or 0
    })
  -- === ko check ===
  if opp.hth <= 0 and not opp.dead then
    opp.hth = 0
    opp.dead = true
    sfx(6)               
    
    opp.vy = -2          -- upward kick
    opp.fx.hit_ttl = 0   -- stop shaking
    opp.fx.flash_ttl = 0
  end

    -- reset 4 next turn
    canv.syms = {}
    canv.att = 0
    canv.def = 0

    onshow_pending = false
			turn_ready = true
						plr.hth+=2

  end
end


function in_canvas_local(x, y)
	return x >= 0 and 
	y >= 0 and x + cell <= canv.w 
	and y + cell <= canv.h
end

function fx_show_cell(x,y,hit)
  add(show_fxq, {x=x, y=y, hit=hit, ttl=show_box_ttl})
  if not hit then sfx(3) end -- red/miss sound only for on-show
end
__gfx__
00000000077000000666666000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000076770000600000060600000607000000000000000000000000000000000000000000000000000000075700000057000000000a000000700000000000
00000000707f000060000006006000600700000000000000000000000000000000000000000000000000000000776766000770000000a0000000500000770700
000000000004f00060000006000606006777600000000000000000000000000000000000000000000000000007000007000077000000a0000000700000777700
0000000000004f006000000600006000677760000000000000000000000000000000000000000000000000000006767600007700000777000007700000777700
0000000000000ff06000000600060600677760000000000000000000000000000000000000000000000000000070000000007700000777000007500000077000
00000000000004ff6000000600600060077660000000000000000000000000000000000000000000000000000067676700077000000777000005700000077000
000000000000004f0666666006000006000000000000000000000000000000000000000000000000000000000000000700070000000777000007700000077000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000007700000077000
00000000077770000005600000077700006777600770007700007076077000770008080000080800007000700070007000000000000770000007500000077000
00000000070777700007760000770770067777760067776000070760706777600000778000007780007707700077077000000000007777000005700000077000
00000000077766770007776006777776060666060077777000077600007777700007570000075700077777770700700700770000007777000007700000077000
00000000007677670067777607676767066707660070707000707760007070700aa777000aa77700075575570700700700077000077777700007700000077000
00000000007667770066777606767676000777000067776007777760006777600007770000077700077575770077577000077700077777700007500000077000
00000000076777770066777600676760006000600007070007777660000707000088000000887700007757700007770000007700077777700005700000077000
00000000000000000006666000066600000777000006660000666600000676000088000000887770000777000000000000007770007777000007700000077000
00000000000000000000000000000000000000000000000000000000000667770000000007777770000666700000000000007770000000000007700000077000
00000000000000000033500000003000000050000000707707777000000677777000000007777677000777777000777000007770000000000007500000077000
0000000000006000007777600000300000e75e700007077077777700000677777700007007777677000777777700007700007700000770000075770000077000
0000000000777706077e777600030300067767700007770776667677000677766700000707777767000777777700000700077700000770000557777000077000
00000000070777660777777600030030066666000070777767777777000670667770000700777770000776776770007700077000007777000777775000777700
0000000007777606067777660e70000300e76e7007777777677777000006700677700070000a0a00000776767770077000770000005775000777557000777700
000000000006060000677660077000e70077677007777677667777000006700067777700000a0a00000776767777770000700000007777000075770000707700
00000000000000000006660000000077000660000007677077777700006770077770000000a4aaa0007676677770000000000000000770000007700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000007700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000750000007500000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000570000005700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000775777577700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077577757000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000009999000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000009944000000000000999900007000000099990007000000000000000000000000000000000000000000000000000000000000000000000000004440000
0000009944400000000000099440007000000009944000f00000000000000000000000000000000000000099990000000000000000000000000000000fff4000
000000990400000000000099444000f000000099444000f000000000000000000000000000000000000009944900000000000000000000000000000005f5f000
000000994440000000000099040000f000000099040004400000009999000000000000999900000000000944450000000000000000000000000000000ffff000
0000009999500000000000994440044000000099444090f000000994490000000000099449000000000009040500000000000000000000000000000000ff0000
000009999959000000000999995990f0000009999959900000000944450050000000094445000000000009444590000000000000000000000000000001ff1000
00009999999900000000099999959000000009999959000000000904095500000000090405900000000009999590000000000000000000000000000016061110
00009999999900000000099999990000000009999999000000000944499000000000094445900000000009995999000000000000000000000000000016061110
00009999999900000000099999990000000009999999000000000999999900000000099995990000000099999999900000000000000000000000000016061110
00099999999900000000099999990000000009999999000000009999999990000000999995999000000099999999900000000000000000000000000016061110
00099999999900000000099999990000000009999999000000009999999999000000999999999900000999999990990000000000000000000000000016061110
00049999999900000000099999990000000009999999000000099999999099900009999999909990009999999990990000000000000000000000000016061110
0ff4ff79999900000000099999990000000009999999000000999999999009900099999999900990009909999990990000000000000000000000000016061110
000009979ff90000000009999ff90000000009999ff90000009909999990000000990999999000000f4009999ff0000000000000000000000000000016661110
00000ffffff0000000000ffffff0000000000ffffff0000000f009999fff000000f009999fff000000400ffffff000000000000000000000000000001d661110
00000ffffff0000000000fff0fff000000000fff0fff000000400fff00fff00000400fff00fff00000f00fff0fff0000000000000000000000000000fddd1110
00000ffffff0000000000fff0fff000000000fff0fff000000f00fff00fff00000f00fff00fff000000f0fff0fff00000000000000000000000000000dd0dff0
00000ffffff0000000000fff0fff000000000fff0fff000000f00fff0fff000000f00fff0fff000000070fff0fff00000000000000000000000000000dd0dd00
00000fff0400000000000fff0040000000000fff0040000000770fff0040000000700fff0040000000700fff004000000000000000000000000000000dd0dd00
0000004009900000000000400099000000000040009900000000004000990000007000400099000000000040009900000000000000000000000000000dd0dd00
0000009000000000000000900000000000000090000000000000009000000000000000900000000000000090000000000000000000000000000000000dd0dd00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550dd00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000000000000000000000000000000000007000000000000000700000000000000000000000000000000000077777770000
00000000000000770000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000777777777000
00000000000007770000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000007777777777700
00000000000007770000000000000007000000000000000700000000000000000007700000000000000070000000000000700000000000000067777777777760
00000000000077770000000000000007000000000000000000000000000000000000777000000000000000000000000000000000000000000067777777777760
00000000000777770000000000000007000000000000000000000000000000700000077700000000000000000000000000000000000000000067777777777760
00000000077777700000000000000007000000000000000000000000000000000000007770000000000000007000000000000000000000000067777777777760
00000000777777000000000000000070000000000000000000000000000000000000000777700000000000000000000000000000000000000067777777777760
00000077777770000000000000000700000000000000000700000000000000000000000007770000000000000070000000000000000000000006777777777600
00077777777700000000000000000700000000000000700000000000000000000000000000777000000000000007000000000000000070000000677777776000
77777777770000000000000000007000000000000000000000000000000000070000000000007000000000000000770000000000000000000000066666660000
07777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000000000007070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000007700
00000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600
00000000000000007777770000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007000700000000000000000000000000000000000000000000000000000000000000000000000006
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800080
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800080
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111777777777777777177777777777777711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766600666006665176660000666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111117660aa000aa066517660bbbb006666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766609aaa90666517660b0bbbb0666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111176660aaaaa0666517660bbb33bb066511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111176660a0a0a06665176660b3bb3b066511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766609aaa906665176660b33bbb066511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766660a0a06666517660b3bbbbb066511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766660999066665176660000000666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666000666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111755555555555555175555555555555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111777777777777777155555555555555711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665156666666666666711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666666666665156666666666666711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766666000666665156666660600666711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766660ccc06666515666660b0b3066711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111176660cc0cc066651566660b0b30666711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111176601ccccc106651566660bb306666711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111117660c1c1c1c0665156660b0bb30666711111111111111111111111111111111111111111111111111111111111111111111111100111111111111111
1111111176601c1c1c1066515660bbbbb306667111111111111111111111111111111110000000000000000000000000001111111111110bb011111111111111
11111111766601c1c10666515660bbbb3306667111111111111111111111111111111110bbbbbbbbb55555555555555550111111111110b3bb01111111111111
111111117666601110666651566603333066667111111111111111111111111111111110bbbbbbbbb55555555555555550111111111110b0bf01111111111111
111111117666660006666651566660000666667111111111111111111111111111111110bbbbbbbbb555555555555555501111111111110104f0111111111111
1111111176666666666666515666666666666671111111111111111111111111111111100000000000000000000000000011111111111111104f011111111111
1111111176666666666666515666666666666671111111111111111111111111111111111111111111111111111111111111111111111111110ff01111111111
11111111755555555555555177777777777777711111111111111111111111111111111111111111111111111111111111111111111111111104ff0111111111
111111111111111111111111111111111111111111111111111111111111111111111117777777777777777777777777771111111111111111104f0111111111
11111111777777777777777177777777777777711111111111111111111111111111111777700077777707007000077777111111111111111111001111111111
111111117666666666666651766666666666665111111111111111111111111111111117770ccc077770b0bb0bbbb07777111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111770cc0cc0770b0bb0bbbbbb0077111111111111111111111111111111
11111111766666006666665176666660666666511111111111111111111111111111111701ccccc1070bbb0bb333b3bb07111111111111111111111111111111
1111111176666056066666517666600500666651111111111111111111111111111111170c1c1c1c00b0bbbb3bbbbbbb07111111111111111111111111111111
11111111766660776066665176660795790666511111111111111111111111111111111701c1c1c10bbbbbbb3bbbbb0077111111111111111111111111111111
111111117666607776066651766049949906665111111111111111111111111111111117701c1c100bbbb3bb33bbbb0777111111111111111111111111111111
11111111766606777760665176604444406666511111111111111111111111111111111777011107700b3bb0bbbbbb0077111111111111111111111111111111
11111111766606677760665176660794790666511111111111111111111111111111111770000077777000070000000a07111111111111111111111111111111
1111111176660667776066517666099499066651111111111111111111110000111111170bbbb007770ccc070aa000aa07111111111111111111111111111111
1111111176666066660666517666604400666651111111111111111111109999011111170b0bbbb070cc0cc0a09aaa9077111111111111111111111111111111
1111111176666600006666517666660066666651111111111111111111109944011111170bbb33bb01ccccc100aaaaa077111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111110994440111111770b3bb3b0c1c1c1c00a0a0a077111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111110990401111111770b33bbb01c1c1c1009aaa9077111111111111111111111111111111
1111111175555555555555517555555555555551111111111111111111099444011111170b3bbbbb001c1c10770a0a0777111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111110999950111111770000000770111077709a90077111111111111111111111111111111
111111117777777777777771777777777777777111111111111111111099999590111117777000777000007777099aaa07111111111111111111111111111111
111111117666666666666651766666666666665111111111111111110999999990111117770ccc070bbbb0077709aaaaa0111101111111111111111111111111
11111111766666666666665176666666666666511111111111111111099999999011111770cc0cc00b0bbbb07709aaaaaa0110a0111111111111111111111111
11111111766666666666665176666000006666511111111111111111099999999011111701ccccc10bbb33bb0709aaa99a01110a011111111111111111111111
1111111176666660666666517666067776066651111111111111111099999999901111170c1c1c1c00b3bb3b0709a099aaa0110a011111111111111111111111
11111111766660040606665176606777776066511111111111111110999999999011111701c1c1c100b33bbb0709a009aaa000a0111111111111111111111111
111111117666099990406651766060666060665111111111111111004999999990111117701c1c100b3bbbbb0709a0709aaaaa01111111111111111111111111
111111117660909994406651766066707660665111111111111110ff4ffb9999901111177701110770000000709aa00aaaa00011111111111111111111111111
111111117660999940406651766600777006665111111111111111000099b9ff9011111770000077700007777700077000011111111111111111111111111111
1111111176660040400666517666060006066651111111111111111110ffffff011111170bbbb0070bbbb0077777777777111111111111111111111111111111
1111111176666606066666517666607770666651111111111111111110ffffff011111170b0bbbb00b0bbbb07777777777111111111111111111111111111111
1111111176666666666666517666660006666651111111111111111110ffffff011111170bbb33bb0bbb33bb0777777777111111111111111111111111111111
1111111176666666666666517666666666666651111111111111111110ffffff0111111770b3bb3b00b3bb3b0777777777111111111111111111111111111111
1111111176666666666666517666666666666651111111111111111110fff0401111111770b33bbb00b33bbb0777777777111111111111111111111111111111
1111111175555555555555517555555555555551111111111111111111040099011111170b3bbbbb0b3bbbbb0777777777111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111110901001111111770000000700000007777777777111111111111111111111111111111
11111111777777777777777177777777777777711111111111111111111011111111111777777777777777777777777777111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111777777777777777777777777777111111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766660006666665176666660666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111766603350066665176666603066666511111111111111111111111111111177777777777777777777777777777771111111111111111111111111111
11111111766609999406665176666603066666511111111111111111111111111111176666666666666666666666666666651111111111111111111111111111
11111111766099799940665176666030306666511111111111111111111111111111176666666600606066006060666666651111111111111111111111111111
11111111766099999940665176660030030666511111111111111111111111111111176666666066606060606060666666651111111111111111111111111111
11111111766049999440665176607a06603066511111111111111111111111111111176666666000600060606060666666651111111111111111111111111111
1111111176660499440666517660aa0607a066511111111111111111111111111111176666666660606060606000666666651111111111111111111111111111
111111117666604440666651766600660aa066511111111111111111111111111111176666666006606060066000666666651111111111111111111111111111
11111111766666000666665176666666600666511111111111111111111111111111176666666666666666666666666666651111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111175555555555555555555555555555551111111111111111111111111111
11111111766666666666665176666666666666511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111755555555555555175555555555555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111100111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111110111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111110111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111110111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111100011111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__map__
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9393939393939393939393939393939392929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9292929292929292929292929292929292929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9292929292929292929292929292929292929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9292929292929292929292929292929292929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9292929292929292929292929292929292929292929292929292929292929292929292929292929200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000127101372015740187501d74024720297103e7002a000300001e0000c000120003f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000311005120031100010000100031000110001100000000210000000161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000610046200462004620036100260002600106000e6000e6000b600076000460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000a7100a7200a7300a74009750097600876008760067600576005750007400073000720007100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f9400f1400d1300691014100111000410002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001a870249700c870209700887022970209701d9700887018960058600f9600d9200e900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ee500de5007a500ee501ea501fa501fa501fa501fa501fa5006a5022e5008e5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003082030800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
