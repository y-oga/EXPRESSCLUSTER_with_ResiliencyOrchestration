package require java

java::import panaces.common.utils.logger
java::import panaces.common.utils.InstallUtil
java::import panaces.common.RPODetailsObject
java::import panaces.common.GroupDetailsObject

set eamsPath [java::field panaces.common.utils.InstallUtil root]
set libPath "$eamsPath/scripts/repository/library"

set logger [java::new logger]
set eamsroot [ java::call InstallUtil getRootDir]
source  [file join $eamsroot "lib/agentscommon.tcl"]
source  [file join $eamsroot "lib/TextProcessor.tcl"]

source "$libPath/PanacesCommonLIB.tcl"
source "$libPath/PanaceOperatingSystemTCL.lib"
source "agents/CustomRepCommon.lib"

set scriptroot [file join $eamsroot "scripts/repository"]
set PanacesTCL_LibraryPath  [file join $scriptroot "library"]
$PANACES_CLI_ARGS1 setArgs "PanacesTCL_LibraryPath" $PanacesTCL_LibraryPath
set libPath  [$PANACES_CLI_ARGS1 getParamValue "PanacesTCL_LibraryPath"]

source "$libPath/PanaceOperatingSystemTCL.lib"





############## PLEASE EDIT fip AND port #####################
### Set floating IP address to connect to EXPRESSCLUSTER (ECX)
set fip "192.168.137.5"
set port "29003"
set mdname "md1"
#############################################################






### Set intermediate file
set curlOutPath "scripts/ECX/curlOut.txt"
set commandOutPath "scripts/ECX/commandOut.txt"
### Set MirrorBreakTime record file
set breakTimeRecordPath "scripts/ECX/breakTimeRecord.txt"

### Create breakTimeRecord.txt if it does not exist
set recordExist [file exists $breakTimeRecordPath]
if {$recordExist == 0} {
    set file_ID [open $breakTimeRecordPath w]
    puts $file_ID "unknown"
    close $file_ID
}

