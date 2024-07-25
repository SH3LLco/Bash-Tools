#!/bin/bash
# Author: SH3LL
# CoAuthor: EchoTango
# Github: https://github.com/SH3LLco
                                                                                                                         
# -----------------------------------------------<FUNCTIONS>-----------------------------------------------

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
file="report.csv"

# gets host name
host=$(hostname | cut -f1 -d .)

# write host name to file
echo "${host}" >> $file

# empty line for formatting
line=' '

# gets controllers and sets variables/array
# controllers=$(cat controller0.txt) | Testing
controllers=$(omreport storage controller)
controllerids=($(getControllers "ID"))
controllercount=${#controllerids[@]}
totalcontrollerissues=()

# --------------------------------------------</STATIC VARIABLES>--------------------------------------------

# ----------------------------------------------<CHASSIS CHECK>----------------------------------------------

# sets chassis variables
# chreport=$(cat chassis.txt) | Testing
chreport=$(omreport chassis)
chrow=''
chrowreport=()

# sets chassis components
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

# check components
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

# sets reported issues to # of issues found
reportedchassisissues="${#chrowreport[@]}"

# loops through issues found and writes to file
if [[ $reportedchassisissues -eq 0 ]]; then
        echo ",Chassis No Issues" >> $file
    else 
        echo ",Chassis" >> $file
        for i in $(seq 0 $(($reportedchassisissues - 1))); do
            echo "${chrowreport[$i]}" >> $file
        done
        echo "$line" >> $file
fi


# ----------------------------------------------</CHASSIS CHECK>--------------------------------------------

# -------------------------------------------<MAIN CONTROLLER LOOP>-----------------------------------------

# for loop based on controller count
for i in $(seq 0 $(($controllercount -1))); do
    
    # get the battery report and set variables/array
    # breport=$(cat battery.txt) | Testing
    breport=$(omreport storage battery)
    bstatuses=($(getBattery "Status")) 
    bstatus="${bstatuses[$i]}"
    brow=''
    browissues=''

    # get the enclosure report and set variables/array
    # ereport=$(cat enclosure.txt) | Testing
    ereport=$(omreport storage enclosure)
    estatuses=($(getEnclosure "Status")) 
    estatus="${estatuses[$i]}"
    erow=''
    erowissues=''

    # get the pdisk report
    # preport=$(cat preport0.txt) | Testing
    preport=$(omreport storage pdisk controller=$i)

    # get the vdisk report to array
    # vreport=$(cat vreport0.txt) | Testing
    vreport=$(omreport storage vdisk controller=$i)
    vstatuses=($(getVReport "Status"))
    vrowissues=''

    # gets controller status to array and sets crow variables
    cstatuses=($(getControllers "Status")) 
    cstatus="${cstatuses[$i]}"
    crow=''
    crowissues=''

    # assigns pdisk variables for loop
    driveids=($(getPResult "ID"))
    states=($(getPResult "State"))
    statuses=($(getPResult "Status"))
    powerStatuses=($(getPResult "Power Status"))
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

    # checks for erow issues
    checkErowIssues

    # check for vrow and crow for formatting
    checkVrowIssues

    # creates empty array for prow issues
    mainprowissues=()
# ------------------------------------------</MAIN CONTROLLER LOOP>-----------------------------------------

# --------------------------------------------<SUB CONTROLLER LOOP>-----------------------------------------
    # for loop based on drive count
    for j in $(seq 0 $(($drivecount - 1))); do
        
        # sets pdisk variables for ease of use
        state="${states[$j]}"
        status="${statuses[$j]}"
        powerStatus="${powerStatuses[$j]}"
        failurePredicted="${failurePredicteds[$j]}"
        id="${driveids[$j]}"

        # sets empty variable for prow content and issues
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
    done

    # checks prow vrow and crow to assign controller id if needed
    checkProwVrowCrow

    # checks prow for formatting
    prowCheck
    
# --------------------------------------------</SUB CONTROLLER LOOP>----------------------------------------
done

# writes rows to file
writeControllerToFile
exit 0
