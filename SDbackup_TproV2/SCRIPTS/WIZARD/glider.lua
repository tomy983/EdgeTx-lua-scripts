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
local VALUE = 0
local COMBO = 1

local edit = false
local page = 1
local current = 1
local pages = {}
local fields = {}

-- load common Bitmaps
local ImgMarkBg = Bitmap.open("img/mark_bg.png")
local BackgroundImg = Bitmap.open("img/background.png")
local ImgPlane = Bitmap.open("img/glider/glider.png")
local ImgPageUp = Bitmap.open("img/pageup.png")
local ImgPageDn = Bitmap.open("img/pagedn.png")


-- Change display attribute to current field
local function addField(step)
  local field = fields[current]
  local min, max
  if field[3] == VALUE then
    min = field[6]
    max = field[7]
  elseif field[3] == COMBO then
    min = 0
    max = #(field[6]) - 1
  end
  if (step < 0 and field[5] > min) or (step > 0 and field[5] < max) then
    field[5] = field[5] + step
  end
end

-- Select the next or previous page
local function selectPage(step)
  page = 1 + ((page + step - 1 + #pages) % #pages)
  edit = false
  current = 1
end

-- Select the next or previous editable field
local function selectField(step)
  repeat
    current = 1 + ((current + step - 1 + #fields) % #fields)
  until fields[current][4]==1
end

-- Redraw the current page
local function redrawFieldsPage(event)

  for index = 1, 10, 1 do
    local field = fields[index]
    if field == nil then
      break
    end

    local attr = current == (index) and ((edit == true and BLINK or 0) + INVERS) or 0
    attr = attr + COLOR_THEME_PRIMARY1

    if field[4] == 1 then
      if field[3] == VALUE then
        lcd.drawNumber(field[1], field[2], field[5], LEFT + attr)
      elseif field[3] == COMBO then
        if field[5] >= 0 and field[5] < #(field[6]) then
          lcd.drawText(field[1],field[2], field[6][1+field[5]], attr)
        end
      end
    end
  end
end

local function updateField(field)
  local value = field[5]
end

-- Main
local function runFieldsPage(event)
  if event == EVT_VIRTUAL_EXIT then -- exit script
    return 2
  elseif event == EVT_VIRTUAL_ENTER then -- toggle editing/selecting current field
    if fields[current][5] ~= nil then
      edit = not edit
      if edit == false then
        updateField(fields[current])
      end
    end
  elseif edit then
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
      addField(1)
    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
      addField(-1)
    end
  else
    if event == EVT_VIRTUAL_NEXT then
      selectField(1)
    elseif event == EVT_VIRTUAL_PREV then
      selectField(-1)
    end
  end
  redrawFieldsPage(event)
  return 0
end

-- set visibility flags starting with SECOND field of fields
local function setFieldsVisible(...)
  local arg={...}
  local cnt = 2
  for i,v in ipairs(arg) do
    fields[c