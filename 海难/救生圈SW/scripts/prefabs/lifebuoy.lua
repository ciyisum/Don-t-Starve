require "prefabutil"
--print("LIFEBUOY PREFABS")

local prefabs =
{
	"rowboat_wake",
	"boat_hit_fx",
	"boat_hit_fx_raft_log",
	"boat_hit_fx_raft_bamboo",
	"boat_hit_fx_rowboat",
	"boat_hit_fx_cargoboat",
	"boat_hit_fx_armoured",
	"flotsam_armoured",
	"flotsam_bamboo",
	"flotsam_cargo",
	"flotsam_lograft",
	"flotsam_rowboat",
	"flotsam_surfboard",
}



local assets =
{
	--Asset("ANIM", "anim/raft_basic.zip"), --чисто анимация. Копируем.
	Asset("ANIM", "anim/raft_surfboard_build.zip"), --Нужен для вытягивания картинок.
	Asset("ANIM", "anim/lifebuoy.zip"), --raft_surfboard_build.zip"), --Заменяем на свою.
	Asset("ANIM", "anim/boat_hud_raft.zip"), --need!
	Asset("ANIM", "anim/boat_inspect_raft.zip"), --need!
	Asset("ANIM", "anim/flotsam_lifebuoy_build.zip"), --обломки.
	--Asset("ANIM", "anim/lifebuoy.zip"), --surfboard.zip"), --Основная анимация. Копируем?
	Asset("MINIMAP_IMAGE", "lifebuoymap"), --что-то новое
	Asset( "IMAGE", "images/inventoryimages/lifebuoy.tex" ),
	Asset( "ATLAS", "images/inventoryimages/lifebuoy.xml" ),
}


local function boat_perish(inst)

	--inst:PushEvent("death", {})
	--GetWorld():PushEvent("entity_death", {inst = inst})

	if inst.components.drivable.driver then

		local driver = inst.components.drivable.driver

		driver.components.driver:OnDismount(true)

		driver.components.health:Kill("drowning")

		inst.SoundEmitter:PlaySound(inst.sinksound)
		--driver:PushEvent("death", {cause="drowning"})
		--GetWorld():PushEvent("entity_death", {inst = driver, cause="drowning"})

		inst:Remove()
	end
end



local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("run_loop", true)
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function onmounted(inst)
	--print("I'm getting mounted!")
	inst:RemoveComponent("workable")  
end 

local function ondismounted(inst)
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
end 

local function onopen(inst)
	if inst.components.drivable.driver == nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_boat_inventory_open")
	end
end

local function onclose(inst)
	if inst.components.drivable.driver == nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_boat_inventory_close")
	end
end

