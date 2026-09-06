P5toP6ss.exe -convert ..\1_day_fine\stad1_main.bin ..\1_day_fine\stad1_mainNEW.bin temp1
P5toP6ss.exe -convert ..\2_day_rain\stad1_main.bin ..\2_day_rain\stad1_mainNEW.bin temp2
P5toP6ss.exe -convert ..\3_day_snow\stad1_main.bin ..\3_day_snow\stad1_mainNEW.bin temp3
P5toP6ss.exe -convert ..\4_night_fine\stad1_main.bin ..\4_night_fine\stad1_mainNEW.bin temp4
P5toP6ss.exe -convert ..\5_night_rain\stad1_main.bin ..\5_night_rain\stad1_mainNEW.bin temp5
P5toP6ss.exe -convert ..\6_night_snow\stad1_main.bin ..\6_night_snow\stad1_mainNEW.bin temp6
del ..\1_day_fine\stad1_main.bin
del ..\2_day_rain\stad1_main.bin
del ..\3_day_snow\stad1_main.bin
del ..\4_night_fine\stad1_main.bin
del ..\5_night_rain\stad1_main.bin
del ..\6_night_snow\stad1_main.bin
ren ..\1_day_fine\stad1_mainNEW.bin stad1_main.bin
ren ..\2_day_rain\stad1_mainNEW.bin stad1_main.bin
ren ..\3_day_snow\stad1_mainNEW.bin stad1_main.bin
ren ..\4_night_fine\stad1_mainNEW.bin stad1_main.bin
ren ..\5_night_rain\stad1_mainNEW.bin stad1_main.bin
ren ..\6_night_snow\stad1_mainNEW.bin stad1_main.bin
pause

