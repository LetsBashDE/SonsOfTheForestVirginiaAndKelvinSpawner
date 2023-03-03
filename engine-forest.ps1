# Autor: LetsBash.de / SirBash.com

function retriveLatestSavegame {
    $lastestpath = $false
    $lastesttime = $false
    $savepath = ($ENV:LOCALAPPDATA + "low\Endnight\SonsOfTheForest\Saves\")
    $steamidfolders = Get-ChildItem -path $savepath
    foreach ($steamidfolder in $steamidfolders) {
        foreach ($gametype in @("Multiplayer", "SinglePlayer")) {
            $savegamepath = ($steamidfolder.fullname + "\" + $gametype)
            if (!(test-path -Path $savegamepath)) {
                continue
            }
            $savegamefolders = Get-ChildItem -path $savegamepath
            foreach ($savegamefolder in $savegamefolders) {
                $filepath = ($savegamefolder.fullname + "\SaveData.json")
                $savegame = get-item -path $filepath
                $modifiedtime = $savegame.LastWriteTime
    
                if ($lastesttime -eq $false) {
                    $lastesttime = $modifiedtime
                    $lastestpath = $savegamefolder.fullname
                }
    
                if ($modifiedtime -gt $lastesttime) {
                    $lastesttime = $modifiedtime
                    $lastestpath = $savegamefolder.fullname
                }
            }
        }
    }
    return $lastestpath
}

function weAreManyNPCs {
    param(
        [string]$lastestpath
    )

    # Sanatize
    if ($lastestpath -eq $false) {
        write-host "There are not savegames avalible" -ForegroundColor White -BackgroundColor Red
        return $false
    }

    # Create savegamefilepaths
    $GameStateSaveDataPath = ($lastestpath + "\GameStateSaveData.json")
    $SaveDataPath = ($lastestpath + "\SaveData.json")

    # Testing files
    if (!(test-path -path $GameStateSaveDataPath)) {
        write-host ($GameStateSaveDataPath + " is missing") -ForegroundColor White -BackgroundColor Red
        return $false
    }
    if (!(test-path -path $SaveDataPath)) {
        write-host ($SaveDataPath + " is missing") -ForegroundColor White -BackgroundColor Red
        return $false
    }

    # Stage 1 - GameStateSaveData.json
    $content = getSavegame $GameStateSaveDataPath
    $change = $false
    
    if ($content -eq $false) {
        write-host ($GameStateSaveDataPath + " has no data") -ForegroundColor White -BackgroundColor Red
        return $false
    }

    if ($content -like '*\"IsRobbyDead\":true,*') {
        $change = $true
        $content = $content -replace '[\\]["]IsRobbyDead[\\]["][:]true,', '\"IsRobbyDead\":false,'
    }

    if ($content -like '*\"IsVirginiaDead\":true,*') {
        $change = $true
        $content = $content -replace ('[\\]["]IsVirginiaDead[\\]["][:]true,'), '\"IsVirginiaDead\":false,'
    }

    if ($change -eq $true) {
        if (writeSavegame $GameStateSaveDataPath $content) {
            write-host ($GameStateSaveDataPath + " savegame modified") -ForegroundColor green -BackgroundColor Black
        }
        else {
            write-host ($GameStateSaveDataPath + " could not write to savegame") -ForegroundColor yellow -BackgroundColor Black
            return $false
        }
    }
    else {
        write-host ($SaveDataPath + " savegame does not need modification") -ForegroundColor yellow -BackgroundColor Black
    }

    # Stage 2 - SaveData.json
    $content = getSavegame $SaveDataPath

    if ($content -eq $false) {
        write-host ($SaveDataPath + " has no data") -ForegroundColor White -BackgroundColor Red
        return $false
    }

    # Enumerate max UniqueId
    $maxUniqueId = 0
    $fragments = $content -split '[\\]["]UniqueId[\\]["][:]'
    $skipfirst = $false;
    foreach($fragment in $fragments)
    {
        if($skipfirst -eq $false)
        {
            $skipfirst = $true
            continue
        }
        if($fragment -notmatch '[0-9].*')
        {
            continue
        }

        $value = [int]($fragment -split '[^0-9]')[0]
        if($maxUniqueId -lt $value)
        {
            $maxUniqueId = $value
        }
    }
    
    # Get amount of NPC to insert
    $virginias = read-host -Prompt "How many Virginias you want to spawn"
    $kevins = read-host -Prompt "How many Kelvins you want to spawn"

    # Insert Virginia
    for ($i = 0; $i -lt $virginias; $i++)
    {
        $maxUniqueId++
        $find = '[\\]["]Actors[\\]["][:][\[]'
        $replace = '\"Actors\":[{\"UniqueId\":'+$maxUniqueId+',\"TypeId\":10,\"FamilyId\":0,\"Position\":{\"x\":-1148.47742,\"y\":138.830429,\"z\":-225.7233},\"Rotation\":{\"x\":0.0,\"y\":-0.9923399,\"z\":0.0,\"w\":0.123537354},\"SpawnerId\":-1797797444,\"ActorSeed\":787901937,\"VariationId\":0,\"State\":2,\"GraphMask\":1,\"EquippedItems\":null,\"OutfitId\":-1,\"NextGiftTime\":0.0,\"LastVisitTime\":0.0,\"Stats\":{\"Health\":999.0,\"Anger\":0.0,\"Fear\":0.0,\"Fullness\":100,\"Hydration\":100,\"Energy\":90.5,\"Affection\":999.0},\"StateFlags\":0},'
        $content = $content -replace $find, $replace
        write-host "Added Virginia"
    }

    # Insert Kelvin
    for ($i = 0; $i -lt $kevins; $i++)
    {
        $maxUniqueId++
        $find = '[\\]["]Actors[\\]["][:][\[]'
        $replace = '\"Actors\":[{\"UniqueId\":'+$maxUniqueId+',\"TypeId\":9,\"FamilyId\":0,\"Position\":{\"x\":-1148.47742,\"y\":138.830429,\"z\":-225.7233},\"Rotation\":{\"x\":0.0,\"y\":-0.9923399,\"z\":0.0,\"w\":0.123537354},\"SpawnerId\":0,\"ActorSeed\":-37402917,\"VariationId\":0,\"State\":2,\"GraphMask\":1,\"EquippedItems\":[504],\"OutfitId\":-1,\"NextGiftTime\":0.0,\"LastVisitTime\":-100.0,\"Stats\":{\"Health\":999.0,\"Anger\":91.19554,\"Fear\":99.97499,\"Fullness\":45.9295425,\"Hydration\":18.3870544,\"Energy\":90.5,\"Affection\":0.0},\"StateFlags\":0},'
        $content = $content -replace $find, $replace
        write-host "Added Kelvin"
    }

    if (writeSavegame $SaveDataPath $content) {
        write-host ($SaveDataPath + " savegame modified") -ForegroundColor green -BackgroundColor Black
    }
    else {
        write-host ($SaveDataPath + " could not write to savegame") -ForegroundColor yellow -BackgroundColor Black
        return $false
    }
    return $true
}

function getSavegame {
    param(
        [string]$filepath
    )

    if (!(test-path -path $filepath)) {
        write-host ($filepath + " does not exist") -ForegroundColor White -BackgroundColor Red
        return $false
    }

    return (Get-Content -Raw $filepath)
}

function writeSavegame {
    param(
        [string]$filepath,
        [string]$content
    )

    if (!(test-path -path $filepath)) {
        write-host ($filepath + " does not exist") -ForegroundColor White -BackgroundColor Red
        return $false
    }

    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($filepath, $content, $Utf8NoBomEncoding)
    return $true
}

$lastestpath = retriveLatestSavegame
$result      = weAreManyNPCs $lastestpath
$result
