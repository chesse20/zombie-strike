local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assign = require(ReplicatedStorage.Core.assign)
local BuyBrains = require(script.BuyBrains)
local BuyCaps = require(ReplicatedStorage.Components.BuyCaps)
local Close = require(script.Parent.Close)
local GamePasses = require(script.GamePasses)
local Roact = require(ReplicatedStorage.Vendor.Roact)
local RoactRodux = require(ReplicatedStorage.Vendor.RoactRodux)
local Shop = require(script.Shop)
local Weapons = require(script.Weapons)
local XPMultipliers = require(script.XPMultipliers)

local e = Roact.createElement

local function CategoryButton(props)
	return e("ImageButton", {
		BackgroundColor3 = props.opened and Color3.fromRGB(224, 86, 253) or Color3.fromRGB(190, 46, 221),
		BorderSizePixel = 0,
		Image = "",
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
		[Roact.Event.Activated] = function()
			props.open(props.Page)
		end,
	}, {
		Label = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.95, 0, 0.8, 0),
			Text = props.Text,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}),
	})
end

local CategoryButton = RoactRodux.connect(function(state, props)
	return {
		opened = state.store.page == props.Page
	}
end, function(dispatch)
	return {
		open = function(page)
			dispatch({
				type = "SetStorePage",
				page = page,
			})
		end,
	}
end)(CategoryButton)

local Store = Roact.PureComponent:extend("Store")

function Store:init()
	self.buyBrainsRef = Roact.createRef()
	self.buyCapsRef = Roact.createRef()
	self.gamePassesRef = Roact.createRef()
	self.shopRef = Roact.createRef()
	self.weaponsRef = Roact.createRef()
	self.xpMultiplierRef = Roact.createRef()

	self.pageLayoutRef = Roact.createRef()
end

function Store:UpdateCurrentPage()
	local page = self.pageLayoutRef:getValue()

	if self.props.page == "Shop" then
		page:JumpTo(self.shopRef:getValue())
	elseif self.props.page == "XP" then
		page:JumpTo(self.xpMultiplierRef:getValue())
	elseif self.props.page == "GamePasses" then
		page:JumpTo(self.gamePassesRef:getValue())
	elseif self.props.page == "BuyBrains" then
		page:JumpTo(self.buyBrainsRef:getValue())
	elseif self.props.page == "BuyCaps" then
		page:JumpTo(self.buyCapsRef:getValue())
	elseif self.props.page == "Weapons" then
		page:JumpTo(self.weaponsRef:getValue())
	end
end

function Store:didMount()
	self:UpdateCurrentPage()
end

function Store:didUpdate()
	self:UpdateCurrentPage()
end

function Store:render()
	local props = self.props

	return e("TextButton", {
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(190, 46, 221),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Visible = props.open,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 0.7, 0),
		Text = "",
		ZIndex = 3,
	}, {
		e("UIAspectRatioConstraint", {
			AspectRatio = 2,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Height,
		}),

		Close = e(Close, {
			onClose = props.close,
		}),

		Buttons = e("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.02, 0, 0, 0),
			Size = UDim2.new(0.95, 0, 0.1, 0),
		}, {
			e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.005, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			ShopButton = e(CategoryButton, {
				Page = "Shop",
				Text = "SHOP",
				Size = UDim2.fromScale(0.14, 1),
				LayoutOrder = 1,
			}),

			WeaponsButton = e(CategoryButton, {
				Page = "Weapons",
				Text = "SKINS",
				Size = UDim2.fromScale(0.12, 1),
				LayoutOrder = 2,
			}),

			XPButton = e(CategoryButton, {
				Page = "XP",
				Text = "DOUBLE XP",
				Size = UDim2.fromScale(0.18, 1),
				LayoutOrder = 3,
			}),

			GamePasses = e(CategoryButton, {
				Page = "GamePasses",
				Text = "GAME PASSES",
				Size = UDim2.fromScale(0.18, 1),
				LayoutOrder = 4,
			}),

			BuyBrains = e(CategoryButton, {
				Page = "BuyBrains",
				Text = "BRAINS",
				Size = UDim2.fromScale(0.14, 1),
				LayoutOrder = 5,
			}),

			BuyCaps = e(CategoryButton, {
				Page = "BuyCaps",
				Text = "CAPS",
				Size = UDim2.fromScale(0.14, 1),
				LayoutOrder = 6,
			}),
		}),

		Contents = e("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 0,
		}, {
			e("UIPageLayout", {
				Animated = true,
				Circular = true,
				EasingDirection = Enum.EasingDirection.Out,
				EasingStyle = Enum.EasingStyle.Quint,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				TweenTime = 0.5,
				VerticalAlignment = Enum.VerticalAlignment.Center,

				GamepadInputEnabled = false,
				ScrollWheelInputEnabled = false,
				TouchInputEnabled = false,

				[Roact.Ref] = self.pageLayoutRef,
			}),

			GamePasses = e(GamePasses, {
				[Roact.Ref] = self.gamePassesRef,
			}),

			Shop = e(Shop, {
				[Roact.Ref] = self.shopRef,
			}),

			XPMultipliers = e(XPMultipliers, {
				[Roact.Ref] = self.xpMultiplierRef,
			}),

			BuyBrains = e(BuyBrains, {
				[Roact.Ref] = self.buyBrainsRef,
			}),

			BuyCaps = e(BuyCaps, {
				[Roact.Ref] = self.buyCapsRef,
				remote = ReplicatedStorage.Remotes.BuyCaps,
			}),

			Weapons = e(Weapons, {
				[Roact.Ref] = self.weaponsRef,
			}),
		}),
	})
end

return RoactRodux.connect(
	function(state)
		return assign({
			open = state.page.current == "Store"
		}, state.store)
	end,

	function(dispatch)
		return {
			close = function()
				dispatch({
					type = "ToggleStore",
				})
			end,
		}
	end
)(Store)
