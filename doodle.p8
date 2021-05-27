pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- sasha kuechenmeister
-- & raphael ofeimu

-- game:
-- doodle jump-8

cartdata("doodlejump8")
mx1=(dget(0) or 0)
mx2=(dget(1) or 0)

function _init()
 g_time=0
 reg={}
 reset()
 time()
end


function reset()
 g_id=1 entity_reset() set_e(1) restart()
 g_id=2 entity_reset() set_e(2) restart()
end

function update()
 e_update_all()
 do_movement()
 do_collisions()
 do_supports()
 if scheduled then
  scheduled()
  scheduled=nil
 end
end


function _update60()
 set_e(1) update()
 set_e(2) update()
 g_time+=1
end


function r(s)
 s=s..""
 
 while #s<5 do
  s="0"..s
 end
 
 return s
end

function grid()
 local s=32

end

function _draw()
 cls(3)
 set_e(1)
 clip(0,0,128,128)
 camera()
 grid()
 
 r_render_all("render")
 borderprint("sasha kuechenmeister",2,113,13)
 borderprint("& raphael ofeimu",2,121,13)
 line(0,mx1,32,mx1,1)
 
 borderprint("record",6,mx1-7,8)
	if not g_start then
  if not btn(❎) then
   borderprint("❎ to start",43,60)
  end
 end
	
 camera()
 print(r(g_guy[1].score),2,2)
 r_render_all("render_hud")
 if btn(❎) then
  g_start=true
 end
 

 if g_guy[1].done then
 	gameoverprint("!gameover!",45,30)
 	rsprint("press 🅾️ to restart",27,80)
 	borderprint("your score:",43,50)
 	borderprint(r(g_guy[1].score),55,60)
 	if btn(🅾️) then
 	reset()
 	end
 end
end


 


function restart()
g_start=false
 e_add(guy({
  pos=v(60,92)
 }))
 
 l=60
 
 for i=0,4 do
  e_add(platform({
   pos=v(i>0 and l or 60,100-i*30),
   tile=0 --starting position
  }))
  e_add(platform({
   pos=v(flr(rnd(100))+10,90-i*80),
   tile=gen_type(),
   second=true
  }))
  gen_pos()
 end
 
 e_add(cam())
end

function gen_pos()
 local r
 if l>50 then
  r=l-rnd(24)
 elseif l<12 then
  r=l+rnd(24) 
 else 
  r=l+rnd(48)-24
 end
 l=mid(2,53,r)
end

function gen_type()
 local r=rnd()
 if r<.5 then
  return 0
 elseif r<.6 then
  return 16
 elseif r<.7 then
  return 2 
 else
  return 32 
 end
end

function borderprint(s,x,y,c)
 print(s,x-1,y,c)
 print(s,x+1,y,c)
 print(s,x,y-1,c)
 print(s,x,y+1,c)
 print(s,x,y,7)
end

function gameoverprint(s,x,y,c)
 print(s,x-1,y,0)
 print(s,x+1,y,0)
 print(s,x,y-1,0)
 print(s,x,y+1,0)
 print(s,x,y,8)
end

function rsprint(s,x,y,c)
 print(s,x-1,y,0)
 print(s,x+1,y,0)
 print(s,x,y-1,0)
 print(s,x,y+1,0)
 print(s,x,y,11)
end

function deep_copy(obj)
 if (type(obj)~="table") return obj
 local cpy={}
 setmetatable(cpy,getmetatable(obj))
 for k,v in pairs(obj) do
  cpy[k]=deep_copy(v)
 end
 return cpy
end

function index_add(idx,prop,elem)
 if (not idx[prop]) idx[prop]={}
 add(idx[prop],elem)
end

function event(e,evt,p1,p2)
 local fn=e[evt]
 if fn then
  return fn(e,p1,p2)
 end
end

function state_dependent(e,prop)
 local p=e[prop]
 if (not p) return nil
 if type(p)=="table" and p[e.state] then
  p=p[e.state]
 end
 if type(p)=="table" and p[1] then
  p=p[1]
 end
 return p
