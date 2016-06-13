local PlayerHud = require "screens/playerhud"

local OldSMC = PlayerHud.SetMainCharacter

function PlayerHud:SetMainCharacter(maincharacter)
	OldSMC(self,maincharacter) 		
	if maincharacter then
		local bp = maincharacter.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
		if bp and bp.components.container then
			bp.components.container:Close()
			bp.components.container:Open(maincharacter)
		end
	end
end

return PlayerHud
