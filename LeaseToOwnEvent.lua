--
-- FS22 - LeaseToOwn mod
--
-- LeaseToOwnEvent.lua
--
-- @Author: Bodzio528
-- @Date: 11.07.2022
-- @Version: 1.0.0.0
--
-- Changelog:
-- 	v1.0.0.0 (13.07.2022):
--      - Initial release
--

LeaseToOwnEvent = {}
local LeaseToOwnEvent_mt = Class(LeaseToOwnEvent, Event)

LeaseToOwnEvent.debug = false -- true --

InitEventClass(LeaseToOwnEvent, "LeaseToOwnEvent")

---Create instance of Event class
-- @return table self instance of class event
function LeaseToOwnEvent.emptyNew()
    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent:emptyNew") end
    local self = Event.new(LeaseToOwnEvent_mt)

    return self
end

---Create new instance of event
-- @param table vehicle vehicle
function LeaseToOwnEvent.new(vehicle, farmId, price)
    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent:new") end
    local self = LeaseToOwnEvent.emptyNew()
    self.vehicle = vehicle
    self.farmId = farmId
    self.price = price
    return self
end

function LeaseToOwnEvent:writeStream(streamId, connection)
    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent:writeStream") end

    NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.price)
end

function LeaseToOwnEvent:readStream(streamId, connection)
    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent:readStream") end

    self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.price = streamReadInt32(streamId)

    self:run(connection)
end

function LeaseToOwnEvent:run(connection)
    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent:run") end

    if not connection:getIsServer() then
        if LeaseToOwnEvent.debug then print("LeaseToOwnEvent: this is client") end

        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            local player = g_currentMission:getPlayerByConnection(connection)
            local farmAllowed = player ~= nil and g_currentMission:getHasPlayerPermission("farmManager", connection, player.farmId)
            if player ~= nil and player.farmId > 0 and farmAllowed then
                local isLeased = (self.vehicle:getPropertyState() == Vehicle.PROPERTY_STATE_LEASED)
                if isLeased and player.farmId == self.vehicle:getOwnerFarmId() then
                    if self.price > 0 then
                        local money = g_currentMission:getMoney(self.farmId)
                        if money < self.price then
                            if LeaseToOwnEvent.debug then print("LeaseToOwnEvent: Not enough money on the farm! Aborting.") end
                            return
                        end
                    end
                    -- at this point all requirements are fulfilled

                    -- 1. deduct money from account
                    g_currentMission:addMoney(-self.price, self.farmId, MoneyType.SHOP_VEHICLE_BUY, true, true)

                    -- 2. change ownership of vehicle
                    self.vehicle.propertyState = Vehicle.PROPERTY_STATE_OWNED
                    g_currentMission:removeLeasedItem(self.vehicle)
                    g_currentMission:addOwnedItem(self.vehicle)

                    -- 3. broadcast event so others will know
					g_server:broadcastEvent(self, true)
                else
                    if LeaseToOwnEvent.debug then print("LeaseToOwnEvent: vehicle is NOT leased - abort!") end
                end
            end
        end
    else -- this is server
        if LeaseToOwnEvent.debug then print("LeaseToOwnEvent: this is server") end

        if self.vehicle ~= nil then
            -- 2. change ownership of vehicle
            self.vehicle.propertyState = Vehicle.PROPERTY_STATE_OWNED
            g_currentMission:removeLeasedItem(self.vehicle)
            g_currentMission:addOwnedItem(self.vehicle)

            -- 4. update shop menu so equipment will be displayed as owned now on
            g_currentMission.shopMenu:updateGarageItems()
        end
    end
end
