--
-- FS22 - LeaseToOwn mod
--
-- LeaseToOwnEvent.lua
--
-- @Author: Bodzio528
--
local logger = Logger.create(LeaseToOwn.MOD_NAME)
logger:setLevel(Logger.INFO)

LeaseToOwnEvent = {}
local LeaseToOwnEvent_mt = Class(LeaseToOwnEvent, Event)

InitEventClass(LeaseToOwnEvent, "LeaseToOwnEvent")

---Create instance of Event class
-- @return table self instance of class event
function LeaseToOwnEvent.emptyNew()
    local self = Event.new(LeaseToOwnEvent_mt)

    logger:debug("LeaseToOwnEvent:emptyNew")

    return self
end

---Create new instance of event
-- @param table vehicle vehicle
function LeaseToOwnEvent.new(vehicle, farmId, price)
    logger:debug("LeaseToOwnEvent:new")

    local self = LeaseToOwnEvent.emptyNew()
    self.vehicle = vehicle
    self.farmId = farmId
    self.price = price
    return self
end

function LeaseToOwnEvent:writeStream(streamId, connection)
    logger:debug("LeaseToOwnEvent:writeStream")

    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteInt32(streamId, self.price)
end

function LeaseToOwnEvent:readStream(streamId, connection)
    logger:debug("LeaseToOwnEvent:readStream")

    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.price = streamReadInt32(streamId)

    self:run(connection)
end

function LeaseToOwnEvent:run(connection)
    logger:debug("LeaseToOwnEvent:run")

    if not connection:getIsServer() then
        logger:debug("LeaseToOwnEvent: this is client")

        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            local player = g_currentMission:getPlayerByConnection(connection)
            local farmAllowed = player ~= nil and g_currentMission:getHasPlayerPermission("farmManager", connection, player.farmId)
            if player ~= nil and player.farmId > 0 and farmAllowed then
                local isLeased = (self.vehicle:getPropertyState() == VehiclePropertyState.LEASED)
                if isLeased and player.farmId == self.vehicle:getOwnerFarmId() then
                    if self.price > 0 then
                        local money = g_currentMission:getMoney(self.farmId)
                        if money < self.price then
                            logger:debug("LeaseToOwnEvent: Not enough money on the farm! Aborting.")
                            return
                        end
                    end
                    -- at this point all requirements are fulfilled

                    -- 1. deduct money from account
                    g_currentMission:addMoney(-self.price, self.farmId, MoneyType.SHOP_VEHICLE_BUY, true, true)

                    -- 2. change ownership of vehicle
                    setVehicleOwned(self.vehicle)

                    -- 3. broadcast event so others will know
                    g_server:broadcastEvent(self, true)
                else
                    logger:debug("LeaseToOwnEvent: vehicle is NOT leased - abort!")
                end
            end
        end
    else -- this is server
        logger:debug("LeaseToOwnEvent: this is server")

        if self.vehicle ~= nil then
            setVehicleOwned(self.vehicle)
        end
    end
end

function setVehicleOwned(vehicle)
    vehicle.propertyState = VehiclePropertyState.OWNED
    g_currentMission:removeLeasedItem(vehicle)
    g_currentMission:addOwnedItem(vehicle)
end