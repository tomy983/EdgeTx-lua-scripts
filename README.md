# EdgeTx-lua-scripts
Written and tested only on a Jumper T-Pro V2 with internal ELRS 1000mW module (oled LCD)

~~With the RSSI Model Locator.lua file Add also the two audio files. Eventually replace telemko.wav with the one in your own language.~~ 
Now uses language from SYSTEM folder and auto detect user language. 
The beep is generated rather than being a file, so other files other than the lua file are no longer needed.
It also has haptic feedback and a large bar graph showing the signal strenght.


This code is derived from https://github.com/EdgeTX/edgetx-sdcard/blob/3f79e21fbfe480fa59393e3cc196e329d7bb185c/sdcard/c480x272/SCRIPTS/TOOLS/Model%20Locator%20(by%20RSSI).lua#L19 - Model Locator (by RSSI).lua by Offer Shmuely, and as I found it in my newly bought Jumper T-Pro V2 SD card and it was not working (it is designed for colour display ecc..) and I tought it might be useful, I decided to make this version for my radio.


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
