--
-- FS22 - LeaseToOwn mod
--
-- LeaseToOwn.lua
--
-- @Author: Bodzio528
--

LeaseToOwn = {
    MOD_DIRECTORY = g_currentModDirectory or "",
    MOD_NAME = g_currentModName or "FS22_LeaseToOwn",
}

-- TODO: search & destroy
LeaseToOwn.modName = g_currentModName or "FS22_LeaseToOwn"

LeaseToOwn.LEASE_PERIOD = 36 -- lease agreement duration in months
LeaseToOwn.LEASE_USAGE_LIMIT = 20 -- lease agreement working hours limit

-- 1% monthly fee
LeaseToOwn.LEASE_WAGE_PER_PERIOD = EconomyManager.PER_DAY_LEASING_FACTOR
-- 2.1% per operating hour fee
LeaseToOwn.LEASE_WAGE_PER_HOUR = EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR
-- 2% initial base fee
LeaseToOwn.LEASE_INITIAL_FEE = EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR 

source(LeaseToOwn.MOD_DIRECTORY .. "Logger.lua")
source(LeaseToOwn.MOD_DIRECTORY .. "LeaseToOwnEvent.lua")

local logger = Logger.create(LeaseToOwn.MOD_NAME)
logger:setLevel(Logger.INFO)

local pageShopItemDetails = g_gui.screenControllers[ShopMenu].pageShopItemDetails

function LeaseToOwn:onShopItemDetailsOpen()
    logger:debug("LeaseToOwn:onShopItemDetailsOpen pageShopItemDetails")

    local shopMenu = g_currentMission.shopMenu
    local currentPage = shopMenu.pageShopItemDetails
    local itemsList = currentPage.itemsList

    if itemsList ~= nil and itemsList.totalItemCount == 0 then
        logger.info("LeaseToOwn: page itemList (is nil = "..tostring(itemsList ~= nil)..") is empty. Abort!")
        return
    end

    local selectedItemIdx = itemsList.selectedIndex
    if selectedItemIdx < 1 then
        logger:info("LeaseToOwn: selected item idx "..selectedItemIdx.." is invalid. Abort!")
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
    logger:debug("LeaseToOwn:purchase leasePurchaseElement callback begin")

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
    logger:debug("LeaseToOwn:onConfirm "..tostring(confirm))

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
    logger:debug("LeaseToOwn:onShopItemDetailsClose pageShopItemDetails")

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

    logger:debug("LeaseToOwn: lease period "..LeaseToOwn.LEASE_PERIOD.." months")
    logger:debug("LeaseToOwn: shop configuration initial price "..initialPrice)
    logger:debug("LeaseToOwn: age "..vehicleAge.." month(s)")
    logger:debug("LeaseToOwn: operating time "..operatingTime.. "h")
    logger:debug("LeaseToOwn: lease installments paid "..installments)
    logger:debug("LeaseToOwn: lease usage paid "..usage)
    logger:debug("LeaseToOwn: lease commission to return "..commission)
    logger:debug("LeaseToOwn: final purchase price for "..vehicle:getName().." is "..g_i18n:formatMoney(price))

    return price
end
