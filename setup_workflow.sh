#!/bin/bash
: '
Author:		Gustav Poulsgaard
Date:		04-02-2026
Purpose:	Create workflow folders.
Description:
	This script creates a folder structure for a new workflow or adds to an
	existing directory. The structure mimics best-practices as suggested by
	GenomeDK and adjusted by Gustav.
Usage:
	This script can be run from an empty project directory as:
	bash ./setup_new_workflow.sh
References:
	https://genome.au.dk/docs/best-practices/
	https://www.howtofair.dk/
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_NAME="setup_utils.sh"
# ${BASH_SOURCE[0]} → path to this script file
# dirname → directory containing the script
# cd ... && pwd → absolute, normalized path
# Source setup_utils.sh from the same directory
source "$SCRIPT_DIR/$UTIL_NAME"

mkdir -pv backup/{scripts,plots,docs} data steps results

_exists "scripts" || ln -sv backup/scripts/ scripts
_exists "docs" || ln -sv backup/docs/ docs
_exists "scripts" || ln -sv backup/scripts/ scripts
_exists "plots" || ln -sv backup/plots/ plots

provision_file -v environment.yml README.md workflow.py