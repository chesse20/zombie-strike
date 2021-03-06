local ReplicatedStorage = game:GetService("ReplicatedStorage")

local inspect = require(ReplicatedStorage.Core.inspect)
local LimitedMap = require(ReplicatedStorage.Core.LimitedMap)
local PetsDictionary = require(ReplicatedStorage.Core.PetsDictionary)

local CoreData = {}

CoreData.Equippable = {
	Armor = true,
	Helmet = true,
	Weapon = true,
	Pet = true,
}

local function getDataItem(data)
	if data.Model then
		-- Standard item
		return ReplicatedStorage.Items[data.Type .. data.Model]
	else
		return data.Instance
	end
end

-- https://devforum.roblox.com/t/view-port-frame-accessories/227171/2
local function addAccessory(character, accessory)
	local attachment = accessory.Handle:FindFirstChildOfClass("Attachment") -- Not all Accessories are guaranteed to have an Attachment - if not, we'll use default hat placement.
	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = accessory.Handle

	if attachment then
		-- The found attachment name in the accessory matches an existing attachment in the character rig, which we'll make the weld connect to.
		local other = character:FindFirstChild(tostring(attachment), true)
		weld.C0 = attachment.CFrame
		weld.C1 = other.CFrame
		weld.Part1 = other.Parent
	else
		-- No attachment found. The placement is defined using the legacy hat placement.
		weld.C1 = CFrame.new(0, character.Head.Size.Y / 2, 0) * accessory.AttachmentPoint:inverse()
		weld.Part1 = character.Head
	end

	-- Updates the accessory to be positioned accordingly to the weld we just created.
	accessory.Handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:inverse()
	accessory.Parent = character
	weld.Parent = accessory.Handle
end

local function addAttachment(item, attachment)
	local attachName = require(attachment.Config).Attach

	local weld = Instance.new("Weld")
	weld.Part0 = item.PrimaryPart
	weld.Part1 = attachment.PrimaryPart
	weld.C0	= item.PrimaryPart[attachName .. "Attach"].CFrame
	weld.C1	= attachment.PrimaryPart.Attach.CFrame
	weld.Parent = attachment.PrimaryPart
	attachment.PrimaryPart.CFrame = item.PrimaryPart[attachName .. "Attach"].WorldCFrame
	attachment.Parent = item
end

function CoreData.AddAttachmentsToGun(data, model, uuid)
	uuid = uuid or model.UUID
	local attachment = data.Attachment
	if attachment then
		local attachmentModel = ReplicatedStorage.Items[attachment.Type .. attachment.Model]:Clone()
		attachmentModel.Name = "GunAttachment"
		attachmentModel.PrimaryPart.Anchored = false

		local rarityValue = Instance.new("NumberValue")
		rarityValue.Name = "Rarity"
		rarityValue.Value = attachment.Rarity
		rarityValue.Parent = attachmentModel

		addAttachment(model, attachmentModel)
		uuid.Value = uuid.Value .. "/" .. attachment.UUID
	end
end

-- 270 == game pass inventory space * 2
local modelCache = LimitedMap.new(270)

local function getModel(data)
	local itemType = data.Type

	local uuid = {}

	-- assert(data.UUID ~= nil, "UUID is nil! " .. inspect(data))
	uuid = Instance.new("StringValue")
	uuid.Name = "UUID"
	uuid.Value = data.UUID or "NO_UUID"

	if data.Name ~= nil and data.UUID == nil then
		uuid.Value = data.Name
	end

	if itemType == "Armor" then
		local armorItem = getDataItem(data)
		local shirt = armorItem:FindFirstChildOfClass("Shirt")

		if shirt then
			local pants = armorItem:FindFirstChildOfClass("Pants")

			local armorDummy = ReplicatedStorage.ArmorDummy:Clone()
			armorDummy.Shirt.ShirtTemplate = shirt.ShirtTemplate
			armorDummy.Shirt.Color3 = shirt.Color3
			armorDummy.Pants.PantsTemplate = pants.PantsTemplate
			armorDummy.Pants.Color3 = pants.Color3

			uuid.Parent = armorDummy
			return armorDummy
		elseif armorItem:FindFirstChild("UpperTorso") then
			-- Cosmetic
			local armorDummy = ReplicatedStorage.ArmorDummy:Clone()

			for _, limb in pairs(armorItem:GetChildren()) do
				if limb:IsA("Accessory") then
					addAccessory(armorDummy, limb)
				else
					limb = limb:Clone()
					limb.Position = armorDummy[limb.Name].Position
					armorDummy.Humanoid:ReplaceBodyPartR15(limb.Name, limb)
				end
			end

			uuid.Parent = armorDummy
			return armorDummy
		else
			error("don't know how to handle " .. inspect(data))
		end
	elseif itemType == "Helmet" then
		local helmetItem = getDataItem(data)

		local model = Instance.new("Model")
		uuid.Parent = model

		if helmetItem:IsA("BasePart") or helmetItem:IsA("Accessory") then
			local clone = helmetItem:Clone()
			clone.Parent = model

			if clone:IsA("BasePart") then
				model.PrimaryPart = clone
			else
				model.PrimaryPart = clone.Handle
			end
		else
			for _, content in pairs(helmetItem:GetChildren()) do
				if content:IsA("BasePart") then
					local clone = content:Clone()
					clone.Parent = model
					model.PrimaryPart = clone
				elseif content:IsA("Accessory") then
					local clone = content:Clone()
					clone.Parent = model
					model.PrimaryPart = clone.Handle
				end
			end
		end

		return model
	elseif itemType == "Pet" then
		local model = Instance.new("Model")
		local pet = PetsDictionary.Pets[data.Model].Model:Clone()
		pet.Parent = model
		uuid.Parent = model
		model.PrimaryPart = pet
		return model
	elseif itemType == "GunLowTier" or itemType == "GunHighTier" then
		local model = Instance.new("Model")

		local gun = data.Instance.Gun:Clone()
		gun.Parent = model

		local uuid = Instance.new("StringValue")
		uuid.Name = "UUID"
		uuid.Value = "Gun_" .. data.Index
		uuid.Parent = model

		model.PrimaryPart = gun

		return model
	else
		local model = ReplicatedStorage.Items[data.Type .. data.Model]:Clone()
		CoreData.AddAttachmentsToGun(data, model, uuid)
		uuid.Parent = model
		return model
	end
end

CoreData.GetModel = function(data)
	if data.UUID ~= nil and modelCache[data.UUID] ~= nil then
		return modelCache[data.UUID]
	end

	local model = getModel(data)
	if model ~= nil and data.UUID ~= nil and #tostring(data.UUID) == 32 then
		modelCache[data.UUID] = model
	end

	return model
end

return CoreData
