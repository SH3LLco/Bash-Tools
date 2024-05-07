#!/bin/bash
                                                                                                                         
# -----------------------------------------------<FUNCTIONS>-----------------------------------------------

# function to get filename
function getFileName {
    date=$(date +%Y-%m-%d)
    host=$(hostname | cut -f1 -d .)
    echo "$date-$host.csv"
}

# function to check for controller issues and write to file
function writeControllerToFile {
  
    reportedcontrollerissues="${#totalcontrollerissues[@]}"

    # if # of issues is 0 then echo no issues, else echo each issue. 
    if [[ $reportedcontrollerissues -eq 0 ]]; then
        for i in $(seq 0 $(($controllercount - 1))); do
            echo " ,Controller ${controllerids[$i]} No Issues Found" >> $file
        done
    else 
        for i in $(seq 0 $(($reportedcontrollerissues - 1))); do
            echo "${totalcontrollerissues[$i]}" >> $file
        done
    fi
}

# function to check for controller issues
function checkCrowIssues {
     # if controller status is not ok, add to crow
    if [[ 'Ok' != "$cstatus" ]]; then
        crow="${crow}Status,${cstatus},"
    fi

    if [[ -z "$crow" ]]; then
        crow="${crow}"
    else
        crowissues=" ,${controllerid},${crow},"
        totalcontrollerissues+=("${crowissues}")
    fi
}

# function to check for battery issues
function checkBrowIssues {
    # if battery status is not ok, add to battery
    if [[ 'Ok' != "$bstatus" ]]; then
        brow="${brow}Status,${bstatus},"
    fi

    if [[ -z "$brow" ]]; then
        brow="${brow}"
    else
        if [[ -z "${crowissues}" ]]; then
            browissues=" ,${controllerid},Battery,${brow},"
            totalcontrollerissues+=("${browissues}")
        else
            browissues=" ,Battery,${brow},"
            totalcontrollerissues+=("${browissues}")
        fi
    fi
}

# function to check for Enclosure issues
function checkErowIssues {
    # if battery status is not ok, add to battery
    if [[ 'Ok' != "$estatus" ]]; then
        erow="${erow}Status,${estatus},"
    fi

    if [[ -z "$erow" ]]; then
        erow="${erow}"
    else
        if [[ -z "${crowissues}" ]] && [[ -z "${browissues}" ]]; then
            erowissues=" ,${controllerid},Battery,${erow},"
            totalcontrollerissues+=("${erowissues}")
        else
            erowissues=" ,Battery,${erow},"
            totalcontrollerissues+=("${erowissues}")
        fi
    fi
}

# function to check if vrow has data but controller is clean to avoid vrow reporting without controller context
checkVrowIssues() {
    # gets vrow count
    vrowcount="${#vstatuses[@]}"
    
    for y in $(seq 0 $(($vrowcount -1))); do
        vrow=''

        # sets vdisk status variable for ease of use
        vstatus="${vstatuses[$y]}"

        # if vdisk status is not ok, add to vrow
        if [[ 'Ok' != "${vstatus}" ]]; then
            vrow="${vrow}Status,${vstatus},"
        fi


        if [[ -z "$vrow" ]]; then
            vrow="${vrow}"
        else
            if [[ -z "${crowissues}" ]] && [[ -z "${erowissues}" ]] && [[ -z "${browissues}" ]]; then
                vrowissues=" ,${controllerid},VDisk,${vrow},"
                totalcontrollerissues+=("${vrowissues}")
            else
                vrowissues=" ,VDisk,${vrow},"
                totalcontrollerissues+=("${vrowissues}")
            fi
        fi
    done

    if [[ -z "$vrowissues" ]]; then
        vrowissues="$vrowissues"
    else
        totalcontrollerissues+=("$line")
    fi
}

# function to check for prow issues
checkProwIssues() {
    # if prow is empty, echo no issues, else write prow to file
    if [[ -z "$prow" ]]; then
        prow="${prow}"
    else
        if [[ -z "${crowissues}" ]] && [[ -z "${vrowissues}" ]] && [[ -z "${browissues}" ]] && [[ -z "${erowissues}" ]]; then
            prowissues=" , ,PDisk ${id},${prow},"
            mainprowissues+=("${prowissues}")
        else
            prowissues=" , ,PDisk ${id},${prow},"
            mainprowissues+=("${prowissues}")
        fi
    fi
}

