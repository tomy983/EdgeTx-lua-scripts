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
-- Plane Wizard pages
local ENGINE_PAGE = 0
local AILERONS_PAGE = 1
local FLAPERONS_PAGE = 2
local BRAKES_PAGE = 3
local TAIL_PAGE = 4
local CONFIRMATION_PAGE = 5

-- Navigation variables
local page = ENGINE_PAGE
local dirty = true
local edit = false
local field = 0
local fieldsMax = 0

-- Model settings
local engineMode = 1
local thrCH1 = 0
local aileronsMode = 1
local ailCH1 = 0
local ailCH2 = 5
local flapsMode = 0
local flapsCH1 = 6
local flapsCH2 = 7
local brakesMode = 0
local brakesCH1 = 8
local brakesCH2 = 9
local tailMode = 1
local eleCH1 = 0
local eleCH2 = 4
local rudCH1 = 0
local servoPage = nil

-- Common functions
local lastBlink = 0
local function blinkChanged()
  local time = getTime() % 128
  local blink = (time - time % 64) / 64
  if blink ~= lastBlink then
    lastBlink = blink
    return true
  else
    return false
  end
end

local function fieldIncDec(event, value, max, force)
  if edit or force==true then
    if event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
      value = (value + max)
      dirty = true
    elseif event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
      value = (value + max + 2)
      dirty = true
    end
    value = (value % (max+1))
  end
  return value
end

local function valueIncDec(event, value, min, max)
  if edit then
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
      if value < max then
        value = (value + 1)
        dirty = true
      end
    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
      if value > min then
        value = (value - 1)
        dirty = true
      end
    end
  end
  return value
end

local function navigate(event, fieldMax, prevPage, nextPage)
  if event == EVT_VIRTUAL_ENTER then
    edit = not edit
    dirty = true
  elseif edit then
    if event == EVT_VIRTUAL_EXIT then
      edit = false
      dirty = true
    elseif not dirty then
      dirty = blinkChanged()
    end
  else
    if event == EVT_VIRTUAL_NEXT_PAGE then
      page = nextPage
      field = 0
      dirty = true
    elseif event == EVT_VIRTUAL_PREV_PAGE then
      page = prevPage
      field = 0
      killEvents(event);
      dirty = true
    else
      field = fieldIncDec(event, field, fieldMax, true)
	end
  end
end

local function getFieldFlags(position)
  flags = 0
  if field == position then
    flags = INVERS
    if edit then
      flags = INVERS + BLINK
    end
  end
  return flags
end

local function channelIncDec(event, value)
  if not edit and event==EVT_VIRTUAL_MENU then
    servoPage = value
    dirty = true
  else
    value = valueIncDec(event, value, 0, 15)
  end
  return value
end

-- Init function
local function init()
  rudCH1 = defaultChannel(0)
  eleCH1 = defaultChannel(1)
  thrCH1 = defaultChannel(2)
  ailCH1 = defaultChannel(3)
end

