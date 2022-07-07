rem make ZIP archive
tar.exe -a -c -f FS22_LeaseToOwn.zip LeaseToOwn.lua LeaseToOwnEvent.lua modDesc.xml modIcon.dds

rem copy ZIP to FS22 mods folder
rem xcopy /b/v/y FS22_LeaseToOwn.zip "%userprofile%\Documents\My Games\FarmingSimulator2022\mods"
