--
-- FS22 - LeaseToOwn mod
--
-- LeaseToOwn.lua
--
-- @Author: Bodzio528
-- @Date: 11.07.2022
-- @Version: 1.0.0.0
--
-- Changelog:
-- 	v1.0.0.0 (13.07.2022):
--      - Initial release
--

LeaseToOwn = {}
LeaseToOwn.dir = g_currentModDirectory
LeaseToOwn.modName = g_currentModName

LeaseToOwn.LEASE_PERIOD = 36 -- lease agreement duratio in months
LeaseToOwn.LEASE_USAGE_LIMIT = 20 -- leased equipment working hours limit
LeaseToOwn.LEASE_WAGE_PER_PERIOD = 0.01 -- 1% monthly fee
LeaseToOwn.LEASE_WAGE_PER_HOUR = 0.021 -- 2.1% per operating hour fee
LeaseToOwn.LEASE_INITIAL_FEE = 0.02 -- 2% initial base fee

LeaseToOwn.debug = false -- true --
LeaseToOwn.info = true -- true --

source(LeaseToOwn.dir .. "LeaseToOwnEvent.lua")

local pageShopItemDetails = g_gui.screenControllers[ShopMenu].pageShopItemDetails

function LeaseToOwn:onShopItemDetailsOpen()
    if LeaseToOwn.debug then print("LeaseToOwn:onShopItemDetailsOpen pageShopItemDetails") end

    local shopMenu = g_currentMission.shopMenu
    local currentPage = shopMenu.pageShopItemDetails
    local itemsList = currentPage.itemsList

    if itemsList ~= nil and itemsList.totalItemCount == 0 then
        if LeaseToOwn.info then
            print("LeaseToOwn: page itemList (is nil = "..tostring(itemsList ~= nil)..") is empty. Abort!")
        end
        return
    end

    local selectedItemIdx = itemsList.selectedIndex
    if selectedItemIdx < 1 then
        if LeaseToOwn.info then
            print("LeaseToOwn: selected item idx "..selectedItemIdx.." is invalid. Abort!")
        end
        return
    end
	
	local vehicle = itemsList.dataSource.displayItems[selectedItemIdx].concreteItem
	if vehicle ~= nil then
		local isPageListOfLeasedVehicles = (vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED)
		if isPageListOfLeasedVehicles and shopMenu.leasePurchase_Button == nil then
			local leasePurchaseElement = shopMenu.menuButton[1]:clone(self)
			leasePurchaseElement:setText(g_i18n:getText("LeaseToOwn_PURCHASE"))
			leasePurchaseElement:setInputAction("MENU_EXTRA_1")
			leasePurchaseElement.onClickCallback = function ()
				LeaseToOwn.purchase()
			end

			shopMenu.menuButton[1].parent:addElement(leasePurchaseElement)
			shopMenu.leasePurchase_Button = leasePurchaseElement
		end
	end
end

function LeaseToOwn:purchase()
    if LeaseToOwn.debug then print("LeaseToOwn:purchase leasePurchaseElement callback begin") end

    local shopMenu = g_currentMission.shopMenu
    local currentPage = shopMenu.pageShopItemDetails
    local itemsList = currentPage.itemsList
    local selectedItemIdx = itemsList.selectedIndex
    local vehicle = itemsList.dataSource.displayItems[selectedItemIdx].concreteItem

    local price = calculateVehicleValue(vehicle)
    LeaseToOwn.price = price
    LeaseToOwn.selectedVehicle = vehicle

    local text = string.format(g_i18n:getText("LeaseToOwn_leasePurchaseQuestion"),
                               vehicle:getName(),
                               g_i18n:formatMoney(price))

    g_gui:showYesNoDialog({text = text,
                           title = g_i18n:getText("LeaseToOwn_leasePurchaseQuestionHeader"),
                           callback = LeaseToOwn.onConfirm,
                           target = LeaseToOwn})
end

function LeaseToOwn:onConfirm(confirm)
    if LeaseToOwn.debug then print("LeaseToOwn:onConfirm "..tostring(confirm)) end

    if confirm then
        local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
        if farm ~= nil then
            g_client:getServerConnection():sendEvent(LeaseToOwnEvent.new(LeaseToOwn.selectedVehicle,
                                                                         farm.farmId,
                                                                         LeaseToOwn.price))
        end
    end

    g_currentMission.shopMenu:updateGarageItems()
end

pageShopItemDetails.onFrameOpen = Utils.appendedFunction(pageShopItemDetails.onFrameOpen, LeaseToOwn.onShopItemDetailsOpen)

function LeaseToOwn:onShopItemDetailsClose()
    if LeaseToOwn.debug then print("LeaseToOwn:onShopItemDetailsClose pageShopItemDetails") end

    local shopMenu = g_currentMission.shopMenu

    if shopMenu.leasePurchase_Button ~= nil then
        shopMenu.leasePurchase_Button:unlinkElement()
        shopMenu.leasePurchase_Button:delete()
        shopMenu.leasePurchase_Button = nil
    end
end

pageShopItemDetails.onFrameClose = Utils.appendedFunction(pageShopItemDetails.onFrameClose, LeaseToOwn.onShopItemDetailsClose)

--------------------------------------------------------------------------------

function calculateVehicleValue(vehicle) -- put calculated value in confirmation dialog
    local operatingTime = math.floor(vehicle:getOperatingTime() / (60 * 60 * 1000)) -- full hours
    local vehicleAge = math.floor(vehicle.age) -- full months
    local initialPrice = vehicle:getPrice() -- full shop price
    local installments = LeaseToOwn.LEASE_WAGE_PER_PERIOD * initialPrice * math.min(LeaseToOwn.LEASE_PERIOD, vehicleAge)
    local usage = LeaseToOwn.LEASE_WAGE_PER_HOUR * initialPrice * math.min(LeaseToOwn.LEASE_USAGE_LIMIT, operatingTime)
    local commission = LeaseToOwn.LEASE_INITIAL_FEE * initialPrice * (1.0 - math.min(1.0, vehicleAge / LeaseToOwn.LEASE_PERIOD))
    local price = math.max(0, initialPrice - installments - usage) - commission

    if LeaseToOwn.debug then
        print("LeaseToOwn: lease period "..LeaseToOwn.LEASE_PERIOD.." months")
        print("LeaseToOwn: shop configuration initial price "..initialPrice)
        print("LeaseToOwn: age "..vehicleAge.." month(s)")
        print("LeaseToOwn: operating time "..operatingTime.. "h")
        print("LeaseToOwn: lease installments paid "..installments)
        print("LeaseToOwn: lease usage paid "..usage)
        print("LeaseToOwn: lease commission (2%) to return "..commission)
        print("LeaseToOwn: final purchase price for "..vehicle:getName().." is "..g_i18n:formatMoney(price))
    end

    return price
end
