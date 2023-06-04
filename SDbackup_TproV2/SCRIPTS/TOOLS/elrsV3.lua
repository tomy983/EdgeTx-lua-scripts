-- TNS|ExpressLRS|TNE
---- #########################################################################
---- #                                                                       #
---- # Copyright (C) OpenTX                                                  #
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
local deviceId = 0xEE
local handsetId = 0xEF
local deviceName = ""
local lineIndex = 1
local pageOffset = 0
local edit = nil
local charIndex = 1
local fieldPopup
local fieldTimeout = 0
local loadQ = {}
local fieldChunk = 0
local fieldData = {}
local fields = {}
local devices = {}
local goodBadPkt = "?/???    ?"
local elrsFlags = 0
local elrsFlagsInfo = ""
local fields_count = 0
local backButtonId = 2
local exitButtonId = 3
local devicesRefreshTimeout = 50
local folderAccess = nil
local commandRunningIndicator = 1
local expectChunksRemain = -1
local deviceIsELRS_TX = nil
local linkstatTimeout = 100
local titleShowWarn = nil
local titleShowWarnTimeout = 100
local exitscript = 0

local COL2
local maxLineIndex
local textXoffset
local textYoffset
local textSize
local byteToStr

local function allocateFields()
  fields = {}
  for i=1, fields_count + 2 + #devices do
    fields[i] = { }
  end
  backButtonId = fields_count + 2 + #devices
  fields[backButtonId] = {name="----BACK----", parent = 255, type=14}
  if folderAccess ~= nil then
    fields[backButtonId].parent = folderAccess
  end
  exitButtonId = backButtonId + 1
  fields[exitButtonId] = {id = exitButtonId, name="----EXIT----", type=17}
end

local function reloadAllField()
  fieldChunk = 0
  fieldData = {}
  -- loadQ is actually a stack
  loadQ = {}
  for fieldId = fields_count, 1, -1 do
    loadQ[#loadQ+1] = fieldId
  end
end

local function getField(line)
  local counter = 1
  for i = 1, #fields do
    local field = fields[i]
    if folderAccess == field.parent and not field.hidden then
      if counter < line then
        counter = counter + 1
      else
        return field
      end
    end
  end
end

local function constrain(x, low, high)
  if x < low then
    return low
  elseif x > high then
    return high
  end
  return x
end

-- Change display attribute to current field
local function incrField(step)
  local field = getField(lineIndex)
  local min, max = 0, 0
  if ((field.type <= 5) or (field.type == 8)) then
    min = field.min or 0
    max = field.max or 0
    step = field.step * step
  elseif field.type == 9 then
    min = 0
    max = #field.values - 1
  end
  field.value = constrain(field.value + step, min, max)
end

-- Select the next or previous editable field
local function selectField(step)
  local newLineIndex = lineIndex
  local field
  repeat
    newLineIndex = newLineIndex + step
    if newLineIndex <= 0 then
      newLineIndex = #fields
    elseif newLineIndex == 1 + #fields then
      newLineIndex = 1
      pageOffset = 0
    end
    field = getField(newLineIndex)
  until newLineIndex == lineIndex or (field and field.name)
  lineIndex = newLineIndex
  if lineIndex > maxLineIndex + pageOffset then
    pageOffset = lineIndex - maxLineIndex
  elseif lineIndex <= pageOffset then
    pageOff