local function setupcontainer(inst, slots, bank, build, inspectslots, inspectbank, inspectbuild, inspectboatbadgepos, inspectboatequiproot)
	inst:AddComponent("container")
	inst.components.container:SetNumSlots(#slots)
	inst.components.container.type = "boat"
	inst.components.container.side_align_tip = -500
	inst.components.container.canbeopened = false
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst.components.container.widgetslotpos = slots
	inst.components.container.widgetanimbank = bank
	inst.components.container.widgetanimbuild = build
	inst.components.container.widgetboatbadgepos = Vector3(0, 40, 0)
	inst.components.container.widgetequipslotroot = Vector3(-80, 40, 0)


	local boatwidgetinfo = {}
	boatwidgetinfo.widgetslotpos = inspectslots
	boatwidgetinfo.widgetanimbank = inspectbank
	boatwidgetinfo.widgetanimbuild = inspectbuild
	boatwidgetinfo.widgetboatbadgepos = inspectboatbadgepos
	boatwidgetinfo.widgetpos = Vector3(200, 0, 0)
	boatwidgetinfo.widgetequipslotroot = inspectboatequiproot
	inst.components.container.boatwidgetinfo = boatwidgetinfo
end 




local function commonfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	--trans:SetFourFaced() --??
	inst.no_wet_prefix = true 

	inst:AddTag("boat")

	local anim = inst.entity:AddAnimState()
	
	inst.entity:AddSoundEmitter()

	inst.entity:AddPhysics()
	inst.Physics:SetCylinder(0.25,2)

	inst:AddComponent("inspectable")
	inst:AddComponent("drivable")
	
	inst.waveboost = TUNING.WAVEBOOST

	inst:AddComponent("rowboatwakespawner")

	inst:AddComponent("boathealth")
	inst.components.boathealth:SetDepletedFn(boat_perish)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("lootdropper")

    inst:ListenForEvent("mounted", onmounted)
    inst:ListenForEvent("dismounted", ondismounted)
 
 	inst:AddComponent("flotsamspawner")

	return inst
end

local function pickupfn(inst, guy)
	local board = SpawnPrefab("lifebuoy_item")
	guy.components.inventory:GiveItem(board)
	board.components.pocket:GiveItem("lifebuoy", inst)
	return true
end

local function ondeploy(inst, pt, deployer)
	local board = inst.components.pocket:RemoveItem("lifebuoy") or SpawnPrefab("lifebuoy") 

	if board then
		pt = Vector3(pt.x, 0, pt.z)
		board.Physics:SetCollides(false)
		board.Physics:Teleport(pt.x, pt.y, pt.z) 
		board.Physics:SetCollides(true)
		inst:Remove()
		return board
	end
end

local RUN_SPEED = 2.5
local PENALTY_SPEED = 1

local function lifebuoy_fn(sim)
	--print("CREATE BOW")
	local inst = commonfn(sim)

	setupcontainer(inst, {}, "boat_hud_raft", "boat_hud_raft", {}, "boat_inspect_raft", "boat_inspect_raft", {x=0,y=5}, {})

	inst.AnimState:SetBank("raft")
	inst.AnimState:SetBuild("lifebuoy") --("raft_surfboard_build")
	inst.AnimState:PlayAnimation("run_loop", true)
	--inst.AnimState:OverrideSymbol("ripple_front","raft_surfboard_build","ripple_front")
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetPriority( 5 )
	minimap:SetIcon("lifebuoymap.png")
	inst.perishtime = TUNING.SURFBOARD_PERISHTIME * 0.5 -- 1 days
	inst.components.boathealth.maxhealth = 50
	inst.components.boathealth:SetHealth(50, inst.perishtime)

	inst.landsound = "dontstarve_DLC002/common/boatjump_land_wood"
	inst.sinksound = "dontstarve_DLC002/common/boat_sinking_log_cargo"
	inst.sailsound = "common/surfboard_sail_LP"

	inst.components.boathealth.damagesound = "dontstarve_DLC002/common/surfboard_damage"
	
	inst.components.drivable.sanitydrain = TUNING.SURFBOARD_SANITY_DRAIN
	inst.components.drivable.runspeed = RUN_SPEED --TUNING.SURFBOARD_SPEED
	inst.components.drivable.hitmoisturerate = TUNING.SURFBOARD_HITMOISTURERATE
	inst.components.drivable.maprevealbonus = TUNING.MAPREVEAL_RAFT_BONUS
	inst.components.drivable.runanimation = "row_loop" --похоже на греблю
	inst.components.drivable.prerunanimation = "row_pre"
	inst.components.drivable.postrunanimation = "row_pst"
	--inst.components.drivable.sailloopanim = "row_loop" --"surf_loop"
	--inst.components.drivable.sailstartanim = "row_pre" --"surf_pre"
	--inst.components.drivable.sailstopanim = "row_pst" --"surf_pst"
	inst.components.drivable.overridebuild = "lifebuoy" --"raft_surfboard_build"
	inst.components.drivable.flotsambuild = "flotsam_lifebuoy_build"
	inst.components.drivable.creaksound = "dontstarve_DLC002/common/boat_creaks"
	--inst.components.drivable.alwayssail = true
	
	inst.stop_penalty_task = nil

	--автоматически добавляется?
	--inst.components.flotsamspawner.flotsamprefab = "snakeskin" --что генерировать в качестве обломков.
	inst.components.flotsamspawner.Spawn = function(self)
		self.distance_traveled = 0
		local time_now = GetTime()
		if time_now < 10 or time_now - self.inst.on_mount_time < 5 then
			return --no spawn at start and after mounted
		end
		local debris = SpawnPrefab("snakeskin")
		debris.Transform:SetPosition(self.inst:GetPosition():Get())
		local angle = math.random(-180, 180)*DEGREES
		local sp = math.random()*4+2
		debris.Physics:SetVel(sp*math.cos(angle), 0, sp*math.sin(angle))
		debris.components.floatable:PlayWaterAnim()
		debris:DoTaskInTime(3,function(inst)
			if inst:IsValid() and not inst.components.inventoryitem:IsHeld() then
				SpawnPrefab("splash_ocean").Transform:SetPosition(inst:GetPosition():Get())
				inst:Remove()
			end
		end)
	end
	
	--No damage from waves.
	local old_DoDelta = inst.components.boathealth.DoDelta
	inst.components.boathealth.DoDelta = function(self,damage,damageType,...) --"wave")
		if damageType ~= "wave" then
			return old_DoDelta(self,damage,damageType,...)
		end
		if inst.stop_penalty_task then
			inst.stop_penalty_task:Cancel()
			inst.stop_penalty_task = nil
		end
		local inst = self.inst
		local player = _G.GetPlayer()
		if player.components.driver and player.components.driver.vehicle == inst then
			player.components.locomotor.runspeed = PENALTY_SPEED
			inst.stop_penalty_task = inst:DoTaskInTime(2,function(inst)
				inst.stop_penalty_task = nil
				if player.components.driver.vehicle == inst and player.components.locomotor.runspeed == PENALTY_SPEED then
					player.components.locomotor.runspeed = RUN_SPEED
				end
			end)
		end
		return old_DoDelta(self,math.max(damage,-1),damageType,...)
	end


	inst.waveboost = 3 --TUNING.SURFBOARD_WAVEBOOST
	--inst.wavesanityboost = 0 --TUNING.SURFBOARD_WAVESANITYBOOST

	--inst:AddComponent("characterspecific")
    --inst.components.characterspecific:SetOwner("walani")

	inst:AddComponent("pickupable")
	inst.components.pickupable:SetOnPickupFn(pickupfn)
	inst:SetInherentSceneAltAction(ACTIONS.RETRIEVE)

	return inst
