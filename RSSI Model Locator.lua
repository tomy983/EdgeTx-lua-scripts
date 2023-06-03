---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget script for Jumper T-Pro V2 (oled LCD)                #
---- # Copyright (C) EdgeTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- RSSI Model Locator 
-- Based on code from: Offer Shmuely 2022 (based on code from Scott Bauer 6/21/2015)
-- Thomas Sosio
-- Date: 06/2023
-- ver: 0.4

-- This widget help to find a lost/crashed model based on the RSSI (if still available)
-- The widget produce audio representation (variometer style) of the RSSI from the lost model

-- There are two way to use it
-- 1. The simple way:
--    walk toward the quad/plane that crashed,
--    as you get closer to your model the beeps will become more frequent with higher pitch (and a visual bar graph as well)
--    until you get close enough to find it visually

-- 2. the more accurate way:
--    turn the antenna straight away (i.e. to point from you, straight away)
--    try to find the weakest signal! (not the highest), i.e. the lowest RSSI you can find, this is the direction to the model.
--    now walk to the side (not toward the model), find again the weakest signal, this is also the direction to your model
--    triangulate the two lines, and it will be :-)

local delayMillis = 100
local nextPlayTime = getTime()

-- init_func is called once when model is loaded
local function init()
    return 0
end

local function getSignalValues()
    -- try expressLRS
    local fieldinfo = getFieldInfo("1RSS")
    if fieldinfo then
        local v = getValue("1RSS")
        lcd.drawText(3, 13, "Signal: 1RSS (ELRS)", 0)
        if v == 0 then
            v = -115
        end
        return v, -115, 0
    end

    lcd.drawText(3, 13, "Signal not found in 1RSS", 0)
    return nil, 0, 0
end


local function main(event, touchState) 
    lcd.clear() 
    local signalValue, signalMin, signalMax = getSignalValues()
    if signalValue == nil then        
        playFile("/SCRIPTS/TOOLS/telemko.wav")
        lcd.drawText(3, 28, "Qualcosa non va", 0)
        return
    end

    -- Title
    lcd.drawText(3, 3, "RSSI Model Locator", 0)
    
    local signalPercent = 100 * ((signalValue - signalMin) / (signalMax - signalMin))

    -- draw bar
    lcd.drawGauge(3, 40, 115, 5, signalPercent, 100)
    lcd.drawText(3, 50, "YOU CAN FIND IT!", 0)
    if signalPercent == 0 then
        lcd.drawText(3, 28, "NO SIGNAL")
    else
        lcd.drawNumber(3, 28, signalPercent)
        lcd.drawText(15, 28, "%")
    end

    -- beep or messge  
    if getTime() >= nextPlayTime then
        if signalPercent == 0 then
            playFile("/SCRIPTS/TOOLS/telemko.wav")
            nextPlayTime = getTime() + 800            
            playHaptic(10, 2)
            playHaptic(6, 10)
        else
            -- write current value            
            playFile("/SCRIPTS/TOOLS/Model Locator (by RSSI).wav")
            playHaptic(3, delayMillis - signalPercent, PLAY_NOW)
            nextPlayTime = getTime() + delayMillis - signalPercent   
        end
    end

    return 0
end

return { init = init, run = main }
