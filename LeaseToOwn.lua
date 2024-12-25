--
-- FS25 - LeaseToOwn mod
--
-- LeaseToOwn.lua
--
-- @Author: Bodzio528
--

LeaseToOwn = {
    MOD_DIRECTORY = g_currentModDirectory or "",
    MOD_NAME = g_currentModName or "FS25_LeaseToOwn",
    LEASE_PERIOD = 36, -- lease agreement duration in months
    LEASE_USAGE_LIMIT = 20, -- lease agreement working hours limit
    LEASE_WAGE_PER_PERIOD = EconomyManager.PER_DAY_LEASING_FACTOR, -- 1% monthly fee
    LEASE_WAGE_PER_HOUR = EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR, -- 2.1% per operating hour fee
    LEASE_INITIAL_FEE = EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR -- 2% initial base fee
}

source(LeaseToOwn.MOD_DIRECTORY .. "Logger.lua")
source(LeaseToOwn.MOD_DIRECTORY .. "LeaseToOwnEvent.lua")

local logger = Logger.create(LeaseToOwn.MOD_NAME)
logger:setLevel(Logger.INFO)

function LeaseToOwn:onFrameOpen()
    logger:debug("LeaseToOwn:onFrameOpen pageStatistics")

    local clonedButton = g_inGameMenu.menuButton[1]:clone(self)

    clonedButton:setDisabled(true)
    clonedButton:setVisible(g_inGameMenu.pageStatistics.subCategoryPaging.state == 2)
    clonedButton:setText(g_i18n:getText("LeaseToOwn_PURCHASE"))
    clonedButton:setInputAction("MENU_EXTRA_1")
    clonedButton.onClickCallback = LeaseToOwn.purchase

    g_inGameMenu.menuButton[1].parent:addElement(clonedButton)
    g_inGameMenu.leasePurchase_Button = clonedButton

    LeaseToOwn:onVehicleListIndexChanged(g_inGameMenu.pageStatistics.vehiclesList.selectedIndex, g_inGameMenu.pageStatistics.vehiclesList.totalItemCount)
end

function LeaseToOwn:onFrameClose()
    logger:debug("LeaseToOwn:onFrameClose pageStatistics")

    local menuButton = g_inGameMenu.leasePurchase_Button

    if menuButton ~= nil then
        menuButton:unlinkElement()
        menuButton:delete()
        g_inGameMenu.leasePurchase_Button = nil
    end
end

function LeaseToOwn:onPageStatisticsTabIndexChanged(index, count)
    logger:debug("LeaseToOwn:onPageStatisticsTabIndexChanged pageStatistics")

    local menuButton = g_inGameMenu.leasePurchase_Button

    if menuButton ~= nil then
        menuButton:setVisible(index == 2)
    end
end

function LeaseToOwn:onVehicleListIndexChanged(index, count)
    logger:debug("LeaseToOwn:onVehicleListIndexChanged vehiclesList")

    if g_inGameMenu.leasePurchase_Button ~= nil then
        local vehicle = g_inGameMenu.vehiclesList.dataSource.vehicles[index].vehicle
        if vehicle:getPropertyState() == VehiclePropertyState.LEASED then
            g_inGameMenu.leasePurchase_Button:setDisabled(false)
        else
            g_inGameMenu.leasePurchase_Button:setDisabled(true)
        end
    end
end

function LeaseToOwn:purchase()
    logger:debug("LeaseToOwn:purchase leasePurchaseElement callback begin")

    local selectedVehicleIndex = g_inGameMenu.vehiclesList.dataSource.vehicles[g_inGameMenu.vehiclesList.selectedIndex]
    local vehicle = selectedVehicleIndex.vehicle
    local price = calculateVehicleValue(vehicle)

    LeaseToOwn.price = price
    LeaseToOwn.selectedVehicle = vehicle

    local text = string.format(g_i18n:getText("LeaseToOwn_leasePurchaseQuestion"),
                               vehicle:getName(),
                               g_i18n:formatMoney(price))

    YesNoDialog.show(LeaseToOwn.onConfirm, LeaseToOwn, text)
end

function LeaseToOwn:onConfirm(confirm)
    logger:debug("LeaseToOwn:onConfirm "..tostring(confirm))

    if confirm then
        g_inGameMenu.leasePurchase_Button:setDisabled(false)

        local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
        if farm ~= nil then
            local vehicle = LeaseToOwn.selectedVehicle
            local price = LeaseToOwn.price

            g_client:getServerConnection():sendEvent(LeaseToOwnEvent.new(vehicle,
                                                                         farm.farmId,
                                                                         price))

            g_inGameMenu.pageStatistics:updateVehicles()

            InfoDialog.show(string.format(g_i18n:getText("LeaseToOwn_leasePurchaseCompleted"),
                               vehicle:getName(),
                               g_i18n:formatMoney(price)))
        end
    end
end

g_inGameMenu.vehiclesList:addIndexChangeObserver(LeaseToOwn, LeaseToOwn.onVehicleListIndexChanged)
g_inGameMenu.pageStatistics.subCategoryPaging:addIndexChangeObserver(LeaseToOwn, LeaseToOwn.onPageStatisticsTabIndexChanged)

local statisticsPage = g_inGameMenu.pageStatistics

statisticsPage.onFrameOpen = Utils.appendedFunction(statisticsPage.onFrameOpen, LeaseToOwn.onFrameOpen)
statisticsPage.onFrameClose = Utils.appendedFunction(statisticsPage.onFrameClose, LeaseToOwn.onFrameClose)
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