# function to check if vrow and crow are empty, if so adds controller id
checkProwVrowCrow() {
    reportedprowissues="${#mainprowissues[@]}"

    if [[ -z "${crowissues}" ]] && [[ -z "${vrowissues}" ]] && [[ -z "${browissues}" ]] && [[ -z "${erowissues}" ]]; then
        # if # of issues is 0 then echo no issues, else echo each issue. 
        if [[ $reportedprowissues -eq 0 ]]; then
            reportedprowissues="$reportedprowissues"
        else
            totalcontrollerissues+=(",${controllerid}")
            for x in $(seq 0 $(($reportedprowissues - 1))); do
                totalcontrollerissues+=("${mainprowissues[$x]}")
            done
        fi

    else
        if [[ $reportedprowissues -eq 0 ]]; then
            reportedprowissues="$reportedprowissues"
        else
            for x in $(seq 0 $(($reportedprowissues - 1))); do
                totalcontrollerissues+=("${mainprowissues[$x]}")
            done
        fi
    fi
}

# prowcheck if empty, does nothing, if found adds empty lines for formatting.
function prowCheck {
    if [[ -z "$prowcheck" ]]; then
        prowcheck="${prowcheck}"
    else
        totalcontrollerissues+=("$line")
        totalcontrollerissues+=("$line")
    fi
}

# function to handle pdisk results
function getPResult {
    echo -e "$preport" | egrep "^\W*$1" | cut -d : -f 2- | sed 's/^ //g' | sed 's/ /_/g'
}

# function to handle controllers
function getControllers {
    echo -e "$controllers" | egrep "^\W*$1" | cut -d : -f 2- | sed 's/^ //g' | sed 's/ /_/g'
}

# function to handle vdisk results
function getVReport {
    echo -e "$vreport" | egrep "^\W*$1" | cut -d : -f 2- | sed 's/^ //g' | sed 's/ /_/g'
}

# function to handle chassis results
function getChassis {
    echo -e "$chreport" | awk -F ' : ' -v comp="$1" '$2 == comp {print $1}' | tr -d '[:space:]'
}

# function to handle battery results
function getBattery {
    echo -e "$breport" | egrep "^\W*$1" | cut -d : -f 2- | sed 's/^ //g' | sed 's/ /_/g'
}

# function to handle battery results
function getEnclosure {
    echo -e "$ereport" | egrep "^\W*$1" | cut -d : -f 2- | sed 's/^ //g' | sed 's/ /_/g'
}

# -----------------------------------------------</FUNCTIONS>-----------------------------------------------

# --------------------------------------------<STATIC VARIABLES>--------------------------------------------
# gets file name
file=$(getFileName)

# gets host name
host=$(hostname | cut -f1 -d .)

# write host name to file
echo "${host}" >> $file

# empty line for formatting
line=' '

# gets controllers and sets to variable
# commented for testing: controller=$(omreport storage controller)
controllers=$(cat controller0.txt)

# gets controller IDs and sets to array
controllerids=($(getControllers "ID"))

# gets length of controllerids
controllercount=${#controllerids[@]}

# sets file name
file=$(getFileName)

# creates empty issue array that we will use to report issues
totalcontrollerissues=()

# --------------------------------------------</STATIC VARIABLES>-------------------------------------------
# ----------------------------------------------<CHASSIS CHECK>----------------------------------------------
# omreport chassis
chreport=$(cat chassis.txt)
chrow=''
chrowreport=()

chfan=$(getChassis "Fans")
chintrusion=$(getChassis "Intrusion")
chmemory=$(getChassis "Memory")
chpwrsup=$(getChassis "Power Supplies")
chpwrman=$(getChassis "Power Management")
chproc=$(getChassis "Processors")
chtemp=$(getChassis "Temperatures")
chvolt=$(getChassis "Voltages")
chhdwrlog=$(getChassis "Hardware Log")
chbatt=$(getChassis "Batteries")

if [[ 'Ok' != "$chfan" ]]; then
    chrow="Fans,${chfan},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chintrusion" ]]; then
    chrow="Intrusion,${chintrusion},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chmemory" ]]; then
    chrow="Memory,${chmemory},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chpwrsup" ]]; then
    chrow="Power Supplies,${chpwrsup},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chpwrman" ]]; then
    chrow="Power Management,${chpwrman},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chproc" ]]; then
    chrow="Processors,${chproc},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chtemp" ]]; then
    chrow="Temperatures,${chtemp},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chvolt" ]]; then
    chrow="Voltages,${chvolt},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chhdwrlog" ]]; then
    chrow="Hardware Log,${chhdwrlog},"
    chrowreport+=(",,${chrow}")
fi

