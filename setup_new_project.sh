#!/bin/bash
: '
Author:		Gustav Poulsgaard
Date:		04-02-2026
Purpose:	Create project folders.
Description:
	This script creates a folder structure for a new project or adds to an
	existing project. The structure mimics best-practices for multi-user
	projects as suggested by GenomeDK and adjusted by Gustav.
Usage:
	This script can be run from an empty project directory as:
	bash ./setup_new_project.sh
References:
	https://genome.au.dk/docs/best-practices/
	https://www.howtofair.dk/
'

# turn on safety switches
set -euo pipefail
# e: exit on error. 
# u: undefined variables are errors
# o: pipe exit status should fail if any piped command fails

# source (import / load) setup-utilities
# (should be located in same dir as this script)
# Resolve the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_NAME="setup_utils.sh"
# ${BASH_SOURCE[0]} → path to this script file
# dirname → directory containing the script
# cd ... && pwd → absolute, normalized path

# Source setup_utils.sh from the same directory
source "$SCRIPT_DIR/$UTIL_NAME"


# START LOGGING ===============================================================
TIMESTAMP="$(date '+%Y%m%d_%H%M')"
# logging script activity to logfile
LOGFILE="setup_new_project_log_$TIMESTAMP.out"
# write/overwrite logfile
: > "$LOGFILE"
# save original stdout/stderr (console)
exec 3>&1 4>&2
# send stdout to logfile
exec 1>"$LOGFILE"
# send stderr to console (as stderr) AND logfile
exec 2> >(tee -a "$LOGFILE" >&4)
# send stdout (1) to logfile and stderr (2) to console

# CREATE TOP-LEVEL DIRECTORIES ================================================
# document the creation of the project
printf "Project initialized using setup_new_project.sh on %s by %s\n" \
"$(date '+%Y-%m-%d')" "$(whoami)"

# create the three main directories incl. the first user-specific workspace
mkdir -pv PrimaryData DerivedData WorkSpaces .admin

## EXPAND .admin directory ====================================================
provision_file -v --admin README.md

# create scripts and logs directory
mkdir -pv .admin/backup/scripts/setup .admin/backup/logs

# move this script into admin workspace 
# mv -v ./setup_new_project.sh WorkSpaces/backup/admin/scripts/setup/setup_new_project.sh
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
cp "$SCRIPT_PATH" ".admin/backup/scripts/setup/$SCRIPT_NAME"
echo "cp: copied this setup script to '.admin/backup/scripts/setup/$SCRIPT_NAME'"

cp "$SCRIPT_DIR/$UTIL_NAME" ".admin/backup/scripts/setup/$UTIL_NAME"
echo "cp: copied util script to '.admin/backup/scripts/setup/$UTIL_NAME'"


# EXPAND PrimaryData ==========================================================

provision_file -v -d PrimaryData README.md

# EXPAND DerivedData ==========================================================

mkdir -pv DerivedData/{backup,MainData,Metadata,QC,Reference}
# main:	if only one source of data exist, else name it after the source/method.
# metadata: sample sheets bridging data identifiers with patient identifiers.
# qc: quality control data.
# reference: shared reference data, e.g. genome reference.
provision_file -v -d DerivedData README.md


# Create patientID directories and sampleID subdirectories
# awk 'FNR>1 && $1!="" {pid=$1; sid=$2 print pid "/" sid}' example_sample_manifest.txt | xargs mkdir -p


# EXPAND WorkSpaces ===========================================================

# create a user-specific directory
mkdir -pv "WorkSpaces/$(whoami)"

# create symlink in WorkSpaces to admin in backup
# ln -sv WorkSpaces/backup/admin WorkSpaces/admin

# change directory to user's own workspace
cd "WorkSpaces/$(whoami)"
echo "cd: changed directory to 'WorkSpaces/$(whoami)'"

# create directories and parent directories if they do not already exist
mkdir -pv backup/{scripts,plots,docs} data steps results

# create empty files
provision_file -v environment.yml README.md
# touch backup/environment.yml backup/README.md
# echo "touch: created files 'backup/environment.yml' 'backup/README.md'"
#touch backup/workflow.py backup/templates.py 

# create symbolic link between files in backup-folder and project home-folder
#ln -s backup/workflow.py workflow.py
#ln -s backup/templates.py templates.py
# ln -sv backup/environment.yml environment.yml
# if dir doesnt exist; do symlinks
[[ -e docs ]] || ln -sv backup/docs/ docs
[[ -e scripts ]] || ln -sv backup/scripts/ scripts
[[ -e plots ]] || ln -sv backup/plots/ plots
# [[ -e data ]] || ln -sv backup/data/ data
# ln -sv backup/README.md README.md

# change directory back to project root
cd ../..
echo "cd: changed directory to project root"


# SET PERMISSIONS =============================================================

: '
TODO

Can we specify that all files under PrimaryData are write-protected?

'


# CLEAN UP ====================================================================
# move log into admin/logs
echo "mv: moved './$LOGFILE' to '.admin/backup/logs/$LOGFILE'"
mv "$LOGFILE" ".admin/backup/logs/$LOGFILE"

# stop logging from here onward: restore original stdout/stderr
exec 1>&3 2>&4

# cleanup: close the saved fds
exec 3>&- 4>&-

echo "DONE"