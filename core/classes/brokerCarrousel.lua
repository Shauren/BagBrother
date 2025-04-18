﻿--[[
	A databroker display object that cycles between plugins.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local LDB = LibStub('LibDataBroker-1.1')
local Carrousel = Addon.Tipped:NewClass('BrokerCarrousel', 'Button')


--[[ Construct ]]--

function Carrousel:New(parent)
	local f = self:Super(Carrousel):New(parent)
	f:RegisterForClicks('anyUp')
	f:EnableMouseWheel(true)

	local left = f:CreateArrowButton('<')
	left:SetScript('OnClick', function() f:SetPreviousObject() end)
	left:SetPoint('LEFT')

	local right = f:CreateArrowButton('>')
	right:SetScript('OnClick', function() f:SetNextObject() end)
	right:SetPoint('RIGHT')

	local icon = f:CreateTexture(nil, 'OVERLAY')
	icon:SetPoint('LEFT', left, 'RIGHT')
	icon:SetSize(18, 18)

	local text = f:CreateFontString()
	text:SetFontObject('NumberFontNormalRight')
	text:SetJustifyH('LEFT')

	f.objects = {}
	f.Icon, f.Text = icon, text
	f.Left, f.Right = left, right
	f:SetHeight(24)
	f:Update()
	return f
end

function Carrousel:CreateArrowButton(text)
	local b = CreateFrame('Button', nil, self)
	b:SetNormalFontObject('GameFontNormal')
	b:SetHighlightFontObject('GameFontHighlight')
	b:SetToplevel(true)
	b:SetSize(18, 18)
	b:SetText(text)

	return b
end


--[[ Messages ]]--

function Carrousel:ObjectCreated(_, name)
	if self:GetObjectName() == name then
		self:UpdateDisplay()
	end
end

function Carrousel:AttributeChanged(_, object, attr)
	if self:GetObjectName() == object then
		if attr == 'icon' then
			self:UpdateIcon()
		elseif attr == 'text' then
			self:UpdateText()
		end
	end
end


--[[ Frame Events ]]--

function Carrousel:OnShow()
	self:Update()
end

function Carrousel:OnHide()
	LDB.UnregisterAllCallbacks(self)
end

function Carrousel:OnEnter()
	local object = self:GetObject()
	if object then
		if object.OnEnter then
			object.OnEnter(self)
		else
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')

			if object.OnTooltipShow then
				object.OnTooltipShow(GameTooltip)
			else
				GameTooltip:SetText(self:GetObjectName())
			end

			GameTooltip:Show()
		end
	end
end

function Carrousel:OnLeave()
	local object = self:GetObject()
	if object and object.OnLeave then
		object.OnLeave(self)
	else
		self:Super(Carrousel):OnLeave()
	end
end

function Carrousel:OnClick(...)
	GetValueOrCallFunction(self:GetObject(), 'OnClick', self, ...)
end

function Carrousel:OnDragStart()
	GetValueOrCallFunction(self:GetObject(), 'OnDragStart', self)
end

function Carrousel:OnReceiveDrag()
	GetValueOrCallFunction(self:GetObject(), 'OnReceiveDrag', self)
end

function Carrousel:OnMouseWheel(direction)
	if direction > 0 then
		self:SetNextObject()
	else
		self:SetPreviousObject()
	end
end


--[[ Update ]]--

function Carrousel:Update()
	self:RegisterEvents()
	self:UpdateDisplay()
end

function Carrousel:RegisterEvents()
	LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated', 'ObjectCreated')
	LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged', 'AttributeChanged')
end

function Carrousel:UpdateDisplay()
	self:UpdateText()
	self:UpdateIcon()
end

function Carrousel:UpdateText()
	local obj = self:GetObject()
	self.Text:SetText(obj.text or obj.label or '')
	self:Layout()
end

function Carrousel:UpdateIcon()
	local obj = self:GetObject()
	self.Icon:SetTexture(obj.icon)
	self.Icon:SetShown(obj.icon)
	self:Layout()
end

function Carrousel:Layout()
	if self.Icon:IsShown() then
		self.Text:SetPoint('LEFT', self.Icon, 'RIGHT', 2, 0)
		self.Text:SetPoint('RIGHT', self.Right, 'LEFT', -2, 0)
	else
		self.Text:SetPoint('LEFT', self.Left, 'RIGHT', 2, 0)
		self.Text:SetPoint('RIGHT', self.Right, 'LEFT', -2, 0)
	end
end


--[[ LDB Objects ]]--

function Carrousel:SetNextObject()
	local current = self:GetObjectName()
	local objects = self:GetAvailableObjects()
	local i = FindInTableIf(objects, function(o) return o == current end)

	self:SetObject(objects[(i or 0) % #objects + 1])
end

function Carrousel:SetPreviousObject()
	local current = self:GetObjectName()
	local objects = self:GetAvailableObjects()
	local i = FindInTableIf(objects, function(o) return o == current end)

	self:SetObject(objects[((i or 2) - 2) % #objects + 1])
end

function Carrousel:SetObject(name)
	self:GetProfile().brokerObject = name
	self:UpdateDisplay()

	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_FAER_TAB)
end

function Carrousel:GetObject()
	return LDB:GetDataObjectByName(self:GetObjectName()) or LDB:GetDataObjectByName(ADDON .. 'Launcher')
end

function Carrousel:GetObjectName()
	return self:GetProfile().brokerObject
end

function Carrousel:GetAvailableObjects()
	wipe(self.objects)

	for name, obj in LDB:DataObjectIterator() do
		if obj.type == 'launcher' or obj.type == 'data source' then
			tinsert(self.objects, name)
		end
	end

	sort(self.objects)
	return self.objects
end
