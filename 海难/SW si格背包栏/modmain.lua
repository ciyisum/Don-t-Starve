Assets = {Asset("ATLAS", "images/backpack.xml")}

function TweakBackpack(inst)
	inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.BACK
end

function TweakInventory(component,inst)
	inst.components.inventory.numequipslots = 4
	inst.components.inventory.maxslots = inst.components.inventory.maxslots - 1
end

function TweakInvBar(inst)
	inst:AddEquipSlot(GLOBAL.EQUIPSLOTS.BACK, "images/backpack.xml", "backpack.tex")
	inst:Rebuild()
end

table.insert(GLOBAL.EQUIPSLOTS, "BACK")
GLOBAL.EQUIPSLOTS.BACK = "back"

AddComponentPostInit("inventory", TweakInventory)
AddPrefabPostInit("backpack", TweakBackpack)
AddPrefabPostInit("krampus_sack", TweakBackpack)
AddPrefabPostInit("piggyback", TweakBackpack)
AddPrefabPostInit("icepack", TweakBackpack)
AddClassPostConstruct("widgets/inventorybar", TweakInvBar)
local PlayerHud = GLOBAL.require "phfix"