if [[ 'Ok' != "$chbatt" ]]; then
    chrow="Batteries,${chbatt},"
    chrowreport+=(",,${chrow}")
fi

reportedchassisissues="${#chrowreport[@]}"

if [[ $reportedchassisissues -eq 0 ]]; then
        echo ",Chassis No Issues" >> $file
    else 
        echo ",Chassis" >> $file
        for i in $(seq 0 $(($reportedchassisissues - 1))); do
            echo "${chrowreport[$i]}" >> $file
        done
        echo "$line" >> $file
fi


# ----------------------------------------------</CHASSIS LOOP>----------------------------------------------
# -------------------------------------------<MAIN CONTROLLER LOOP>-----------------------------------------

# for loop based on controller count
for i in $(seq 0 $(($controllercount -1))); do
    
    # get the battery report
    # omreport storage battery
    breport=$(cat battery0.txt)
    bstatuses=($(getBattery "Status")) 
    bstatus="${bstatuses[$i]}"
    brow=''
    browissues=''

    # get the enclosure report
    # omreport storage enclosure
    ereport=$(cat enclosure0.txt)
    estatuses=($(getEnclosure "Status")) 
    estatus="${estatuses[$i]}"
    erow=''
    erowissues=''

    # get the pdisk report
    # commented for testing: preport=$(omreport storage pdisk controller=$i)
    preport=$(cat preport0.txt)

    # get the vdisk report
    # commented for testing: vreport=$(omreport storage vdisk controller=$i)
    vreport=$(cat vreport0.txt)

    # sets vdisk status array
    vstatuses=($(getVReport "Status"))

    # sets empty variable for vrow status
    vrowissues=''

    # gets controller status to array
    cstatuses=($(getControllers "Status")) 

    # sets controller status variable for ease of use
    cstatus="${cstatuses[$i]}"

    # sets empty variable for controller row status
    crow=''
    crowissues=''

    # gets pdisk drive ids
    driveids=($(getPResult "ID"))

    # gets pdisk state
    states=($(getPResult "State"))

    # gets pdisk status
    statuses=($(getPResult "Status"))

    # gets pdisk power status
    powerStatuses=($(getPResult "Power Status"))

    # gets pdisk failure prediction
    failurePredicteds=($(getPResult "Failure Predicted"))

    # gets # of drives
    drivecount=${#driveids[@]}

    # sets controller variable
    controllerid="Controller ${i}"

    # prow check for formatting, if pdisk issues found, adds empty lines after pdisk list
    prowcheck=''

    # checks for controller issues
    checkCrowIssues
    # crowAdd

    checkBrowIssues

    checkErowIssues

    # check for vrow and crow for formatting
    checkVrowIssues
    # vrowAdd

    mainprowissues=()
# ------------------------------------------</MAIN CONTROLLER LOOP>-----------------------------------------

# --------------------------------------------<SUB CONTROLLER LOOP>-----------------------------------------
    # for loop based on drive count
    for j in $(seq 0 $(($drivecount - 1))); do
        
        # sets state variable for ease of use
        state="${states[$j]}"

        # sets status variable for ease of use
        status="${statuses[$j]}"

        # sets power status variable for ease of use
        powerStatus="${powerStatuses[$j]}"

        # sets failure prediction variable for ease of use
        failurePredicted="${failurePredicteds[$j]}"

        # sets id variable to drive id for ease of use
        id="${driveids[$j]}"

        # sets empty variable for prow status
        prow=''
        prowissues=''

        # if state is not ready or online
        if [[ 'Ready' != "$state" ]] && [[ 'Online' != "$state" ]]; then
            prow="${prow}State,${state},"
            prowcheck="${prow}"
            
        fi

        # if status is not ok
        if [[ 'Ok' != "$status" ]]; then
            prow="${prow}Status,${status},"
            prowcheck="${prow}"
            
        fi

        # if power status is not spun up
        if [[ 'Spun_Up' != "$powerStatus" ]]; then
            prow="${prow}Power,${powerStatus},"
            prowcheck="${prow}"
            
        fi

        # if failure predicted
        if [[ 'No' != "$failurePredicted" ]]; then
            prow="${prow}Failure Predicted,${failurePredicted},"
            prowcheck="${prow}"
            
        fi

        # checks for pdisk issues
        checkProwIssues
        # prowAdd
    done

    checkProwVrowCrow

    prowCheck
    
# --------------------------------------------</SUB CONTROLLER LOOP>----------------------------------------
done

# writes rows to file
writeControllerToFile
exit 0