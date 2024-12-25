# Make ZIP archive
tar.exe -a -c -f FS25_LeaseToOwn.zip Logger.lua LeaseToOwn.lua LeaseToOwnEvent.lua modDesc.xml icon_leasetoown.dds

# Define the path to the "Documents" folder, user and language independent
$documentsPath = [System.Environment]::GetFolderPath('MyDocuments')

# Combine the "Documents" path with "My Games\FarmingSimulator2025\mods" folder
$modsFolderPath = Join-Path -Path $documentsPath -ChildPath "My Games\FarmingSimulator2025\mods"

# Check if the mods folder exists
if (Test-Path -Path $modsFolderPath) {
    # Copy ZIP to FS25 mods folder
    Copy-Item -Path FS25_LeaseToOwn.zip -Destination $modsFolderPath -Force
    Write-Output "Build and copied successfully."
} else {
    Write-Warning "The path '$modsFolderPath' does not exist."
}

Write-Host "Press any key to exit..."
$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
