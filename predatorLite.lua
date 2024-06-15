-- 0.5A Patch notes:
-- Removed AI Aggression settings, doesnt work and cant make it work for some reason...

local settings = {
    cl_dataBank = {
        cl_calculateMaxSpeed    = true,             -- By default we want to calculate the max speed possible.
        cl_maxSpeed             = 0,                -- Base figure used in the max speed calculations.
    },
    cl_autoPilot = {                                -- ALL VALUES HERE ARE STORED DEFAULTS FOR AI DRIVING!
        cl_apEnabled            = false,            -- By default we disable the AI driving feature.
        cl_topSpeed             = 250,              -- Default top speed that AI are allowed to drive.
        cl_skill                = 50,               -- Default value for how skillfull a driver the AI is.
        cl_grip                 = 5,                -- Default value for AI grip.
    }, 
    cl_vehicle = {                                  -- ALL VALUES HERE ARE STORED DEFAULTS FOR THE 'VEHICLES' MENU!
        cl_optTires             = false,            -- By default we want to set this to false.
        cl_damage               = false,            -- This is for disabling body and engine damge.
        cl_gearLock             = false,            -- This is used to lock the gear in the chosen value of the user (Max 10)
        cl_power                = 0.0,              -- Default to 0 because this is additional power.
        cl_braking              = 0.0,              -- Default to 0 because this is additional breaking.
        cl_downforce            = 0.0,              -- Default to 0 because this is additional downforce.
        cl_fuel                 = 15,               -- Deafult to 15 so the tank isnt empty if we use it.
        cl_freezeFuel           = -1,               -- This will freeze how much fuel is in the users car.
        cl_chosenGear           = 1,                -- First gear is selected by default.
    },
}

local cl_driversData = {}
local localCar;

function formatTime(ms)
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local milliseconds = ms % 1000
    return string.format("%02d:%02d:%03d", minutes, seconds, milliseconds)
end

