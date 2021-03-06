local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assign = require(ReplicatedStorage.Core.assign)
local CircleBackground = require(ReplicatedStorage.Core.UI.Components.CircleBackground)
local Data = require(ReplicatedStorage.Core.Data)
local Loot = require(ReplicatedStorage.Core.Loot)
local Roact = require(ReplicatedStorage.Vendor.Roact)
local RoactRodux = require(ReplicatedStorage.Vendor.RoactRodux)
local SilhouetteModel = require(ReplicatedStorage.Core.SilhouetteModel)
local StyledButton = require(ReplicatedStorage.Core.UI.Components.StyledButton)
local ViewportFramePreviewComponent = require(ReplicatedStorage.Core.UI.Components.ViewportFramePreviewComponent)

local e = Roact.createElement

local ItemButton = Roact.PureComponent:extend("ItemButton")

local ICON_FAVORITED = "rbxassetid://4462267516"
local ICON_UNFAVORITED = "rbxassetid://4462267332"

function ItemButton:init()
	self:SetModel()

	self:setState({
		hovered = false,
	})

	self.mouseEnter = function()
		self:setState({
			hovered = true,
		})

		self.props.onHover(self.props.Loot)
	end

	self.mouseLeave = function()
		self:setState({
			hovered = false,
		})

		self.props.onUnhover(self.props.Loot)
	end

	self.activated = function()
		local props = self.props
		if props.equipped then
			(props.onClickEquipped or function() end)(props.Loot)
		else
			(props.onClickUnequipped or function() end)(props.Loot)
		end
	end

	self.favorite = function()
		if not self.props.NoInteractiveFavorites then
			ReplicatedStorage.Remotes.FavoriteLoot:FireServer(self.props.Loot.UUID)
		end
	end
end

function ItemButton:SetModel()
	local model = Data.GetModel(self.props.Loot)

	if Loot.IsAurora(self.props.Loot) then
		model.PrimaryPart.Material = Enum.Material.Ice
		model.PrimaryPart.TextureID = ""
	end

	if self.props.Silhouette then
		SilhouetteModel(model)
	end

	self:setState({
		model = model,
	})
end

function ItemButton:didUpdate(oldProps)
	if oldProps.Silhouette ~= self.props.Silhouette
		or oldProps.Loot ~= self.props.Loot
	then
		self:SetModel()
	end
end

function ItemButton:render()
	local props = self.props

	local color

	if props.Silhouette then
		color = Color3.new(0.35, 0.35, 0.35)
	else
		color = Loot.Rarities[props.Loot.Rarity].Color
	end

	local h, s, v = Color3.toHSV(color)

	if props.equipped then
		color = Color3.fromHSV(h, s, v * 0.6)
	elseif self.state.hovered then
		color = Color3.fromHSV(h, s, v * 0.7)
	end

	local favoriteFrame

	if not props.HideFavorites then
		local favoriteButton = e("ImageButton", {
			BackgroundTransparency = 1,
			Image = props.Loot.Favorited and ICON_FAVORITED or ICON_UNFAVORITED,
			Size = UDim2.fromScale(1, 1),
			[Roact.Event.Activated] = self.favorite,
		})

		local child

		if props.NoInteractiveFavorites then
			child = favoriteButton
		else
			child = e(CircleBackground, {}, {
				FavoriteButton = favoriteButton,
			})
		end

		favoriteFrame = e("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.88, 0.09),
			Size = UDim2.fromScale(0.2, 0.2),
		}, {
			FavoriteButton = child,
		})
	end

	local equippedText

	if props.equipped then
		equippedText =  e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = 20,
			Size = UDim2.fromScale(0.95, 0.3),
			Text = "EQUIPPED",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextStrokeTransparency = 0,
			ZIndex = 2,
		})
	end

	return e(StyledButton, {
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Square = true,

		[Roact.Event.Activated] = self.activated,
		[Roact.Event.MouseEnter] = self.mouseEnter,
		[Roact.Event.MouseLeave] = self.mouseLeave,
	}, assign({
		EquippedText = equippedText,
		FavoriteFrame = favoriteFrame,

		ViewportFrame = e(ViewportFramePreviewComponent, {
			Model = self.state.model,

			Native = {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.9),
			},
		}),
	}, props[Roact.Children] or {}))
end

function ItemButton:willUnmount()
	if self.props.onUnhover then
		self.props.onUnhover(self.props.Loot)
	end
end

return RoactRodux.connect(function(state, props)
	local lootType = props.Loot.Type

	if Loot.IsWeapon(props.Loot) then
		lootType = "Weapon"
	elseif Loot.IsAttachment(props.Loot) then
		lootType = "Attachment"
	end

	if state.equipment then
		local equipped = state.equipment["equipped" .. lootType]

		if equipped then
			return {
				equipped = equipped.UUID == props.Loot.UUID
					or table.find(state.trading.theirEquipment, props.Loot.UUID) ~= nil,
			}
		end
	end

	return {}
end)(ItemButton)