-- Engine Menu
local engineModeItems = {"No", "Yes"}
local function drawEngineMenu()
  lcd.clear()
  if engineMode == 1 then
    -- 1 channel
    lcd.drawText(5, 30, "Assign channel", 0);
    lcd.drawText(5, 40, ">>>", 0);
    lcd.drawSource(25, 40, MIXSRC_CH1+thrCH1, getFieldFlags(1))
    fieldsMax = 1
  else
    -- No engine
    fieldsMax = 0
  end
  lcd.drawText(1, 0, "Got an engine?", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawCombobox(0, 8, LCD_W, engineModeItems, engineMode, getFieldFlags(0))
end

local function engineMenu(event)
  if dirty then
    dirty = false
    drawEngineMenu()
  end

  navigate(event, fieldsMax, page, page+1)

  if field==0 then
    engineMode = fieldIncDec(event, engineMode, 1)
  elseif field==1 then
    thrCH1 = channelIncDec(event, thrCH1)
  end
end

-- Ailerons Menu
local aileronsModeItems = {"No", "Yes, 1 channel", "Yes, 2 channels"}
local function drawAileronsMenu()
  lcd.clear()
  if aileronsMode == 2 then
    -- 2 channels
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(30, 40, "L", 0);
    lcd.drawText(65, 40, "R", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+ailCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+ailCH2, getFieldFlags(2))
    fieldsMax = 2
  elseif aileronsMode == 1 then
    -- 1 channel
    lcd.drawText(5, 30, "Assign channel", 0);
    lcd.drawText(5, 40, ">>>", 0);
    lcd.drawSource(25, 40, MIXSRC_CH1+ailCH1, getFieldFlags(1))
    fieldsMax = 1
  else
    -- No ailerons
    fieldsMax = 0
  end
  lcd.drawText(1, 0, "Got ailerons?", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawCombobox(0, 8, LCD_W, aileronsModeItems, aileronsMode, getFieldFlags(0))
end

local function aileronsMenu(event)
  if dirty then
    dirty = false
    drawAileronsMenu()
  end

  navigate(event, fieldsMax, page-1, page+1)

  if field==0 then
    aileronsMode = fieldIncDec(event, aileronsMode, 2)
  elseif field==1 then
    ailCH1 = channelIncDec(event, ailCH1)
  elseif field==2 then
    ailCH2 = channelIncDec(event, ailCH2)
  end
end

-- Flaps Menu
local flapsModeItems = {"No", "Yes, 1 channel", "Yes, 2 channels"}
local function drawFlapsMenu()
  lcd.clear()
  if flapsMode == 0 then
    -- no flaps
    fieldsMax = 0
  elseif flapsMode == 1 then
    -- 1 channel
    lcd.drawText(5, 30, "Assign channel", 0);
    lcd.drawText(5, 40, ">>>", 0);
    lcd.drawSource(25, 40, MIXSRC_CH1+flapsCH1, getFieldFlags(1))
    fieldsMax = 1
  elseif flapsMode == 2 then
    -- 2 channels
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(30, 40, "L", 0);
    lcd.drawText(65, 40, "R", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+flapsCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+flapsCH2, getFieldFlags(2))
    fieldsMax = 2
  end
  lcd.drawText(1, 0, "Got flaps?", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawCombobox(0, 8, LCD_W, flapsModeItems, flapsMode, getFieldFlags(0))
end

local function flapsMenu(event)
  if dirty then
    dirty = false
    drawFlapsMenu()
  end

  navigate(event, fieldsMax, page-1, page+1)

  if field==0 then
    flapsMode = fieldIncDec(event, flapsMode, 2)
  elseif field==1 then
    flapsCH1 = channelIncDec(event, flapsCH1)
  elseif field==2 then
    flapsCH2 = channelIncDec(event, flapsCH2)
  end
end

-- Airbrakes Menu
local brakesModeItems = {"No", "Yes, 1 channel", "Yes, 2 channels"}
local function drawBrakesMenu()
  lcd.clear()
  if brakesMode == 0 then
    -- no brakes
    fieldsMax = 0
  elseif brakesMode == 1 then
    -- 1 channel
    lcd.drawText(5, 30, "Assign channel", 0);
    lcd.drawText(5, 40, ">>>", 0);
    lcd.drawSource(25, 40, MIXSRC_CH1+brakesCH1, getFieldFlags(1))
    fieldsMax = 1
  elseif brakesMode == 2 then
    -- 2 channels
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(30, 40, "L", 0);
    lcd.drawText(65, 40, "R", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+brakesCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+brakesCH2, getFieldFlags(2))
    fieldsMax = 2
  end
  lcd.drawText(1, 0, "Got air brakes?", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawCombobox(0, 8, LCD_W, brakesModeItems, brakesMode, getFieldFlags(0))
end

local function brakesMenu(event)
  if dirty then
    dirty = false
    drawBrakesMenu()
  end

  navigate(event, fieldsMax, page-1, page+1)

  if field==0 then
    brakesMode = fieldIncDec(event, brakesMode, 2)
  elseif field==1 then
    brakesCH1 = channelIncDec(event, brakesCH1)
  elseif field==2 then
    brakesCH2 = channelIncDec(event, brakesCH2)
  end
end

-- Tail Menu
local tailModeItems = {"Ele(1)", "Ele(1) + Ruder(1)", "Ele(2) + Ruder(1)", "V-Tail(2)"}
local function drawTailMenu()
  lcd.clear()
  if tailMode == 0 then
    -- Elevator(1ch), no rudder...
    lcd.drawText(5, 30, "Assign channel", 0);
    lcd.drawText(5, 40, ">>>", 0);
    lcd.drawSource(25, 40, MIXSRC_CH1+eleCH1, getFieldFlags(1))
    fieldsMax = 1
  elseif tailMode == 1 then
    -- Elevator(1ch) + rudder...
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(25, 40, "Ele", 0);
    lcd.drawText(60, 40, "Rud", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+eleCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+rudCH1, getFieldFlags(2))
    fieldsMax = 2
  elseif tailMode == 2 then
    -- Elevator(2ch) + rudder...
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(25, 40, "EleL", 0);
    lcd.drawText(60, 40, "EleR", 0);
    lcd.drawText(95, 40, "Rud", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+eleCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+eleCH2, getFieldFlags(2))
    lcd.drawSource(95, 50, MIXSRC_CH1+rudCH1, getFieldFlags(3))
    fieldsMax = 3
  else
    -- V-Tail...
    lcd.drawText(5, 30, "Assign channels", 0);
    lcd.drawText(25, 40, "VtaL", 0);
    lcd.drawText(60, 40, "VtaR", 0);
    lcd.drawText(5, 50, ">>>", 0);
    lcd.drawSource(25, 50, MIXSRC_CH1+eleCH1, getFieldFlags(1))
    lcd.drawSource(60, 50, MIXSRC_CH1+eleCH2, getFieldFlags(2))
    fieldsMax = 2
  end
  lcd.drawText(1, 0, "Tail config", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawCombobox(0, 8, LCD_W, tailModeItems, tailMode, getFieldFlags(0))
end

local function tailMenu(event)
  if dirty then
    dirty = false
    drawTailMenu()
  end

  navigate(event, fieldsMax, page-1, page+1)

  if field==0 then
    tailMode = fieldIncDec(event, tailMode, 3)
  elseif field==1 then
    eleCH1 = channelIncDec(event, eleCH1)
  elseif (field==2 and tailMode==1) or field==3 then
    rudCH1 = channelIncDec(event, rudCH1)
  elseif field==2 then
    eleCH2 = channelIncDec(event, eleCH2)
  end
end

-- Servo (limits) Menu
local function drawServoMenu(limits)
  lcd.clear()
  lcd.drawSource(1, 0, MIXSRC_CH1+servoPage, 0)
  lcd.drawText(25, 0, "servo min/max/center/direction?", 0)
  lcd.drawFilledRectangle(0, 0, LCD_W, 8, FILL_WHITE)
  lcd.drawLine(LCD_W/2-1, 8, LCD_W/2-1, LCD_H, DOTTED, 0)
  lcd.drawText(LCD_W/2-19, LCD_H-8, ">>>", 0);
  lcd.drawNumber(140, 35, limits.min, PREC1+getFieldFlags(0));
  lcd.drawNumber(205, 35, limits.max, PREC1+getFieldFlags(1));
  lcd.drawNumber(170, 9, limits.offset, PREC1+getFieldFlags(2));
  if limits.revert == 0 then
    lcd.drawText(129, 50, "\126", getFieldFlags(3));
  else
    lcd.drawText(129, 50, "\127", getFieldFlags(3));
  end
  fieldsMax = 3
end

local function servoMenu(event)
  local limits = model.getOutput(servoPage)

  if dirty then
    dirty = false
    drawServoMenu(limits)
  end

  navigate(event, fieldsMax, page, page)

  if edit then
    if field==0 then
      limits.min = valueIncDec(event, limits.min, -10 *O-ñ+¡+­.ó'«!>+]¯ iû3÷èğSæ ÙºĞÍÈë¾*¶a¬X¦	¨vªñ£Ñ›ÿ$¯¼E» ¸ÃØ‚çYğ+öÊü—
¦+/<3j<&FLQ R£RGQ;OØMªM[Fú;=2â+D&ir6;ıû ÷{í0á¨Şûá‡âYŞ`Ü"à¦æNèAï¡÷-ü£ı% /!L!Ä)ñ193m*„'u)ß*£%ÿ7‡ »¹ù¿çşáßâêİbĞ’ÄR¼Ñ¸,µ$¯J¨k¢¯œ šg¢g«9±ı°¾°º¿Ïàæ&æìá cÙ%“! %
8\H(M7NÔL´NVˆZöTÊL›E²@‹=}8. Y1y= .øŸñÑé×âyä*âŞæİ,á`áéâ ê÷ú¢ùÃÿ9
=: ş ”C Ô,ó5;1](Î' (c'”$;Ğç	Œ°ÿ‹õ!êâeİ¨ÙXÓÅT¹ ºÂº2²b©Ï¤h£—¥/§ß«!³¹Bº Á‡ÏĞßÿç ë¨ñ"I× @$Û(|3×?vI§L©HÙH¯Q!S8M Då@ç>¨8B-­'Â èè€tÿ ù|ğéÜäLâ ä,ã½ßôŞláOç¯î»õIùû¸ÿO'Ø # '!0ş4á2ó+´+9,O*@%s 3mxÎ(ûÏğ èßi×ŠÑŒÌ:Å°¿¹ë¯¥©R«C±K¬Å KŸ° ¿ªÄÇ¼$¾ñÏºélöò|ï˜(ò('m/_? L	L.FQEkK{M6KùD>>™5Z0,'Ù şğş_û1ïÄâUŞµâ:ã2ß^ÚÛàéæ“ê}ğõ ù~Ã²Ø¨*ã1ü.-Ê-D4é95Ì%x """k_şòû1ü#óéãáÖØ!ÚoÑyÃÙ¼Jº ºO·Æ¯½ªñªW¯Á®ñ¯º¹¸Å¦ÅÕÇıÒÆàQè—ô ı® ½ßº'Œ*G08´?`D²H:FÀD±FIÉC <¶5¼34.¼%¥U'
Xkù[õõğEëkåã ãâ÷İoßKæríï“í¥õªh©³f#- +()Ğ0^20ä*%Öøršô	ÎşôEğ íêÍàÁÔ9ÑFÒçÌƒÅ›À½ö»=¹³1¯e²t´ °+³’ÁÉ¦ÅÇŸÖñê·òyïñ% 7 /©A‚A±<Å>»EòH»GNC=›8¤7¤1+)ó"Š ´»	Ò¿ú¤ò‘ğLğxîpê´ã’à¬çÏîğÇî ñ:øoiùZG”+¹.x,ô*@-a3¯6Ä. "˜"q „·÷üíúŒó°ç<ßÜÿÚnØNÎ ÆÆzÆÖÁa¹ç³ûµ«·²Ö­!¯Ò¸•Â°ÅšÁŒÄ Óçëªèíküîúq%1¼: ;ú:>= BCd@Ø=m<ï3B-Ï+_). mvMßÿ	ø ôÎòîNèæàç¥éHëëÓì.óŠú-£è êÒ%,s,=,Ú/(4.5ß2Œ+±%®%õ&
• 	Aânÿ¦ò3é;ä[âyß~Ø~ÎıÇÅ­Ã,Äİ¿ ³ªª³»¼{µõ§Gªí¸ØÇ‰Ê1ÃàÁ ÓCë)ô‰í îU ÿ§(fo'?7•?¨?²:ô;’B^GtD$> 6é2ä1]/2)2ş^Lü	vş‡óÿğõñeïêè ã™ã0ë«ï)é1è¸ôN}Ù"¯ü$ú! %
4:7ì/1+*À/U1),Ã»[©ÿëô î4í†èæİÑÕIÔzÏÆåÂ£Ä£À˜µ«®©°@µ³ ­Ê§­m¾[ÊûÄO¾½É9àtì_íJğÏùñC "«$†,$8¤@+>Á>4D%I)Dt>\<<Ï6÷.á&  yÙW;! 
ú`ò'ğsî_ë½è‰æŠèhí ï–íPóşï+,Ld—&,(p(-›. 12Q(ê"ó&ÁÄÓåg¸ø”î˜è³áùÛ ÚØAÏÇmÄõÃ©ÃÔÀI·­°F¹©ºi°n¬À¶ ÆÃÌìË¾É’ĞnââõCùŠñ†÷“*!i#e e$1 ='Dì@ø9q=ˆG`G>ó7ƒ3Û/ª-@+!$ <M ?øØôéòBîCëê(é_çè¢ëQõ5ù4ô öM·L,±¶#h-C-E'n&½.¨843×%²! &w%~‘üDûy÷*í\á»Û&ÜÛwÔË Ä-ÃøÅSÃá¸Ğ±ñ³¹R¸Å¯Ò«Ñ´À‡ÅuÈ˜È ËdÙîìmóáï¼ò:aAS"*Û8U>6;8 ?E¨B1<97¦3¤1
-¼#ºÃG¹ ûwõöóVóxñƒí4ëÃë:ñ¾óØòüòù¶üß 	ì"Ó"ã×&-3-í*9.i-N**(z#Iğ ßüû&÷MíÀävİ%Ú_Ú1ÖèÌÖÇÈÔÈ Åv¿½c»v·M¸F»j·r´±·l¾TÇ—Ğ´ÍsÊ Ø ï•ó›í“ñØû9Ğ‚æ#&7i>a7ê1¾9ˆB BË<73~2è3/„$¦³Ey§
æ›üœ÷ ø…ø òjì—ììğÁóòˆóKø*üŞÿ‚
£5D Y(_)S%a$}(©1Î3ˆ*üû!†(Å$ş?7  }õ°òsì8å1á)ÜªÔÓìĞ®ËŞÅwÆ*ÇêÃ ¼Ø¹˜¼ê¿M¼·‡·r»¶Â¥Ì÷Ï+ÌpÒã¶íî ñú{²agˆ(5â53ı4Å;Î=<§8 6a23/·,;)ü"‰¨¿’då *üÅùQ÷Œó ğ›ïıï‹ï©îğxó+ö&øBû´¬EˆuÑ ':&›#O'Ø-Ö03.\&Œ"è&å%L½õ" ûá÷¼ñ©éúä–áfİ!ÙvÓmÏzÏĞjÌPÅ“ÃÈ ÇRÀî¼½]¿TÂ¬Âï¾ŒÃÌÎâÖÙÔÕÖá	ïjô öŠûÅT,.³&2¶54Ü7y;::˜< 70m.d.¯(1!FÜEhŸ<¶ı÷ùRø‡÷ õHòîSïEõ®÷Ùô)öxıË.¬ä(65  "ñ!U$,'Æ(t(C&"ù Ù¸›qµş ÷Úö‡óëâ–àßõÙÔDĞÃÌÊËÊËÈâÃë¾ Á£Â	Àg»ïº,¼Ã3ÈÁÈ@ÉŠÑ>İEâ#ä¡ëù÷ ş2ŸôÊØ Ã&2-¼.`3^8¿99÷8¤9	9 5/k,);&j†&ö9
æCgşÂù¹ô‹ó öLóî¡îõùø–÷xüUª
rLÖß— $ı ™œ '#+E'`·±˜!ØË
¯á[ üsôî²ê]ë©ç1ßê×VØŞØÕõĞãÏäËyÈ™Ê Ë¬Æ#Á_Â¥ÃrÃÙÄõÅÃÊŞÕbÙ…ÔÚ–èÖñ ò›øE Lå›7©((1t33=5y7¬8[; 9Q3}./Ó-}(!¼!Q.fÙÿ¤ÿ€ÿ ıKø>ô–õœú~ü5úUùRüôØv		®F İ´=ê"Å"Á-7K”h×Ü	¤œ ûóœíìTëRãÚìÖäØ×{ĞĞÊ¦É5ÊËÊèÇ ÂÀmÃhÆ”Â&¾†À
Ç¦ËòÏEÓûÓ¼Ùİäéì«ï ôOüÁÃŸç#`-335‹4z6ä<›>: 66ü4¯1+a'#)©˜<3¥w ¬ £ı ÷àôô:ôÓõôõïóŞô,ûsşûü/B
ï *¯û8 "¨!ğ,×+~"½ 
û–÷”òìmçuäcàºÛØıÔ³ÓèÒîÒ}ĞÌÎ ÎêÎTÎÑüĞÂÊïÆAÊ…Î+Ï«ÏÍÌVÌÉ×¿äjà Ù…ä;õ÷úåú(ÿL<¶. àãÆ/²6‹/ø/ 8	;Í7—808V2½0¦0Š,–%¼ vÁ{¦
 „éÿıÆúøß÷À÷Xö–÷ûõú`ûÛÿ= 
 ùÈISô!œo.*Gß Š{LüGùí÷@ô¦ì»ä°âDä±â„ÛcÖàÖÌ× Ô=ÒÒĞ2ÍÍVÎ›ÌçÉ‰Ê·ÌËgË¦Ñ®Ö<× Ù¹à?æ™ë®óÖøaúö¶±-2#n(Û+|/ 2L3x46Ù6‚5·2“0l.R*¸&#‹ƒDÒ bğÿ)o pöÒñÅôÇù|ù2ôğöÆ Cú ıw¢	Ô]yGğ¶*P3  Õ¬Ñcwø:õØö#ú	ó+ælßÚå&éQá ØØ³ØY×/××‘ÑòËRÎpÑñÏÁÍBÍEÊ”ÉnÏ ÕÉÑĞ^ÙâYãGåøëó	úçÏCĞè! ?$i.‹33Ø3ÿ5-7›7‘7+4ı/Ú.V,\&x  }š”%
ŸkÉÿóúõöø0ù<öÖñ4òÏõ ø€ö™öü¾Ùÿ9hËœ¶f¶ø ±{’˜¿Úç7ÿ_õOñ{ñÀï êfä¤ß¦İNŞxßäÚ;ÓÒ¼ÖØˆÔ€ÏÌ9Î‚Ó ÔúÍÒÈ#Í ÕëØ=ÙÈØóÙ:äÓíğgğƒ÷ÿ  %Œ#i)v(A+Â03‰4„3µ12ú2$0 ,['n%`"Ç4˜ggtNôşùµ÷“ù ùsöhòÉó@øúû"üßı/ÿö×e¾	q ^üÊà^"¢Q›ó,Ó éı üø+ğíî´ì¿å³àvßáßkÜÙºØÜØ‰Ø ÕÕ0ÕwÓDĞÎĞ·ÓšÓtÑÒ=×£ÚÜŞ…àâùå ò~÷ê÷Qù9 L¹Ø&z*_,w-Å0%4 3h1E0Ş1 /Ÿ)&\%q!äBDe$¦*  “şÜú·÷LõI÷røËõWòö{ı\ úØú"ª
 Ë3N…wì²~+ê“Gä ‰íÿşù©öXò-îìÆéÜätâãÁŞbÙ_Û ß>Ù|Ó]ÖFÚ\×XÔ¹ÑxÑAÔÕsÑÏòÔ·ÚÙÚ Û*áfäèï$öu÷ûŞİrÏS/"Q& )/*…,I1h1ÿ-¹-0y,d(ø'g&}Ï°L šZjÇÊ »û‹õõ7úªüšõ†ğ÷û Ï  ûûøåA-ÓgbÖ ÒÑ	k`­¿şòúĞõ]õ¹ò íZêoê çäÚâyà0ß¾ßßÒÚ‚Ù3ÛsÜñ×âÔ¾Ó<ÕJÖ Ó¥ÎÒ:ØñØKØ¯ÚLß¡å<ëğíâî²õŞ Ö £<iV Ç%P*Ÿ+Ù-/õ0P3³1c.“-W. +P%J?ÀJõS	³	k?ıÄúæøöú¤ú ÷jóĞö+ıÑşæú@ú7 ã
“.†Æ ?78ÇÄı0›ıD3²ıú$÷ òğïıì…è…å7ä™âEàß‰İ¡ÚÚØÛŠÚ]Ô ÓJ×ØŸÓiĞëÑ–×ØòÖ<×Ûàååãæõç±î öšûïş@	¦bˆï†&İ*[*}*Ç+K/ /¾+É(É)(¸$CØıe4—¦Üø	  Ûş»û ù×úDúƒûü×ııÿ®±á! 7¡½ß™#¤°"|ùYò	I Rı úº÷î÷>÷„ñwë;éëìèğá àÄã åÉâPŞãÜ°ŞÛâá¢ÛüØ2İàJÜ×¿ÖüØxÜ ßğÜsÙïŞ›è.íÖèõè‡ñıIÿ ‡ö	,ë »ºv&Æ*_(é&²(Ê,n-à+ı&\$S$4&! ±óØä¢Üv’A ¯şşX áş5ÿ·'å_¤`	ˆ I	¾' ×	”	CşÔ¸ µ fÿeû{÷ö@õ¨óKğ îgìòébévéÑæËã°ââkà‘ßKàÎİÆÙ/Ù$Ü ÛæÖqÒ<Ö[ÜÛ¨ÖáÙVá(åRå¶ç®ìróŞù5ı şcÍEãN•×"•$‰&¬),ƒ,ª,Â+Ø) *Ü)F%!§ç–êJW®3Z>ş üı…ıÛıŒü7ùüoyÜûn ÊX	fä© ó
	ŞµD¹ıCLZş>Dş øöŞõÂóòOíøêGësê–æúãÍãèäNäôá@ß ŞËâ	ã Ş®Úİwá~ßiØ|Øàïâİ¥Ú…áKé êmèøèRñ¿ú¼ûmù¹şÜ	§q B8µ<" $Š$n',+E+q(Ú'§(M'±&š$¥Îë–Ä ÇM
œZğ­¦ÿ< ïÿğşqüiı =ÿpı?ÊÓ4öjm¶Ûãë|ø \
¸N ÿN}şø
ö¿õ$ö:óŸîJê é—ê_ê¢åNá®áåå÷àfŞìßæááYßDİTİ İ‚ŞßØİ,ÛçİŸâøä›ããÊæíóğòšòK÷ ®O
YØšìí e%$Ö"7%£$›& 'µ%½ Ä!…!—–½×œE	g² q8;şı¢ı…“·şşıh}ãÛî6 ±[çk	×	6«œNõš0ÿıOü ı²ú>øÖöKô›òpò²ğí½ê‰êêté~æå÷ä æMåãWà§á›ããçŞŞÆà6â_àáCã…äå éí³îğô,úÿcÿ”ç	~T®r "Ö#‡ ­$)Q)L%î#Q$Ê&u%ÿ÷8r^ ¬€Gt3, ÿ¿şÿ  ÿ³şÿ<{Eğ³æÍŞÚ CºÂóş%ı}û úWùaøõ;òİğFñ\ğÕí ê´èêTëÿè¢ä ä4èé%å×âşãæAæ ããá âäSã¨áfãµæ§å™ä¥éníRî˜ïFój÷`üÿ 	
TO¯!• ‘ $&¯%^&Å% ##L"t |¦ñóÄx‰¨İJè  Íÿ+ „ÿòşgüüc•  ıŠ  E	®  @uÇ5<P
]	 4  `ıù ö“ö|øAöYïPëîîØñHí9çæé©êèEåUä æ†é„çìäVæ›è)çßå–è—éõå"å¾é¾ë,éüè íÓîïéò´õ¦õpøiş˜= 	ãŞ‡Ü §€A~)!~!Î {D—ÇÕÇÏ ì ñ‡
	;83Ü¬; üé‡a nüw2Èè˜>‚  ıxş;Zûû‡ù÷üşˆú¿öõ ö,ösó¡ğìï ğğï!í$ìUí1í’ëßêSëûêEêZéééŸèç æ]æ»åæ…çvçIæç*ìûî•íÆî[ôıøìûŒı  ëÍ‚çÏñHZ¨4¹w  ²  D³mŸ<ì†X¤©Îù ƒOš Æ D¿ æıEıËÿ^ Wı³ıP{ ,ÿ× Á±ßI“ 0 C‹aı~û¹ıMÿ ûø+øø9÷ÙõuóÎñ"òò¨îì»ìyìhéÈç éXé¾åËä¼ç¼è-çóå”æ%èäèåéQé™ç?é€î ñÄï4ï´ñøoü½ü¸üŠ PizÙ¥Ã Îé‹ç¥»8Ö'MgÌÓ: åRÖG%e	Ÿşé‰S ÿ® ¹· ‹şãı# jüÿŸş7şVÿõÿhÿÛı\ü üåışıOúTù%û6üTùlõôô¹öÚöõóğ{ï ğ-òÇïíNìkìTì6ëgé‡érêê}è¸èØéeé èç(ésêgê£èZêšîï{ïOò]öûö¹ú1ÿŸ  æ	ıœîríœé-YÕ• èƒeş(óEŞ˜`Åšç
 l% `Æÿk Ê7ÿ
şÿüÿ \ EXÌé° íıªşõKşĞûAûæú†ı ü`÷ÏõLùÛúÁöÀô§öùFõàí8ë°ìÔë½é¬ç âEâ¹æåèõä áÆá¬æéäÈáåÔèìfëÁë ï¬ó•õ÷õùøsı™ ‹…ç	¼Ø¼µü †÷Äœâòé ¦&wÜ,ü Î2	¯
µ©	&µîC$£  ’s Kÿ£ aÖ Ğ +!-¯)ˆæ :  Äş·ı¡ürúOøƒ÷ŒõHóñqğğîóê¦é+è ç¬æ¥ä?âsá'ããœá)ßñßâ:ãøá.áâNå çæBæ”éøìïÄñôuö³ú ¬ÄtW ©MÄ.c.ÄŒ! ‘ågÀ hT.Y6ç¶lI®	Ç8! <Â w™g$… á+t^nÊŞJ “'÷ÿ²ıcüû¨ø›öHõóñéïJï”í ìhìÇëşé
èïçèæ¹äîãtã¡âEãJãUââ ã{åæç¼èMêì»îEğüï’ñÕõ†ø ø›ùı Q~ÉP
GgjºsÒ—¬b„ ôp®Åò*¯åì“ÅÁ( ¾
8$Å	¤«
Jj
c9	 M =ãnnª Dÿ¯ı1ıæû±ù³÷¤÷Qö@ó ññ„ğ¡îaíUìZëÈêîézè;ç[ænæRæ4åå åæ×æç™ç?çèiêëKêĞé3ìï§ïqï§ï ñôö±öö÷?úşüÔ ÷ùĞT	¢bB q7„Ôâlÿî±ë~•)– ˜;·ÕÔÖ	*…
HpÉDç «R¸Ë»Æ /q Bÿ ş ıàıGü8ùî÷Ò÷¼öHô5òÙğ‹ğğcîîëSê˜ê êºèoçMç$ç½çVè\èqç•çpé¡êLêÚéë…ì íÍîğuğ÷ñ†ôŞõ®õø©ûÑü…üóşTôÿ âÔ
}ãÛB{ÉC>Ş…– «oËá`Om–é+“¦X “Œµ
²£Ü¼Ó¼ÿ‰şÅıEü‚ú´ù‚ù ø÷Úõïôêôïôsó”ñ^ñ6òƒòñbğ‚ğÆğ¸ğ ğ{ïèï®ğ»ïÌîNï6ğŠğÙïï¢îcï¿ğ‚ğÒï ğ òòòó-õ(õ õÆõ÷øøàùZú|ûÈıÎÿ b“ÓKƒÂ1	‹Š»gd-öÖ ¿IZĞTE0l›I¿d¡ İ9Ğ
*	®	V
­ºO†ÄT¢  «şAşğımıœûúğù4ûøúøöòöOø÷õ ôƒõFõ«ôõUô	óHòòŞñêğñêğØïÀïùğ ñêğjñÄò:óéóÂõÒö‹öïöÿø7úÚùeù ú)û üßü#ııÿ} ŸÍĞ‰2&(Nc PZèİg	ê	"	O	
î
ø


 ÏÉ
Ì	»	©
õ
Ú	N	'		ÿy	fX’ íÑ¶›°&÷TG—ÿoşÿˆş ü^ú¤ú°ú^ù/øøÍ÷F÷,÷+÷öÚõKöŠö°õ õìõ»õ˜õ#ö0÷Ïö°õ&ö´÷ø†÷4÷»÷øñ÷ øOùæø‘øâùû>ûÀû§ü ıåı¶ÿÃ O  ú Hª¹sÆ“/´âÃ5	 œ×[	+	B/j¹Ó¥€M½ ªëÓ»úáïıÓG7üàq ßÿ»ÿş Õş,ıÕırşéı×üÕûaûüNüÍú ùmú9ûúÓø:ù’ùªøÄ÷{÷F÷U÷c÷è÷ã÷¹÷ ÷şø£ùœù€ù¥ùeúQû üüü°üÙıUş§ı%ş ÿp ïÿ] .}(cRT„˜«ª ÀÃÉö|ƒisˆ="š	i ¾   œ×Ùo\³[ø¡ ¢/,S¹
8  Ø ~ şÿ[ÿ)ÿËşÿ şãıTıŸı±ıKıÕüŞüØüàüÎüııSı8ı`ı ıÓıAş6şØışÂşÿçş\ş8şvşbş[ş”ıı ıÏııı‡ımş¤ş€ş-ÿB 5 ÙÿQ ó I  p ¶ †êÕ éÿ¯ÚÍ	£e »í~€ Ù  Dÿ<ÿ£ÿÿ¶şÀş¤ş şÕşÕşÌş÷ş}ÿìÿ  ~ Î  pxA ˜ˆYŞ t t d K ¸ÿìşŞş”ÿˆÿ¦ş@ş ş+ÿçş[ş şxş‚şOşÓıÒıàış£ıRı™ı ş ş!ş?şàş¼ÿ,   — <-Ä ‡ ¶ Ü s   Ïÿ¬ÿiÿ’ÿqÿ?ÿÕş/ÿwÿmÿÿÿFÿ`ÿŸÿ ÿ)ÿ)ÿêÿøÿmÿdÿ& K &  : O 4 ¹ â   T 1[Ø Í cºªd':¡¢Ö '   ¡ ª ßÿnÿoÿ‘ÿêÿ# ”ÿ6ÿRÿ J ïÿ—ÿ ÿàÿ= ÄÿÆÿbÿtÿçÿ0 |ÿXÿ3ÿ˜ÿÛÿ€ÿÿ şÕşƒÿ¼ÿSÿØşÿ p – f . Æ _Q©   !­ D  
  Ùÿ°ÿƒÿ`ÿqÿ±ÿ±ÿƒÿ ÿîşIÿqÿ$ÿyşcşÏşFÿTÿÜşÌş+ÿÔÿ
 øÿ ÿ‘ÿ+ ¤ k Ìÿ¼ÿÿÿQ   Ìÿÿªÿ      , d ° q  îÿQ  S Êÿäÿ ; <  ÿóÿ* J )  4 . = 
 #    0  /   , 3 ] _ ‡ T g  Š s Z g f Š O   q ‘ o K Œ  U   > n ëÿ¿ÿÈÿ    - åÿÚÿ ‘ Š # øÿ%  }  Ûÿ L   êÿØÿ S (  óÿ4 9 6      %   : íÿæÿ J  ïÿÛÿ    îÿóÿÿÿıÿ  ûÿ     C  éÿ   7 " ãÿ   W D .  E F  M K  ? O h :   ÿ Z < (     F B  ıÿ
 ; V T   # 3 S Y G $   % 7 ? # ÿÿñÿ %   ÷ÿëÿ                                                                                                                                                           x, RUDDER_PAGE, page)

  if e ent == EVT_VIRTUAL_EXIT then
    return 2
  elseif event == E T_VIRTUAL_ENTER_LONG then
     illEvents(event)
    applySett ngs()
    return 2
  else
    return 0
  end
end

-- Mai 

local function run(event)
  if event == nil then
    erro ("Cannot be run as a model scri t!")
  end

  if servoPage ~  nil then
    servoMenu(event) 
  elseif page == ENGINE_PAGE t en
    engineMenu(event)
  el eif page == ELEVONS_PAGE then
    elevonsMenu(event)
  elseif page == RUDDER_PAGE then
    r dderMenu(event)
  elseif page  = CONFIRMATION_PAGE then
    r turn confirmationMenu(event)
  end
  return 0
end

return   init=init, run=run }
                                                                                                                                                                                                                                                                                                                                         + —.Øë²2F9F Fÿ÷iıÅó#2F! F —ÿ÷ ıÅóC2F! F —ÿ÷Yı&J-&K¿F!F “ "3F8Fş÷Õÿ -?ôr® L#ˆ +ôm® ı÷ı €gæ+Fç2*ôc®Hh )?ô^®Ñø 1Ñø Û²3ÿ+?öT® !­ø
@øø	 •¬h ø 1ÒøQ3Û²«B¿Òø Q]ñ¿VUÂø 1)ëÑ5æhE  *ó)XK  µFÿ÷òü ±!F½è@ ÿ÷×½½"pµPC,K\	+ ÑTh
xÍx:Ò²*(¿"ÿ-y/Ñ+,Ø1à ğıÔø	0±#csHxÓÔãx+Ñ£yÓ¹ yğğ,Ñğ)ØBğIpJ`J `JpJp"KpKJ`p½-üØ+úØ ñ 1 DFğÑüKëhÅø0ki3ğ ¿#csæçÔ  ır  €ËT‹  L‹  I‹   ‹  X‹  ‹  E8†  "µBCKœš\ 	*Ñbhy$D¿$rIyQr!p !Q`" C\aóT½Ô  #CCğµ"Lâã\	+ ÑSh
yD¿"Zs
y×D¿"s‘ù  *¼¿ "šr
yVD¿"Úr
yñ•D¿"šs
y % D¿"Úsø+:Ò²*(¿"tï²ºBÙø 5ø{öç"p "Z`#XC#\bó#Tğ½   -éøC&FCßøŒ€FøP+	+ÑÏx± /Ğ½èøƒK“øx  *øÑHh‰hñ|Â"{ƒø  "ƒøx ìçßøT™øx0+æÑ"	ñ| Fğ ü (ŞÑ"Iñ Fğÿû (ÖÑ#J‰øx0K ó`
K
J`
KøPp	K`Äç ¿Ô   s  Ûr  _ÓT‹  L‹  E8X‹  ‹   #CC-éñOßø‘€F	ëø0F	+ÑËx h+Ğ+CĞ«¹”ù p—¹”ø#`ñ
ñû² BQÙPF"YFFğ±û7
ñ	
 (òÑ°½èğ”ù 0+øÑ”ø$0ëÃ3"1FàFğšû (ëÑ òï3  û0”ø%0#J ëÃ khƒP«h K` ğ.ÿ##pKh3c`Òç”ù 0+ÎÑ”ø$ " ëÀ 01 DFğqû (ÂÑëh£b+iãb«Š#†«} ø20³hà.µØ s„ø#0khëÆ6£Q û «h¢S`ƒh +¤Ğ°½èğOG ¿Ô  ÔZ   †  #0µCCJÓ\	
+ÑKÉx“ø…0™BÑ òï3ëÁ!û 3 !LQi`#XC\oó T0½ ¿Ô  s  ÔZ  Ëxğë€ À² (Ğ1ÿ÷Ù»pG#XCK\	+ÑHĞé@2 ëRJhDĞø!³ûòó+Ÿ¿‘ù x2"êârÂT G ¿Ô  s  #XCK\	+	ÑK±ù  ùš€	±ŠB İÚ€pGÔ  s  "µPCK \	+ÑTh”ù 0+ÑËxc¹”ø$ " ë  01 DFğÂú¹##p½+	ÑËx+ùÑÔø !KhšBôÑ	#ñç
+ğÑËx+íÑ#êç ¿Ô   ´ŒxF,	ØT±<,Øßèğş, Ğ¼pGF¼ÿ÷½F¼ÿ÷ï½F¼ÿ÷	¾F