function script.windowMain(dt) 
    ui.tabBar("dt", function()
        ui.tabItem("Leaderboard ("..ac.getSim().connectedCars..")", function()   
            for i, cl_data in ipairs(cl_driversData) do
                if cl_data.cl_carData then
                    local cl_lookVectors = ac.getCar(cl_data.cl_targetSim).look
                    local cl_vectors = {
                        cl_x = -cl_lookVectors.x,
                        cl_y = -cl_lookVectors.y,
                        cl_z = -cl_lookVectors.z,
                    }
                    ui.treeNode(cl_data.cl_driverName, ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                        ui.text(" • Drivers name: "..cl_data.cl_driverName)
                        ui.text(" • Race position: "..cl_data.cl_driverPosition)
                        ui.text(" • Drivers car: "..cl_data.cl_driversCar)  
                        ui.text(" • Current speed: ") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).speedKmh).." kmh")
                        ui.treeNode("Lap information", ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                            ui.text(" • Current lap time:") ui .sameLine() ui.text(formatTime(ac.getCar(cl_data.cl_targetSim).lapTimeMs))
                            ui.text(" • Best lap time:") ui .sameLine() ui.text(formatTime(ac.getCar(cl_data.cl_targetSim).bestLapTimeMs))

                            ui.text(" • Lap count:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).lapCount))
                        end)
                        ui.treeNode("Specific vehicle information", ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                            ui.text(" • Total vehicle mass:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).mass).." KG")
                            ui.text(" • Steering lock angle:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).steerLock).." Degrees")
                            ui.text(" • Maximum vehicle fuel:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).maxFuel).." L")
                            ui.text(" • Remaining fuel:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).fuel).." L")
                            ui.text(" • Vehicle gear count:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).gearCount))
                            ui.text(" • Turbo/s count:") ui .sameLine() ui.text(math.floor(ac.getCar(cl_data.cl_targetSim).turboCount))
           
                        end)
                        ui.separator()
                        ui.text("Online player controls:") ui.sameLine()
                        if cl_data.cl_driverName == ac.getDriverName(0) then
                            if ui.button("Cancel spectating") then 
                                ac.focusCar(0) 
                            end 
                        end
                        if cl_data.cl_driverName ~= ac.getDriverName(0) then
                            if ui.button("Spectate") then 
                                ac.focusCar(cl_data.cl_targetSim) 
                            end ui.sameLine()
                        end          
                        ui.separator()
                    end)
                end
            end
            table.clear(cl_driversData)
            if ui.button("Sort by race position") then
                table.sort(cl_driversData, function(a, b) return a.cl_driverPosition < b.cl_driverPosition end)
            end
        end)
        ui.tabItem("Vehicle", function()
            ui.treeNode("Gears", ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                if ui.radioButton("Lock selected gear", settings.cl_vehicle.cl_gearLock) then settings.cl_vehicle.cl_gearLock = not settings.cl_vehicle.cl_gearLock end
                local currentGear, hasGearChanged = ui.slider("     ", settings.cl_vehicle.cl_chosenGear, 0, ac.getCar(0).gearCount, "%.f - Chosen gear")
                if hasGearChanged then 
                    settings.cl_vehicle.cl_chosenGear = currentGear 
                    settings.cl_vehicle.cl_gearLock = false
                end
            end)
            ui.treeNode("Fuel", ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                if ui.radioButton("Freeze fuel amount", settings.cl_vehicle.cl_freezeFuel >= 0) then settings.cl_vehicle.cl_freezeFuel = settings.cl_vehicle.cl_freezeFuel > 0 and -1 or localCar.fuel end
                local currentFuel, hasFuelChanged = ui.slider("  ", settings.cl_vehicle.cl_fuel, 0, ac.getCar(0).maxFuel, "%.0fkg - Fuel")
                if hasFuelChanged then settings.cl_vehicle.cl_fuel = currentFuel physics.setCarFuel(0, currentFuel) end
            end)
            ui.treeNode("Handling", ui.TreeNodeFlags.DefaultOpen and ui.TreeNodeFlags.Framed, function ()
                if ui.radioButton("Optimal tire temperatures", settings.cl_vehicle.cl_optTires) then settings.cl_vehicle.cl_optTires = not settings.cl_vehicle.cl_optTires end
                local currentDownforce, hasChangedDownforce = ui.slider(" ", settings.cl_vehicle.cl_downforce, 0, 250, "%.0fkg - Downforce")
                if hasChangedDownforce then settings.cl_vehicle.cl_downforce = currentDownforce end 
                local currentPassive, hasChangedPassive = ui.slider("   ", settings.cl_vehicle.cl_power, 0, 10, "x%.1f - Power")
                if hasChangedPassive then settings.cl_vehicle.cl_power = currentPassive end
                local currentBrake, hasChangedBrake = ui.slider("    ", settings.cl_vehicle.cl_braking, 0, 10, "+%.1fnm - Braking")
                if hasChangedBrake then settings.cl_vehicle.cl_braking = currentBrake end
            end)
            ui.text("Other options:")
            if ui.radioButton("Disable body and engine damage", settings.cl_vehicle.cl_damage) then settings.cl_vehicle.cl_damage = not settings.cl_vehicle.cl_damage end   
            ui.separator()
        end)
        ui.tabItem("Auto-pilot", function()     
            if ui.checkbox("Enable 'Auto-Pilot'", settings.cl_autoPilot.cl_apEnabled) then
                settings.cl_autoPilot.cl_apEnabled = not settings.cl_autoPilot.cl_apEnabled
                physics.setCarAutopilot(settings.cl_autoPilot.cl_apEnabled)
            end
            local currentSkill, hasChangedSkill = ui.slider(" ", settings.cl_autoPilot.cl_skill, 0, 100, "AI Skill - %.0f%% ")
            if hasChangedSkill then
                settings.cl_autoPilot.cl_skill = currentSkill
                physics.setAILevel(0, currentSkill * 1000)
            end
            local currentAiGrip, hasAIGripChanged = ui.slider("   ", settings.cl_autoPilot.cl_grip, 0, 100, "AI Grip - x%.0f%%")
            if hasAIGripChanged then
                settings.cl_autoPilot.cl_grip = currentAiGrip
                physics.setExtraAIGrip(0, settings.cl_autoPilot.cl_grip / 4.5)         
            end 
            if settings.cl_dataBank.cl_calculateMaxSpeed then
                ui.sameLine()
                ui.text("Calculated top: "..math.floor(settings.cl_dataBank.cl_maxSpeed).."kmh")
            end
        end)
    end)
end

function script.update(dt)
    if settings.cl_dataBank.cl_calculateMaxSpeed then
        if settings.cl_dataBank.cl_maxSpeed < ac.getCar(0).drivetrainSpeed then
            settings.cl_dataBank.cl_maxSpeed = ac.getCar(0).drivetrainSpeed
        end
    end
    localCar = ac.getCar(0)
    if settings.cl_vehicle.cl_downforce > 0 then physics.addForce(0, vec3(0, 0, 0), true, vec3(0, -settings.cl_vehicle.cl_downforce * 9.8 * dt * 100, 0), true) end
    if settings.cl_vehicle.cl_optTires then local temp = ac.getCar(0).wheels[0].tyreOptimumTemperature physics.setTyresTemperature(0, ac.Wheel.All, temp) end
    if settings.cl_vehicle.cl_damage then physics.setCarBodyDamage(0, vec4(0, 0, 0, 0)) physics.setCarEngineLife(0, 1000) end
    if settings.cl_autoPilot.cl_topSpeed then physics.setAITopSpeed(0, settings.cl_autoPilot.cl_topSpeed) end
    if settings.cl_vehicle.cl_freezeFuel >= 0 then physics.setCarFuel(0, settings.cl_vehicle.cl_fuel) end
    if settings.cl_vehicle.cl_gearLock then physics.engageGear(0, settings.cl_vehicle.cl_chosenGear) end
    if settings.cl_vehicle.cl_power > 0 and (localCar.gear > 0) and (localCar.rpm + 200 < localCar.rpmLimiter) then
        local passivePush = settings.cl_vehicle.cl_power * localCar.mass * localCar.gas * dt * 100     
        physics.addForce(0, vec3(0, 0, 0), true, vec3(0, 0, passivePush), true)
    end
    if settings.cl_vehicle.cl_braking > 0 and (localCar.speedKmh > 5) then
        local passivePush = settings.cl_vehicle.cl_braking * localCar.mass * localCar.brake * dt * 100
        passivePush = localCar.localVelocity.z > 0.0 and -passivePush or passivePush     
        physics.addForce(0, vec3(0, 0, 0), true, vec3(0, 0, passivePush), true)
    end
    for i = 0, ac.getSim().carsCount - 1 do
        if ac.getDriverName(i) ~= "" then
            table.insert(
                cl_driversData, {
                    cl_targetSim = i,
                    cl_driverName = ac.getDriverName(i),
                    cl_driverPosition = ac.getCar(i).racePosition,
                    cl_driversCar = ac.getCarName(i),
                    cl_carData = ac.getCar(i).isConnected,              
                }
            )
        end   
    end
end