end

function round(x)
 return flr(x+0.5)
end

-------------------------------
-- objects
-------------------------------

object={}
 function object:extend(kob)
  -- printh(type(kob))
  if (kob and type(kob)=="string") kob=parse(kob)
  kob=kob or {}
  kob.extends=self
  return setmetatable(kob,{
   __index=self,
   __call=function(self,ob)
       ob=setmetatable(ob or {},{__index=kob})
       local ko,init_fn=kob
       while ko do
        if ko.init and ko.init~=init_fn then
         init_fn=ko.init
         init_fn(ob)
        end
        ko=ko.extends
       end
       return ob
      end
  })
 end
 
-------------------------------
-- vectors
-------------------------------

vector={}
vector.__index=vector
 function vector:__add(b)
  return v(self.x+b.x,self.y+b.y)
 end
 function vector:__sub(b)
  return v(self.x-b.x,self.y-b.y)
 end
 function vector:__mul(m)
  return v(self.x*m,self.y*m)
 end
 function vector:__div(d)
  return v(self.x/d,self.y/d)
 end
 function vector:__unm()
  return v(-self.x,-self.y)
 end
 function vector:dot(v2)
  return self.x*v2.x+self.y*v2.y
 end
 function vector:norm()
  return self/sqrt(#self)
 end
 function vector:len()
  return sqrt(#self)
 end
 function vector:__len()
  return self.x^2+self.y^2
 end
 function vector:str()
  return self.x..","..self.y
 end

function v(x,y)
 return setmetatable({
  x=x,y=y
 },vector)
end

-------------------------------
-- collision boxes
-------------------------------

cbox=object:extend()

 function cbox:translate(v)
  return cbox({
   xl=self.xl+v.x,
   yt=self.yt+v.y,
   xr=self.xr+v.x,
   yb=self.yb+v.y
  })
 end

 function cbox:overlaps(b)
  return
   self.xr>b.xl and
   b.xr>self.xl and
   self.yb>b.yt and
   b.yb>self.yt
 end

 function cbox:sepv(b,allowed)
  local candidates={
   v(b.xl-self.xr,0),
   v(b.xr-self.xl,0),
   v(0,b.yt-self.yb),
   v(0,b.yb-self.yt)
  }
  if type(allowed)~="table" then
   allowed={true,true,true,true}
  end
  local ml,mv=32767
  for d,v in pairs(candidates) do
   if allowed[d] and #v<ml then
    ml,mv=#v,v
   end
  end
  return mv
 end
 
 function cbox:str()
  return self.xl..","..self.yt..":"..self.xr..","..self.yb
 end

function box(xl,yt,xr,yb) 
 return cbox({
  xl=min(xl,xr),xr=max(xl,xr),
  yt=min(yt,yb),yb=max(yt,yb)
 })
end

function vbox(v1,v2)
 return box(v1.x,v1.y,v2.x,v2.y)
end

-------------------------------
-- entities
-------------------------------

entity=object:extend({
 state="idle",t=0,
 last_state="idle",
 dynamic=true,
 spawns={}
})

 function entity:init()
  if self.sprite then
   self.sprite=deep_copy(self.sprite)
   if not self.render then
    self.render=spr_render
   end
  end
 end
 
 function entity:become(state)
  if state~=self.state then
   self.last_state=self.state
   self.state,self.t=state,0
  end
 end
 
 function entity:is_a(tag)
  if (not self.tags) return false
  for i=1,#self.tags do
   if (self.tags[i]==tag) return true
  end
  return false
 end
 
 function entity:spawns_from(...)
  for tile in all({...}) do
   entity.spawns[tile]=self
  end
 end

static=entity:extend({
 dynamic=false
})

function spr_render(e)
 local s,p=e.sprite,e.pos

 function s_get(prop,dflt)
  local st=s[e.state]
  if (st~=nil and st[prop]~=nil) return st[prop]
  if (s[prop]~=nil) return s[prop]
  return dflt
 end

 local sp=p+s_get("offset",v(0,0))

 local w,h=
  s.width or 1,s.height or 1

 local flip_x=false
 local frames=s[e.state] or s.idle
 if s.turns then
  if e.facing=="up" then
   frames=frames.u
  elseif e.facing=="down" then
   frames=frames.d
  else
   frames=frames.r
  end
  flip_x=(e.facing=="left")
 end
 if s_get("flips") then
  flip_x=e.flipped
 end

 local delay=frames.delay or 1
 if (type(frames)~="table") frames={frames}
 local frm_index=flr(e.t/delay) % #frames + 1
 local frm=frames[frm_index]
 local f=(e.bold and ospr or spr)
 f(e.exr_sprite or frm,round(sp.x),round(sp.y),w,h,flip_x,false,e.clr)

 return frm_index
end

-------------------------------
-- entity registry
-------------------------------


function entity_reset()
 local r={}
 r.entities,
 r.entities_with,
 r.entities_tagged,
 r.c_buckets={},{},{},{}
 
 reg[g_id]=r
end

function set_e(i)
 g_id=i
 entities=reg[i].entities
 entities_with=reg[i].entities_with
 entities_tagged=reg[i].entities_tagged
 c_buckets=reg[i].c_buckets
end

function e_add(e)
 add(entities,e)
 for p in all(indexed_properties) do
  if (e[p]) index_add(entities_with,p,e)
 end
 if e.tags then
  for t in all(e.tags) do
   index_add(entities_tagged,t,e)
  end
  c_update_bucket(e)
 end
 return e
end

function e_remove(e)
 del(entities,e)
 for p in all(indexed_properties) do
  if (e[p]) del(entities_with[p],e)
 end
 if e.tags then
  for t in all(e.tags) do
   del(entities_tagged[t],e)
   if e.bkt then
    del(c_bucket(t,e.bkt.x,e.bkt.y),e)
   end
  end
 end
 e.bkt=nil
end

indexed_properties={
 "dynamic",
 "render","render_hud",
 "vel",
 "collides_with",
 "feetbox"
}
-->8
-- systems

-------------------------------
-- update system
-------------------------------

function e_update_all()
 for ent in all(entities_with.dynamic) do
  local state=ent.state
  if ent[state] then
   ent[state](ent,ent.t)
  end
  if ent.done and not ent.ign then
   e_remove(ent)
  elseif state~=ent.state then
   ent.t=0
  else
   ent.t+=1
  end  
 end
end

function schedule(fn)
 scheduled=fn
end

-------------------------------
-- render system
-------------------------------

function r_render_all(prop)
 local drawables={}
 for ent in all(entities_with[prop]) do
  local order=ent.draw_order or 0
  if not drawables[order] then
   drawables[order]={}
  end
  add(drawables[order],ent)  
 end
 for o=0,15 do  
  for ent in all(drawables[o]) do
   r_reset(prop)
   ent[prop](ent,ent.pos)
  end
 end
end

function ospr(s,x,y,w,h,fx,fy,o)
 for i=0,15 do pal(i,o or 0) end
 spr(s,x-1,y,w,h,fx,fy)
 spr(s,x+1,y,w,h,fx,fy)
 spr(s,x,y-1,w,h,fx,fy)
 spr(s,x,y+1,w,h,fx,fy)
 r_reset()
 spr(s,x,y,w,h,fx,fy)
end

function r_reset(prop)
 pal()
 palt(0,false)
 palt(15,true)
 if (prop~="render_hud" and g_cam[g_id]) g_cam[g_id]:set()
end

-------------------------------
-- movement system
-------------------------------

function do_movement()
 for ent in all(entities_with.vel) do
  local ev=ent.vel
  ent.pos+=ev
  if ev.x~=0 then
   ent.flipped=ev.x<0
  end
  --if ev.x~=0 and abs(ev.x)>abs(ev.y) then
  
  if ev.x>0 then
   ent.facing="right"
  elseif ev.x<0 then
   ent.facing="left"
  end
   --ent.facing=
   -- ev.x>0 and "right" or "left"
  --elseif ev.y~=0 then
  -- ent.facing=
   -- ev.y>0 and "down" or "up"
  --end
  if (ent.weight) then
   local w=state_dependent(ent,"weight")
   ent.vel+=v(0,w)
  end
 end
end

-------------------------------
-- collision
-------------------------------

function c_bkt_coords(e)
 local p=e.pos
 return flr(shr(p.x,4)),flr(shr(p.y,4))
end

function c_bucket(t,x,y)
 local key=t..":"..x..","..y
 if not c_buckets[key] then
  c_buckets[key]={}
 end
 return c_buckets[key]
end

function c_update_buckets()
 for e in all(entities_with.dynamic) do
  c_update_bucket(e)
 end
end

function c_update_bucket(e)
 if (not e.pos or not e.tags) return 
 local bx,by=c_bkt_coords(e)
 if not e.bkt or e.bkt.x~=bx or e.bkt.y~=by then
  if e.bkt then
   for t in all(e.tags) do
    local old=c_bucket(t,e.bkt.x,e.bkt.y)
    del(old,e)
   end
  end
  e.bkt=v(bx,by)  
  for t in all(e.tags) do
   add(c_bucket(t,bx,by),e) 
  end
 end
end

function c_potentials(e,tag)
 local cx,cy=c_bkt_coords(e)
 local bx,by=cx-2,cy-1
 local bkt,nbkt,bi={},0,1
 return function()
  while bi>nbkt do
   bx+=1
   if (bx>cx+1) bx,by=cx-1,by+1
   if (by>cy+1) return nil
   bkt=c_bucket(tag,bx,by)
   nbkt,bi=#bkt,1
  end
  local e=bkt[bi]
  bi+=1
  return e
 end 
end

c_buckets={}

function collision_reset()
 c_buckets[g_id]={}
end

function do_collisions()
 c_update_buckets()
 for e in all(entities_with.collides_with) do
  for tag in all(e.collides_with) do
   if entities_tagged[tag] then
   local nothers=
    #entities_tagged[tag]  
   if nothers>4 then
    for o in c_potentials(e,tag) do
     if o~=e then
      local ec,oc=
       c_collider(e),c_collider(o)
      if ec and oc then
       c_one_collision(ec,oc,e,o)
      end
     end
    end
   else
    for oi=1,nothers do
     local o=entities_tagged[tag][oi]
     local dx,dy=
      abs(e.pos.x-o.pos.x),
      abs(e.pos.y-o.pos.y)
     if dx<=20 and dy<=20 then
      local ec,oc=
       c_collider(e),c_collider(o)
      if ec and oc then
       c_one_collision(ec,oc,e,o)
      end
     end
    end
   end     
   end
  end 
 end
end

function c_check(box,tags)
 local fake_e={pos=v(box.xl,box.yt)} 
 for tag in all(tags) do
  for o in c_potentials(fake_e,tag) do
   local oc=c_collider(o)
   if oc and box:overlaps(oc.b) then
    return oc.e
   end
  end
 end
 return nil
end

function c_one_collision(ec,oc,e,o)
 if ec.b:overlaps(oc.b) then
  c_reaction(ec,oc,e,o)
  c_reaction(oc,ec,e,o)
 end
end

function c_reaction(ec,oc,e,o)
 local reaction,param=
  event(ec.e,"collide",oc.e)
 if type(reaction)=="function" then
  reaction(ec,oc,param,e,o)
 end
end

function c_collider(ent)
 if ent.collider then 
  if ent.coll_ts==g_time or not ent.dynamic then
   return ent.collider
  end
 end
 local hb=state_dependent(ent,"hitbox")
 if (not hb) return nil
 local coll={
  b=hb:translate(ent.pos),
  e=ent
 }
 ent.collider,ent.coll_ts=
  coll,g_time
 return coll
end

function c_push_out(oc,ec,allowed_dirs,e,o)
 local sepv=ec.b:sepv(oc.b,allowed_dirs)
 ec.e.pos+=sepv
  
 if ec.e.vel then
  local vdot=ec.e.vel:dot(sepv)
  if vdot<0 then
   if (sepv.y~=0) ec.e.vel.y=0
   if (sepv.x~=0) ec.e.vel.x=0
  end
 end
 ec.b=ec.b:translate(sepv)
end

function c_move_out(oc,ec,allowed)
 return c_push_out(ec,oc,allowed)
end

-------------------------------
-- support
-------------------------------

function do_supports()
 for e in all(entities_with.feetbox) do  
  local fb=e.feetbox
  if fb then
   fb=fb:translate(e.pos)
   local support=c_check(fb,{"walls"})
   e.supported_by=support
   if support and support.vel then
    e.pos+=support.vel
   end
  end
 end
end
-->8
-- entities
 
pad=entity:extend({
 sprite={idle={1}},
 hitbox=box(0,0,8,4),
 collides_with={"guy"},
 bold=true
})
 
function pad:collide(o)
 if o.supported_by and o.vel.y>0 then
  o.vel.y=-5
  self.pos.y+=2
  part(o.pos.x+4,o.pos.y+8)

 end
end

function pad:idle()
 if (is_out(self.pos.y)) self.done=true
end

rocket=entity:extend({
 sprite={
  idle={17}
 },
 draw_order=3,
 hitbox=box(0,0,8,8),
 collides_with={"guy"},
 bold=true
})

function rocket:collide(o)
 self.done=true
    o:become("rocket")
end

function rocket:init()
 self.start=self.pos.y-5
 self.t=rnd(128)
end

function rocket:idle(t)
 self.pos.y=self.start+cos(t/100)*2
 if (is_out(self.pos.y)) self.done=true
end 
 
platform=entity:extend({
 hitbox=box(0,0,9,0.1),
 tags={"walls","plat"},
 collides_with={"plat"},
 weight={0,breaking=0.1}
})

function platform:init()
 self.vel=v(0,0)
 self.start=self.pos.y
 self.hp=3
 if self.second and self.tile==0 and rnd()<0.3 then -- random
  local r=rnd()
  local c=pad
  if r>0.8 then
   c=rocket
  end
  e_add(c({
   pos=v(self.pos.x,self.pos.y-4)
  }))
 end
 
 if self.tile==32 then
  self.vel.x=-0.5*(rnd()>0.5 and 1 or -1)
  self.pos.x=64
 end
end

function platform:render()
 ospr(self.tile+(abs(3-self.hp)*16),self.pos.x,self.pos.y,1,1,false,false)
end

function platform:idle()
 if self.tile==32 then
  if self.pos.x<=0 or self.pos.x>=120 then
   self.vel.x*=-1
  end
 end

 if is_out(self.start) then
  e_remove(self)
  e_add(platform({
   pos=v((self.second and flr(rnd(120))+2 or l),g_cam[g_id].pos.y-70),
   tile=gen_type(),
   second=self.second
  }))
  if (not self.second) gen_pos()
 end
end

function platform:breaking() self:idle() end

function platform:collide(e)
 if e:is_a("plat") 
 and self.vel.x==0 and e.vel.x==0
 and not self.second and self.state~="breaking" and e.state~="breaking" then
  return c_move_out,{true,true,false,false}
 elseif not e:is_a("plat") then
 if (not e.vel) return
 local dy,vy=e.pos.y-self.pos.y,e.vel.y
 if vy>0 and dy<=vy+1 and (vy>0 or vy<-0.3) then
  if self.tile==16 then
   self:become("breaking")
  elseif self.tile==2 then
   self.hp=self.hp-1
   if self.hp==0 then
    part(self.pos.x+4,self.pos.y+1,4)
    self.pos.y+=64
   end
  end

  return c_push_out,{false,false,true,false}   
 end
 end
end

function is_out(y)
 return (g_cam[g_id] and (y-g_cam[g_id].pos.y)>64 or false)
end

cam=entity:extend()

g_cam={}

function cam:init()
 g_cam[g_id]=self
 self.pos=v(64,64)
 self.vel=v(0,0)
end

function cam:idle()
 self.vel.y*=0.9
 local g=g_guy[g_id]
 if not g or g.done then return end
 local dy=g.pos.y-self.pos.y+32
 
 if dy<0 then
  self.vel.y+=dy/20
 elseif not g.done and g.pos.y-self.pos.y>64 then
  g.done=true
  g:save()
  g_start=false
 end
end

function cam:set()
 camera((g_id-1)*-64,self.pos.y-64)
end
-->8
-- guy

guy=entity:extend({
 sprite={
  idle={4},
  flips=true
 },
 ign=true,
 bold=true,
 weight=0.1,
 draw_order=10,
 tags={"guy"},
 hitbox=box(0,1,8,8),
 feetbox=box(0,1,8,8.01),
 collides_with={"walls"}
})

g_guy={}

function guy:init()
 self.id=g_id-1
 g_guy[g_id]=self
 self.done=false
 self.vel=v(0,0)
 self.score=0
 self.max=100
 --self.clr=(self.id==0 and 1 or 2)
end

function guy:idle()
 if self.win then 
  g_guy[self.id==0 and 2 or 1].done=true
 return end
 if (not g_start) return
 self.vel.x*=(self.supported_by and 0.7 or 0.95)
 
 if g_start and self.supported_by and self.vel.y>0 then
  self.vel.y=-2.75
  part(self.pos.x+4,self.pos.y+8)
 end
 
 local i=self.id
 if btn(⬅️,i) then
  self.vel.x-=0.1
 end
 
 if btn(➡️,i) then
  self.vel.x+=0.1
 end
 
 self:common()
end

function guy:save()
  if self.id==0 then
   if(self.max<mx1) mx1=self.max
   dset(0,mx1)
  else
   if(self.max<mx2) mx2=self.max
   dset(1,mx2)
  end
end

function guy:common()
 if self.vel.y<0 and self.pos.y<self.max and self.t%10==0 then
  self.score+=(1*flr(abs(self.vel.y)))
 end
 
 if self.pos.y<self.max then
  self.max=self.pos.y
 end
 
 self.pos.x=(self.pos.x+4)%128-4
end

function guy:render()
 if self.state=="rocket" then
  ospr(17,self.pos.x+(self.facing=="left" and
   5 or -3),self.pos.y + 2,1,1,false,false)
 end
 spr_render(self)
end

function guy:rocket(t)
 if (t>=180) self:become("idle")
 self.vel.y=-4
 self.vel.x*=0.95
 
 e_add(particle({
  pos=v(self.pos.x+(self.facing=="left" and
   5 or -3)+3,self.pos.y),
  vel=v(0,0),
  c=rnd()>0.5 and 9 or 8,
  r=3
 }))
 
 if btn(⬅️,self.id) then
  self.vel.x-=0.1
 end
 
 if btn(➡️,self.id) then
  self.vel.x+=0.1
 end
 self:common()
end
-->8
particle=entity:extend()

function particle:init()
 self.vel=v(rnd(2)-1,rnd(2)-1)
end

function particle:render()
 self.r-=0.1
 self.vel*=0.9
 circfill(self.pos.x,self.pos.y,self.r,0)

 if (self.r<0) e_remove(self)
end

function particle:render_hud()
 g_cam[g_id]:set()
 circfill(self.pos.x,self.pos.y,self.r-1,self.c)
end

function part(x,y,c)
 if(true) return
 for i=1,10 do
  e_add(particle({
   pos=v(x,y),
   c=rnd()>0.7 and 5 or (c or 6),
   r=3
  }))
 end
end
__gfx__
ccccc111feeee22fbbbbb33300044000fffbbb3f000440000004400000044000f11ffff1fffbbb3fffffcccfff9999ff00000000000000000000000000000000
ffffffffff5550ffffffffff00000000f288080f000000000000000000000000ffa9fff9f288080ffff1777f9994499900000000000000000000000000000000
ffffffffffffffffffffffff00000000ffbbbbb3000000000000000000000000fffaaaa9ffbbbbb3ffff717f944a844900000000000000000000000000000000
ffffffffffffffffffffffff00000000f4bb33b300000000000000000000000099fa0aa0f4bb33b3ffff9999488a88a400000000000000000000000000000000
ffffffffffffffffffffffff00000000443444ff00000000000000000000000099f8aaa9443444fffffcc8fff88aaaaf00000000000000000000000000000000
ffffffffffffffffffffffff000000004b3a9a3f000000000000000000000000f9fa999f4b3a9a3ff77c7d16ffaaa8ff00000000000000000000000000000000
ffffffffffffffffffffffff00000000f4b999ff000000000000000000000000f9a9a9aff4b999ffff7766ffff88a8ff00000000000000000000000000000000
ffffffffffffffffffffffff00000000ffbff3ff000000000000000000000000ffa9449fffbff3fff99f444ffff8afff00000000000000000000000000000000
76f76f76fff6dfff999994440004400000044000000440000004400000044000fffffffffff4444fffffffff0000000000000000000000000000000000000000
ffffffffff66ddffffffffff0000000000000000000000000000000000000000ff99999f4424404fffeeeeff0000000000000000000000000000000000000000
ffffffffff6c1dffffffffff0000000000000000000000000000000000000000f94799474224777ffee7e7ef0000000000000000000000000000000000000000
ffffffffff6c1dffffffffff0000000000000000000000000000000000000000f994909444699772eee0e0ee0000000000000000000000000000000000000000
fffffffff866dd2fffffffff0000000000000000000000000000000000000000f4944944f4699f22ee8eee8e0000000000000000000000000000000000000000
fffffffff886d22fffffffff00000000000000000000000000000000000000009999999ff9922fff22ee2ee20000000000000000000000000000000000000000
fffffffff88ff22fffffffff00000000000000000000000000000000000000009f999994f99f44fff88eee2f0000000000000000000000000000000000000000
fffffffff8ffff2fffffffff0000000000000000000000000000000000000000ff9fff4f44ff22ff888822220000000000000000000000000000000000000000
aaaaa99900044000ff9999ff00044000000440000004400000044000000440000004400000044000ffffffff0000000000000000000000000000000000000000
ffffffff000000009994499900000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff00000000944a844900000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff000000004aaa88a400000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff00000000f88aaaaf00000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff00000000ff8a88ff00000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff00000000ffaa88ff00000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
ffffffff00000000fffaafff00000000000000000000000000000000000000000000000000000000ffffffff0000000000000000000000000000000000000000
00044000000440000004400000044000000440000004400000044000000440000004400000044000000440000000000000000000000000000000000000000000
__map__
000000000000000000000000002e000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0105000002620036300564006650086500a6500b6400c6200d6200d6200a6200763007640096400b6500d6500f64010630126201362013620116200b6300963008640096500c6500d65010660116501464015610
01100000197001b700257002570025700197001b700197001b7001e700207002270025700257002570020700197001b7001b7001b700197001b700257002570025700197001b7001b7001b700197001b7001b700
01100000167001670016700237001c700237001c70023700237000f700167001670014700147001f70021700217001d7001d700167002370023700237001a7001670016700167001d7002370023700237001c700
011000000e7000e7000e70011700117001170011700137000e7000e7000e70017700107001370013700137000e7000c7000c7000c7000c7000e700177000e7000e7000e700177000c7000c7000c7000c70013700
010e00000f7001c7001b7000e7000d7001a700197001e70020700127001f700217001270014700137001570025700227002370024700167001770017700197001b7001d7000d7000f700197001b7000000000000
__music__
04 01020304