end 



local function deploytest(inst, pt)
	------------------------------------------------------
	-- MAKE SURE THIS TEST MATCHES THE BUILDER.LUA TEST --
	------------------------------------------------------
	local ground = GetWorld()
	local tile = GROUND.GRASS
	if ground and ground.Map then
		tile = ground.Map:GetTileAtPoint(pt:Get())
	end

	local onWater = ground.Map:IsWater(tile)

	--print('deploytest', onWater)
	return onWater
end

local function lifebuoy_ondropped(inst)
	--If this is a valid place to be deployed, auto deploy yourself.
	if inst.components.deployable and inst.components.deployable:CanDeploy(inst:GetPosition()) then
		inst.components.deployable:Deploy(inst:GetPosition(), inst)
	end
end

local function lifebuoy_item_fn(Sim)
	--print("CREATE ITEM")
	local inst = CreateEntity()

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetPriority( 5 )
	minimap:SetIcon("lifebuoymap.png")

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	MakeInventoryPhysics(inst)

	inst:AddTag("boat")
	
	inst.AnimState:SetBank("raft") --surfboard
	inst.AnimState:SetBuild("lifebuoy") --surfboard
	inst.AnimState:PlayAnimation("idle")

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/lifebuoy.xml"
	inst.components.inventoryitem:SetOnDroppedFn(lifebuoy_ondropped)

	inst:AddComponent("pocket")

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = ondeploy
	inst.components.deployable.placer = "lifebuoy_placer" --"surfboard_placer"
	inst.components.deployable.test = deploytest
	inst.components.deployable.deploydistance = 3


	--inst:AddComponent("characterspecific")
    --inst.components.characterspecific:SetOwner("walani")

	return inst
end


return 
	Prefab( "common/objects/lifebuoy", lifebuoy_fn, assets, prefabs),
	Prefab("common/lifebuoy_item", lifebuoy_item_fn, assets, prefabs),
	MakePlacer( "common/lifebuoy_placer",
		"raft",
		"lifebuoy", --"raft_surfboard_build", --build?
		"run_loop",
		false, false, false, nil, nil, nil, nil, true)