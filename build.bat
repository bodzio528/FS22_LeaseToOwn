rem make ZIP archive
tar.exe -a -c -f FS22_LeaseToOwn.zip Logger.lua LeaseToOwn.lua LeaseToOwnEvent.lua modDesc.xml icon_leasetoown.dds

copy FS22_LeaseToOwn.zip FS22_LeaseToOwn_update.zip

rem copy ZIP to FS22 mods folder
xcopy /b/v/y FS22_LeaseToOwn.zip "D:\Users\Bodzio\Documents\My Games\FarmingSimulator2022\mods"