### Get cluster information from ECX WebManager
set curlOut [exec curl -s http://$fip:$port/GetMirrorInfo.js?MirrorDiskName=$mdname]
set file_ID [open $curlOutPath w] 
puts $file_ID "$curlOut"
close $file_ID

### Extract MirrorBreakTime from cluster information
set breakTime [exec grep MirrorBreakTime $curlOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$breakTime"
close $file_ID

### Extract MirrorBreakTime of a primary server
set tmpTimePr [exec awk {-F["]} {{print $2}} $commandOutPath]
### Extract MirrorBreakTime of a secondary server
set tmpTimeDr [exec awk {-F["]} {{print $4}} $commandOutPath]

### Extract MirrorDiskStatus from cluster information
set diskStatus [exec grep DiffStatus $curlOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$diskStatus"
close $file_ID

### Extract MirrorDiskStatus
set diskStatus [exec awk {-F[=]} {{print $2}} $commandOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$diskStatus"
close $file_ID
set diskPr [exec awk {-F[,]} {{print $1}} $commandOutPath]
set diskDr [exec awk {-F[,]} {{print $2}} $commandOutPath]

### Extract ActiveStatus from cluster information
set activeStatus [exec grep ActiveStatus $curlOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$activeStatus"
close $file_ID

### Extract ActiveStatus
set activeStatus [exec awk {-F[=]} {{print $2}} $commandOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$activeStatus"
close $file_ID
set activePr [exec awk {-F[,]} {{print $1}} $commandOutPath]
set activeDr [exec awk {-F[,]} {{print $2}} $commandOutPath]

### Extract DiffPercent from cluster information
set diffPercent [exec grep DiffPercent $curlOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$diffPercent"
close $file_ID

### Extract DiffPercent of a primary server
set tmpDiffPercentPr [exec awk {-F["]} {{print $2}} $commandOutPath]
set diffPercentPr [format "%.1f" $tmpDiffPercentPr]
### Extract DiffPercent of a secondary server
set tmpDiffPercentDr [exec awk {-F["]} {{print $4}} $commandOutPath]
set diffPercentDr [format "%.1f" $tmpDiffPercentDr]

### Extract NMPSize from cluster information
set nmpSize [exec grep NMPSize $curlOutPath]
set file_ID [open $commandOutPath w]
puts $file_ID "$nmpSize"
close $file_ID

### Extract NMPSize of a primary server
set tmpNmpSizePr [exec awk {-F["]} {{print $2}} $commandOutPath]
set nmpSizePr [format "%.1f" $tmpNmpSizePr]
### Extract NMPSize of a secondary server
set tmpNmpSizeDr [exec awk {-F["]} {{print $4}} $commandOutPath]
set nmpSizeDr [format "%.1f" $tmpNmpSizeDr]


### Create a debug file
#set file_ID [open $commandOutPath w]
#puts $file_ID "$diskPr $diskDr end"
#close $file_ID

### Delete an intermediate file
file delete -force -- "$curlOutPath"
file delete -force -- "$commandOutPath"

### Get the clock time
set systemTime [ clock seconds ]
### Convert a clock time to string
set currentTime [ clock format $systemTime -format {%Y-%m-%d %H:%M:%S} ]

### Convert the MirrorBreakTime of a primary server to a suitable format
if {$tmpTimePr != "--"} {
    regsub -all "/" $tmpTimePr {-} timePr
} else {
    set timePr "$tmpTimePr"
}

### Convert the MirrorBreakTime of a secondary server to a suitable format
if {$tmpTimeDr != "--"} {
    regsub -all "/" $tmpTimeDr {-} timeDr
} else {
    set timeDr "$tmpTimeDr"
}

set msg "Unknown"
set dataLag "Unknown"

if {$diskPr == "2" || $diskDr == "2"} {
    set msg "Mirror disks on both servers are under Mirror Recovery. Please wait until Mirror Recovery is completed."

    set timePr "$currentTime"
    set file_ID [open $breakTimeRecordPath r]
    gets $file_ID breakTimeRecord
    close $file_ID
    set timeDr "$breakTimeRecord"
} elseif {$diskPr == "8"} {
    set msg "Primary server is not running."
   
    set timePr "$currentTime" 
    set file_ID [open $breakTimeRecordPath r]
    gets $file_ID breakTimeRecord
    close $file_ID
    set timeDr "$breakTimeRecord"
} elseif {$diskDr == "8"} {
    set msg "Secondary server is not running."
   
    set timePr "$currentTime" 
    set file_ID [open $breakTimeRecordPath r]
    gets $file_ID breakTimeRecord
    close $file_ID
    set timeDr "$breakTimeRecord"
} elseif {$diskPr == "4" && $diskDr != "4"} {
    set msg "Mirroring is not working. The disk on primary server is not up-to-date."
    if {$timePr == "--"} {
        set file_ID [open $breakTimeRecordPath r]
        gets $file_ID breakTimeRecord
        close $file_ID
        set timePr "$breakTimeRecord"
    }    
    set timeDr "$timePr"
    set timePr "$currentTime"
    set dataLag [expr $diffPercentDr * $nmpSizeDr * 0.01]

    set file_ID [open $breakTimeRecordPath w]
    puts $file_ID "$timeDr"
    close $file_ID
} elseif {$diskPr != "4" && $diskDr == "4"} {
    set msg "Mirroring is not working. The disk on secondary server is not up-to-date."

    set timePr "$currentTime"
    if {$timeDr == "--"} {
        set file_ID [open $breakTimeRecordPath r]
        gets $file_ID breakTimeRecord
        close $file_ID
        set timeDr "$breakTimeRecord"
    }
    set dataLag [expr $diffPercentPr * $nmpSizePr * 0.01]

    ### debug ###
    set file_ID [open $commandOutPath w]
    puts $file_ID "$diffPercentPr $diffPercentDr $nmpSizePr $nmpSizeDr $dataLag"
    close $file_ID
    #############

    set file_ID [open $breakTimeRecordPath w]
    puts $file_ID "$timeDr"
    close $file_ID
} elseif {$diskPr == "4" && $diskDr == "4"} {
    set msg "The disks on both servers are not running."

    if {$activePr == "1"} {
        set timePr "$currentTime"
        if {$timeDr == "--"} {
            set file_ID [open $breakTimeRecordPath r]
            gets $file_ID breakTimeRecord
            close $file_ID
            set timeDr "$breakTimeRecord"
        }

        set dataLag [expr $diffPercentPr * $nmpSizePr * 0.01]
    } else {
        if {$timePr == "--"} {
            set file_ID [open $breakTimeRecordPath r]
            gets $file_ID breakTimeRecord
            close $file_ID
            set timeDr "$breakTimeRecord"
        } else{
            set timeDr "$timePr"
        }
        set timePr "$currentTime"
        set dataLag [expr $diffPercentDr * $nmpSizeDr * 0.01]
    }

    set file_ID [open $breakTimeRecordPath w]
    puts $file_ID "$timeDr"
    close $file_ID
} elseif {$diskPr == "1" && $diskDr == "1"} {
    set msg "Mirror disks on both servers are working fine."
    
    set timePr "$currentTime"
    set timeDr "$currentTime"
    set dataLag "0"

    set file_ID [open $breakTimeRecordPath w]
    puts $file_ID "$timeDr"
    close $file_ID
}

$PANACES_CLI_RETVAL setArgs "REPLICATION_DETAILS_EXIT_STATUS" "0"
$PANACES_CLI_RETVAL setArgs "REPLICATION_DETAILS_OUTPUT" "$msg"
$PANACES_CLI_RETVAL setArgs "REPLICATION_DETAILS_OUTPUT_TYPE" "Text"

### Set remaining data lag
$PANACES_CLI_RETVAL setArgs "REPLICATION_DETAILS_DATALAG" "$dataLag"
$PANACES_CLI_RETVAL setArgs "REPLICATION_DETAILS_DATALAG_UNIT" "MB"

### Send MirrorBreakTime of both servers to RO server
### RPO = PR_TIMESTAMP - DR_TIMESTAMP
$PANACES_CLI_RETVAL setArgs "DR_TIMESTAMP" "$timeDr"
$PANACES_CLI_RETVAL setArgs "TIMESTAMP_FORMAT" "yyyy-MM-dd HH:mm:ss"
$PANACES_CLI_RETVAL setArgs "PR_TIMESTAMP" "$timePr"

set successExitCode 0
