--print("LIFEBUOY MOD")
local _G=GLOBAL
local require = _G.require
PrefabFiles = {
	"lifebuoy",
}

Assets = {
	Asset( "IMAGE", "map/lifebuoymap.tex" ),
	Asset( "ATLAS", "map/lifebuoymap.xml" ),
}

AddMinimapAtlas("map/lifebuoymap.xml")

local recipe = _G.Recipe("lifebuoy_item", {_G.Ingredient("snakeskin", 3),_G.Ingredient("log", 1)},
	_G.RECIPETABS.NAUTICAL, _G.TECH.NONE, _G.RECIPE_GAME_TYPE.SHIPWRECKED)
recipe.atlas = "images/inventoryimages/lifebuoy.xml"
recipe.sortkey = 0.0034598723465

_G.STRINGS.NAMES.LIFEBUOY = "Lifebuoy"
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.LIFEBUOY = "It will save my life!"

_G.STRINGS.NAMES.LIFEBUOY_ITEM = "Lifebuoy"
_G.STRINGS.RECIPE_DESC.LIFEBUOY_ITEM = "Make it if you can't swim"
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.LIFEBUOY_ITEM = "It will save my life!"

mods=_G.rawget(_G,"mods")or(function()local m={}_G.rawset(_G,"mods",m)return m end)()
--print("MODS="..tostring(mods))
--_G.arr(mods)
local mk = _G.rawget(_G,"RegisterRussianName") or mods.RussianLanguagePack and mods.RussianLanguagePack.RegisterRussianName
--print("mk="..tostring(mk))
if mk then
	--mk("MUSTINESS","Плесень",3,"Плесени")
	_G.STRINGS.NAMES.LIFEBUOY = "Спасательный круг"
	_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.LIFEBUOY = "Он спасёт мою жизнь!"

	_G.STRINGS.NAMES.LIFEBUOY_ITEM = "Спасательный круг"
	_G.STRINGS.RECIPE_DESC.LIFEBUOY_ITEM = "Не умеешь плавать? Не вопрос."
	_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.LIFEBUOY_ITEM = "Он спасёт мою жизнь!"	
end



local driver = require "components/driver"
local old_OnMount = driver.OnMount
function driver:OnMount(vehicle,...)
	local res = old_OnMount(self,vehicle,...)
	if vehicle and vehicle.prefab == "lifebuoy" then
		vehicle.on_mount_time = _G.GetTime()
		--self.inst.AnimState:ClearOverrideBuild(self.vehicle.components.drivable.overridebuild)
		--self.inst.AnimState:OverrideSymbol("rowboat01","lifebuoy","rowboat01") --+!
		--self.inst.AnimState:OverrideSymbol("shadow","lifebuoy","shadow") --+!
		self.inst.AnimState:OverrideSymbol("ripple_front","raft_surfboard_build","ripple_front") --+!
		--self.inst.AnimState:OverrideSymbol("ripple_front","raft_surfboard_build","ripple_front")
	end
	return res
end



--Save life on boat perished.
local bh = require "components/boathealth"

local function InvDropEverything(self,container)
	if self.activeitem then
		self:DropItem(self.activeitem)
		self:SetActiveItem(nil)
	end
	for k = 1,self.maxslots do
		local v = self.itemslots[k]
		if v and not v:HasTag("boat") then
			self:DropItem(v, true, true)
		end
	end
	for k,v in pairs(self.equipslots) do
		if v.components.container ~= nil then
			self:DropItem(v, true, true)
		end
	end
	if container then
		container:DropEverything()
	end
end


local function my_DepletedFn(inst)
	if inst.components.drivable.driver then
		local driver = inst.components.drivable.driver
		local inv = driver.components.inventory
		local cont = inst.components.container
		if inv then
			local lifebuoy = inv:FindItem(function(v) return v.prefab == "lifebuoy_item" end)
			if not lifebuoy and cont then --find in boat's inventory
				lifebuoy = cont:FindItem(function(v) return v.prefab == "lifebuoy_item" end)
			end
			if lifebuoy then
				local pt = driver:GetPosition()
				local plato = lifebuoy.components.deployable.ondeploy(lifebuoy,pt, driver)
				if plato then
					driver.components.driver:OnDismount(false)
					local fx={"boat_death","bombsplash", "splash_water"} --splash_water_sink
					for i,v in ipairs(fx) do --just fx
						local f = _G.SpawnPrefab(v)
						if f then
							f.Transform:SetPosition(pt.x,pt.y,pt.z)
						end
					end
					--print("Dismount!")
					--print("PLATO = "..tostring(plato)..", valid="..tostring(plato:IsValid()))
					inst.SoundEmitter:PlaySound(inst.sinksound)
					InvDropEverything(inv,cont) --keep equip
					--save myself
					plato.components.drivable:OnMounted(driver)
					driver.components.driver:OnMount(plato)
					driver:DoTaskInTime(1,function(driver)
						if driver:IsValid() then
							if plato:IsValid() and driver.components.driver then
								--print("OnMount again")
								--driver.components.driver:OnMount(plato)
								driver:StartUpdatingComponent(driver.components.driver)
							else
								--print("KILL DRIVER why?")
								--driver.components.health:Kill("drowning")
							end
						end
					end)
					--driver.components.health:Kill("drowning")
					--inst.SoundEmitter:PlaySound(inst.sinksound)
					--driver:PushEvent("death", {cause="drowning"})
					--GetWorld():PushEvent("entity_death", {inst = driver, cause="drowning"})
					inst:Remove()
					return
				end
			end
		end
	end
	return inst.components.boathealth.old_boat_perish_fn(inst)
end


local old_DoDelta = bh.DoDelta
function bh:DoDelta(...)
	if self.old_boat_perish_fn ~= nil then
		self.depleted = my_DepletedFn
		old_DoDelta(self,...)
		self.depleted = self.old_boat_perish_fn
		return
	end
	return old_DoDelta(self,...)
end


local old_SetDepletedFn = bh.SetDepletedFn
function bh:SetDepletedFn(fn)
	old_SetDepletedFn(self,fn)
	self.old_boat_perish_fn = self.depleted --save last set fn.
end


