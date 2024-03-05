#!/bin/bash

# -----------------------------------------------<FUNCTIONS>-----------------------------------------------

# function to get filename
function getFileName {
    date=$(date +%Y-%m-%d)
    host=$(hostname | cut -f1 -d .)
    echo "$date-$host.txt"
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

# -----------------------------------------------</FUNCTIONS>-----------------------------------------------

# --------------------------------------------<STATIC VARIABLES>--------------------------------------------

# gets controllers and sets to variable
# commented for testing: controller=$(omreport storage controller)
controllers=$(cat controllers.txt)

# gets controller IDs and sets to array
controllerids=($(getControllers "ID"))

# gets length of controllerids
controllercount=${#controllerids[@]}

# sets logfile variable to getFileName function
logFile=$(getFileName)

# creates empty issue array that we will use to report issues
issues=()

# --------------------------------------------</STATIC VARIABLES>-------------------------------------------

# ------------------------------------------------<MAIN LOOP>-----------------------------------------------

# for loop based on controller count
for i in $(seq 0 $(($controllercount -1))); do

    # get the pdisk report
    # commented for testing: preport=$(omreport storage pdisk controller=$i)
    preport=$(cat preport.txt)

    # get the vdisk report
    # commented for testing: vreport=$(omreport storage vdisk controller=$i)
    vreport=$(cat vreport.txt)

    # sets vdisk status array
    vstatuses=($(getVReport "Status"))

    # sets vdisk status variable for ease of use
    vstatus="${vstatuses[$i]}"

    # creates empty variable to append to later
    vrow=''

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
    controllerid="Controller $i"
    
    # if disk status is not ok, add to issues and vrow
    if [[ 'Ok' != "$vstatus" ]]; then
        issues+=("$controllerid Status: $vstatus")
        vrow="${vrow} $vstatus, "
    fi
    
    # if vrow is empty, echo no issues, else add controller id to vrow
    if [[ -z "$vrow" ]]; then
            echo "No Issues"
        else 
            vrow="${controllerid} ${vrow}, "
    fi

# ------------------------------------------------</MAIN LOOP>-----------------------------------------------

# -------------------------------------------------<SUB LOOP>------------------------------------------------
    # for loop based on drive count
    for j in `seq 0 $(($drivecount - 1))`; do
        
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

        # creates empty variable for storing pdisk output
        prow=''

        # if state is not ready or online
        if [[ 'Ready' != "$state" ]] && [[ 'Online' != "$state" ]]; then
            issues+=("$id State: $state")
            prow="${prow} $state, "
        fi

        # if status is not ok
        if [[ 'Ok' != "$status" ]]; then
            issues+=("$id Status: $status")
            prow="${prow} $status, "
        fi

        # if power status is not spun up
        if [[ 'Spun_Up' != "$powerStatus" ]]; then
            issues+=("$id Power Status: $powerStatus")
            prow="${prow} $powerStatus, "
        fi

        if [[ 'No' != "$failurePredicted" ]]; then
            issues+=("$id Failure Predicted: $failurePredicted")
            prow="${prow} $failurePredicted, "
        fi
        
        # Used for testing: echo "$row" "$i"
        # if prow is empty, echo no issues, else add drive id to prow
        if [[ -z "$prow" ]]; then
            echo "No Issues"
        else 
            prow="${id} ${prow}, "
        fi

    done

# -------------------------------------------------</SUB LOOP>------------------------------------------------

# ---------------------------------------------<CHECKS & REPORTING>-------------------------------------------

    # Used for testing: echo $row | grep .
    # gets # of issues
    reportedissues="${#issues[@]}"

    # if # of issues is 0 then echo no issues, else echo each issue. 
    if [[ $reportedissues -eq 0 ]]; then
        echo "No Issues Found"
    else 
        for i in `seq 0 $(($reportedissues - 1))`; do
            echo "${issues[$i]}"     
        done
    fi
    
done    

# ---------------------------------------------</CHECKS & REPORTING>------------------------------------------
