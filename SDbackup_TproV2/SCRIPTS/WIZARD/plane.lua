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
      limits.min = valueIncDec(event, limits.min, -10 *O-�+�+�.�'�!>+]
�+/<3j<&F�LQ R�RGQ;O�M�M[F�;=2�+D&ir6;�� �{�0�����Y�`�"��N�A��-���% /�!L!�)�193m*�'u)�*�%�7� �����������bВ�R�Ѹ,�$�J�k��� �g�g�9����������&��� c�%�! %
8\H(M7N�L�NV�Z�T�L�E�@�=}8. Y1y= .�������y�*����,�`��� �������9
=: � �C �,�5;1](�' (c'�$;��	�����!��eݨ�X��T� �º2�b�Ϥh���/�߫!��B��������� ��"I� @$�(|3�?vI�L�H�H�Q!S8M D�@�>�8B-�'� ���t���|����L� �,����l�O���I�����O'� # '!0�4�2�+�+9,O*@%s 3m
Xk�[���E�k�� ����o�K�r������h�
� 	A�n���3�;�[�y�~�~���ŭ�,�ݿ ������{���G����ǉ�1�����C�)�� �U ��(fo'?7�?�?�:�;�B^GtD$> 6�2�1]/2)2�^L�	v�������e��� ��0��)�1��N}�"
4:7�/1+*�/U1�),��[���� �4������I�z���£ģ�������@�� �ʧ�m�[���O���9�t�_�J�����C "�$�,$8�@+>�>4D%I)Dt>\<�<�6�.�&  y�W;! 
�`�'�s�_����h� ��P���+,Ld�&,(p(-�. 12Q(�"�&��
-�#���
����� �����j��������K�*����
�5D Y(_)S%a$}(�1�3�*��!�(�$�?7
�Cg������ �L��������x�U�
rL��� $� �� �'#+E'`���!��
��[ �s���]��1���V����������yș� ˬ�#�_¥�r����ō����bمԁږ��� ��E L��7�((�1t3�3=5y7�8[; 9Q3}./�-}(!�!Q.�f������ �K�>�����~�5�U�R���v		�F ��=�"�"�-7K�h��	�� ����T�R�������{��ʦ�5����� ��m�hƔ�&���
Ǧ���E��Ӽ������ �O���
� *��8 �"�!�,�+~"� 
������m�u�c����Գ�����}��� ���T��������Aʅ�+ϫ���V��׿�j� م�;�����(�L<�. ���/�6�/�/ 8	;�7�808V2�0�0�,�%� v�{�
 �����������X������`����= �
���IS�!�o.*G�
�k�������0�<���4��� ������
 ��3N�w��~+��G� �������X�-������t����b�_� �>�|�]�F�\�XԹ�x�A��s���Է��� �*�f���$�u���
��.�� ?78����0
�	��D��CLZ�>D� �������O���G�s��������N���@� ���	� ޮڏ�w�~�i�|����ݥڅ�K� �m���R����m����	�q
�Z����< ����q�i� =�p�?��4�jm����|� \
�N �N}���
���$�:��J� ��_��N������f������Y�D�T� ݂����,��ݟ������������K� �O
Y
TO��!� � $&�%^&�% ##L"t |����x���J�  ��+ ����g��c�  ��  E	�  @u��5<P
]	 4  `��� ���|�A�Y�P�����H�9�����E�U� �����V��)�������"���,��� ���������p�i��= 	���� ��A~)!~!� {D����� � 
	;�83��; ���a� n�w2���>�� �x�;Z���������������,�s���� ���!�$�U�1����S���E�Z����� �]����v�I��*������[�������  ������HZ�4�w  �  D�m�<���X
 l%�`��k �7�
����� \ EX��� �����K���A����� �`���L����������F���8������ �E������������������f��� �������s�� ���	�
��	&���C$�  �s K�� a� � +!-�)�� :  ������r�O�����H��q������+� ���?�s�'���)����:���.��N� ��B��������u��� ��tW �M�.c.���! 
��������t��E�J�U�� �{����M���E������������� Q~�P
Ggj�s���b� �p���*������( 
8$
Jj
c9	��M =�nn� D���1���������Q�@� ����a�U�Z�����z�;�[�n�R�4�� ������?��i��K���3���q�� �������?���� ���T	�b�B q7���l����~�)� �;���
Hp�D� �R���� /q B� � ���G�8�������H�5������c���S�� ��o�M�$��V�\�q��p��L����� ����u�����������������T�� ��
}�
�����������E������� ����������s��^�6���b������ �{�������N�6�������c������ � ����-�(� ��������Z�|����� b��K��1	���
*	�	V
��O��T�  ��A���m������4�������O��� ��F����U�	�H��������������� ���j���:�������������7���e� �)� ���#����} ����2&(Nc� PZ��g	�	"	O	
�
�


 ��
�	�	�
�
�	N	'		�y	fX� ������&��TG��o���� �^�����^�/����F�,�+����K����� �������#�0�����&������4���
8  � ~ ��[�)���� ���T�����K�������������S�8�`� ���A�6���������\�8�v�b�[���� ��������m�����-�B 5 ��Q � I  p � ��� ������	�e ��~� �  D�<���������� ���������}���  ~ �  pxA ��Y� t t d K ������������@� �+���[� �x���O����������R��� � �!�?�����,   � <-� � � � s   ����i���q�?���/�w�m���F�`��� �)�)�����m�d�& K &  : O 4 � �   T 1[� � c��d':��� '   � � ��n�o�����# ��6�R� J ���� ���= ����b�t���0 |�X�3�������� �������S���� p � f . � _Q�   !� D  
  ������`�q������� ���I�q�$�y�c���F�T�����+���
 �� ���+ � k ������Q   ������      , d � q  ��Q  S ���� ; <  ���* J )  4 . = 
 #    0  /   , 3 ] _ � T g  � s Z g f � O   q � o K � � U   > n ������    - ���� � � # ��% � }  �� L   ���� S (  ��4 9 6      %   : ���� J  ����    ��������  ��     C  ��   7 " ��   W D .  E F  M K  ? O h :   � Z < (     F B  ��
 ; V T   # 3 S Y G $   % 7 ? # ���� %   ����                                                                                                                                                           x, RUDDER_PAGE, page)

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
                                                                                                                                                                                                                                                                                                                                         + �.��2F9F F��i���#2F! F ��� ���C2F! F ���Y�&J-&K�F!F � "3F8F���� -?�r� L#� +�m� ��� �g�+F�2*�c�Hh )?�^��� 1�� ۲3�+?�T� !��
@�����	 ��h � 1��Q3۲�B��� Q]��VU�� 1)��5�hE  *��)XK  �F���� �!F��@ ��׽�"p�PC,K\	+ �Th
x�x:Ҳ*(�"�-y/�
,�1� ����	0�#csHx���x+ѣyӹ y��,��)�B�IpJ`J `JpJp"KpKJ`p�-��+�� � 1 DF���K�h��0ki3� �#cs��Ԏ  �r  ��T�  L�  I�   �  X�  �  E8�  "�BCK��\ 	*�bhy$D�$rIyQr!p !Q`" C\a�T�Ԏ  #CC�"L��\	+ �Sh
yD�"Zs
y�D�"s��  *�� "�r
yVD�"�r
y��D�"�s
y % D�"�s�+:Ҳ*(�"tﲺB�� 5�{��"p "Z`#XC#\b�#T� �  -��C&FC����F�P+	+��x� /н���K��x  *��Hh�h�|�"{��  "��x ����T���x0+��"	�| F� � (��"I� F��� (��#J��x0K �`
K
J`
K�Pp	K`�� �Ԏ   s  �r  _�T�  L�  E8X�  �   #CC-��O����F	��0
��� BQ�PF"YFF��7
�	
 (��������� 0+�є�$0��3"1F�F�� (�� ��3  �0��%0#J �� kh��P�h K` �.�##pKh3c`��� 0+�є�$ " �� 01 DF�q� (���h�b+i�b��#��} �20�h�.�� s��#0kh��6�Q � ��h�S`�h +������OG �Ԏ  �Z   �  #0�CCJ�\	
+�
+���x+��#�� �Ԏ   ��xF,	�T�<,�����, ��pGF�����F����F���	�F