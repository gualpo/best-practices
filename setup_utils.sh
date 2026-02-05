#!/bin/bash

: '
Author:		Gustav Poulsgaard
Date:		05-02-2026
Purpose:	Utility functions for setting up projects
Usage:
	Source this script in your script to setup directories
	e.g. setup_new_project.sh
'

deprecated2_provision_file() {

	# ------------------------------------------------------------------
	# provision_file
	#
	# Goal:
	#	Create one or more "managed" files in a project folder in a safe,
	#	predictable way.
	#
	# Convention enforced:
	#	- The real file lives in:	backup/<filename>
	#	- A symlink is exposed as:	<filename>  (in the base directory)
	#
	# Why:
	#	- Keeps "important files" in one known place (backup/)
	#	- Still lets users open README.md, environment.yml, etc. directly
	#	- Symlink is relative, so the project can be moved without breaking
	#
	# Safety:
	#	- Never overwrites an existing real file or directory
	#	- If a symlink exists, it must already point to the expected target
	#
	# Options:
	#	-d, --destination DIR	Where to provision the file(s)
	#	-v, --verbose		Print what is happening
	#
	# Usage:
	#	provision_file filename [filename ...]
	#	provision_file -d DIR filename [filename ...]
	# ------------------------------------------------------------------

	local base_dir="$PWD"
	local verbose=0

	# vprint prints only when verbose mode is enabled
	vprint() {
		(( verbose )) && printf "%s\n" "$*" >&2
	}

	# Parse options (stop when we hit the first non-option argument)
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-d|--destination)
				# -d needs a directory argument after it
				[[ $# -ge 2 ]] || {
					printf "ERROR: -d|--destination requires an argument\n" >&2
					return 2
				}
				base_dir="$2"
				shift 2
				;;
			-v|--verbose)
				verbose=1
				shift
				;;
			--)
				# Explicit end of options marker
				shift
				break
				;;
			-*)
				printf "ERROR: unknown option: %s\n" "$1" >&2
				return 2
				;;
			*)
				# First filename encountered → stop parsing options
				break
				;;
		esac
	done

	# Must have at least one filename left after parsing options
	[[ $# -ge 1 ]] || {
		printf "Usage: provision_file [-v] [-d DIR] filename [filename ...]\n" >&2
		return 2
	}

	# Convert destination directory to an absolute path.
	# If it doesn't exist, cd will fail and we abort.
	base_dir="$(cd "$base_dir" && pwd)" || {
		printf "ERROR: base_dir does not exist: %s\n" "$base_dir" >&2
		return 1
	}

	# Ensure the backup folder exists once (shared for all files)
	vprint "Base directory: $base_dir"
	mkdir -p "$base_dir/backup" || {
		printf "ERROR: failed to create: %s\n" "$base_dir/backup" >&2
		return 1
	}

	# Provision each file the user requested
	local filename rel_target target link current
	for filename in "$@"; do

		# Relative symlink target (portable if project is moved)
		rel_target="backup/$filename"

		# Absolute path of the canonical file in backup/
		target="$base_dir/$rel_target"

		# Absolute path of the symlink in the base directory
		link="$base_dir/$filename"

		# If filename contains subfolders (e.g. workflow/qc/workflow.py),
		# make sure backup/workflow/qc exists before touching the file.
		mkdir -p "$(dirname "$target")" || {
			printf "ERROR: failed to create: %s\n" "$(dirname "$target")" >&2
			return 1
		}

		# Create the canonical file only if missing (never overwrite)
		if [[ ! -e "$target" ]]; then
			vprint "Create: $target"
			touch "$target" || {
				printf "ERROR: failed to touch: %s\n" "$target" >&2
				return 1
			}
		else
			vprint "Exists:  $target"
		fi

		# If something already exists at <base_dir>/<filename> and it is NOT a symlink,
		# we refuse to overwrite it (it could be a real file or a directory).
		if [[ -e "$link" && ! -L "$link" ]]; then
			printf "ERROR: %s exists and is not a symlink (won't overwrite)\n" "$link" >&2
			return 1
		fi

		# If the symlink exists already, verify it points where we expect.
		# This prevents "surprising rewires" that could hide someone else's file.
		if [[ -L "$link" ]]; then
			current="$(readlink "$link" 2>/dev/null || true)"
			if [[ "$current" != "$rel_target" ]]; then
				printf "ERROR: %s points to '%s' (expected '%s')\n" \
					"$link" "$current" "$rel_target" >&2
				return 1
			fi
			vprint "OK:      $link -> $current"
			continue
		fi

		# Create the symlink (relative path target)
		vprint "Link:    $link -> $rel_target"
		ln -s "$rel_target" "$link" || {
			printf "ERROR: failed to link: %s -> %s\n" "$link" "$rel_target" >&2
			return 1
		}
	done
}


provision_dir() {

	# ------------------------------------------------------------------
	# provision_dir
	#
	# Goal:
	#	Create one or more "managed" directories in a project folder safely.
	#
	# Convention enforced:
	#	- The real directory lives in:	backup/<dirname>/
	#	- A symlink is exposed as:	<dirname>/  (in the base directory)
	#
	# Why:
	#	- Keeps "managed directories" together under backup/
	#	- Users still see and use <dirname>/ normally in the workspace
	#	- Relative symlinks survive moving the project folder
	#
	# Safety:
	#	- Never overwrites an existing real directory/file
	#	- If the symlink exists, it must already point to the expected target
	#
	# Options:
	#	-d, --destination DIR	Where to provision the directory(ies)
	#	-v, --verbose		Print what is happening
	#
	# Usage:
	#	provision_dir dirname [dirname ...]
	#	provision_dir -d DIR dirname [dirname ...]
	# ------------------------------------------------------------------

	local base_dir="$PWD"
	local verbose=0

	vprint() {
		(( verbose )) && printf "%s\n" "$*" >&2
	}

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-d|--destination)
				[[ $# -ge 2 ]] || {
					printf "ERROR: -d|--destination requires an argument\n" >&2
					return 2
				}
				base_dir="$2"
				shift 2
				;;
			-v|--verbose)
				verbose=1
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				printf "ERROR: unknown option: %s\n" "$1" >&2
				return 2
				;;
			*)
				break
				;;
		esac
	done

	[[ $# -ge 1 ]] || {
		printf "Usage: provision_dir [-v] [-d DIR] dirname [dirname ...]\n" >&2
		return 2
	}

	base_dir="$(cd "$base_dir" && pwd)" || {
		printf "ERROR: base_dir does not exist: %s\n" "$base_dir" >&2
		return 1
	}

	vprint "Base directory: $base_dir"
	mkdir -p "$base_dir/backup" || {
		printf "ERROR: failed to create: %s\n" "$base_dir/backup" >&2
		return 1
	}

	local dirname rel_target target link current
	for dirname in "$@"; do

		rel_target="backup/$dirname"
		target="$base_dir/$rel_target"
		link="$base_dir/$dirname"

		# Create the canonical directory under backup/ (including parents)
		if [[ ! -d "$target" ]]; then
			vprint "Create dir: $target"
			mkdir -p "$target" || {
				printf "ERROR: failed to create directory: %s\n" "$target" >&2
				return 1
			}
		else
			vprint "Exists dir: $target"
		fi

		# Refuse to overwrite any existing non-symlink at the link location
		if [[ -e "$link" && ! -L "$link" ]]; then
			printf "ERROR: %s exists and is not a symlink (won't overwrite)\n" "$link" >&2
			return 1
		fi

		# If symlink exists, verify it points where expected
		if [[ -L "$link" ]]; then
			current="$(readlink "$link" 2>/dev/null || true)"
			if [[ "$current" != "$rel_target" ]]; then
				printf "ERROR: %s points to '%s' (expected '%s')\n" \
					"$link" "$current" "$rel_target" >&2
				return 1
			fi
			vprint "OK link:   $link -> $current"
			continue
		fi

		# Create the relative symlink
		vprint "Link dir:  $link -> $rel_target"
		ln -s "$rel_target" "$link" || {
			printf "ERROR: failed to link: %s -> %s\n" "$link" "$rel_target" >&2
			return 1
		}
	done
}


deprecated1_provision_file() {

	# ------------------------------------------------------------------
	# Ensure canonical project file(s) exist under backup/
	# and are exposed via symlinks in the working directory.
	#
	# Directory selection is ONLY allowed via -d / --destination.
	# Positional arguments are always treated as filenames.
	#
	# Options:
	#	-d, --destination DIR	target directory
	#	-v, --verbose		print actions
	# ------------------------------------------------------------------

	local base_dir="$PWD"
	local verbose=0

	vprint() {
		(( verbose )) && printf "%s\n" "$*" >&2
	}

	# Parse options
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-d|--destination)
				[[ $# -ge 2 ]] || {
					printf "ERROR: -d|--destination requires an argument\n" >&2
					return 2
				}
				base_dir="$2"
				shift 2
				;;
			-v|--verbose)
				verbose=1
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				printf "ERROR: unknown option: %s\n" "$1" >&2
				return 2
				;;
			*)
				break
				;;
		esac
	done

	# Require at least one filename
	[[ $# -ge 1 ]] || {
		printf "Usage: provision_file [-v] [-d DIR] filename [filename ...]\n" >&2
		return 2
	}

	# Normalize base_dir to absolute path
	base_dir="$(cd "$base_dir" && pwd)" || {
		printf "ERROR: base_dir does not exist: %s\n" "$base_dir" >&2
		return 1
	}

	# Ensure backup directory exists once
	vprint "Base directory: $base_dir"
	mkdir -p "$base_dir/backup"

	# Provision each file
	local filename rel_target target link current
	for filename in "$@"; do

		rel_target="backup/$filename"
		target="$base_dir/$rel_target"
		link="$base_dir/$filename"

		# Create canonical file if missing
		if [[ ! -e "$target" ]]; then
			vprint "Create: $target"
			touch "$target"
		else
			vprint "Exists:  $target"
		fi

		# If link exists and is not a symlink, refuse to overwrite it
		if [[ -e "$link" && ! -L "$link" ]]; then
			printf "ERROR: %s exists and is not a symlink (won't overwrite)\n" "$link" >&2
			return 1
		fi

		# If symlink exists, verify it points to the expected target
		if [[ -L "$link" ]]; then
			current="$(readlink "$link" 2>/dev/null || true)"
			if [[ "$current" != "$rel_target" ]]; then
				printf "ERROR: %s points to '%s' (expected '%s')\n" \
					"$link" "$current" "$rel_target" >&2
				return 1
			fi
			vprint "OK:      $link -> $current"
			continue
		fi

		# Create relative symlink
		vprint "Link:    $link -> $rel_target"
		ln -s "$rel_target" "$link"
	done
}




provision_file() {

	# ------------------------------------------------------------------
	# provision_file
	#
	# Default convention:
	#	- Canonical file:	backup/<filename>
	#	- Symlink:		<filename>
	#
	# Optional admin convention (use --admin):
	#	- Canonical file:	.admin/backup/<filename>
	#	- Symlink:		<filename>
	#
	# Options:
	#	-d, --destination DIR	Where to provision the file(s)
	#	-v, --verbose		Print what is happening
	#	--admin			Use .admin/backup instead of backup
	# ------------------------------------------------------------------

	local base_dir="$PWD"
	local verbose=0
	local use_admin=0

	vprint() {
		(( verbose )) && printf "%s\n" "$*" >&2
	}

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-d|--destination)
				[[ $# -ge 2 ]] || {
					printf "ERROR: -d|--destination requires an argument\n" >&2
					return 2
				}
				base_dir="$2"
				shift 2
				;;
			-v|--verbose)
				verbose=1
				shift
				;;
			--admin)
				use_admin=1
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				printf "ERROR: unknown option: %s\n" "$1" >&2
				return 2
				;;
			*)
				break
				;;
		esac
	done

	[[ $# -ge 1 ]] || {
		printf "Usage: provision_file [-v] [--admin] [-d DIR] filename [filename ...]\n" >&2
		return 2
	}

	base_dir="$(cd "$base_dir" && pwd)" || {
		printf "ERROR: base_dir does not exist: %s\n" "$base_dir" >&2
		return 1
	}

	# Choose where the canonical file should live (relative to base_dir)
	local store_prefix
	if (( use_admin )); then
		store_prefix=".admin/backup"
	else
		store_prefix="backup"
	fi

	vprint "Base directory: $base_dir"
	vprint "Store prefix:   $store_prefix"

	mkdir -p "$base_dir/$store_prefix" || {
		printf "ERROR: failed to create: %s\n" "$base_dir/$store_prefix" >&2
		return 1
	}

	local filename rel_target target link current
	for filename in "$@"; do

		rel_target="$store_prefix/$filename"
		target="$base_dir/$rel_target"
		link="$base_dir/$filename"

		# Support nested filenames
		mkdir -p "$(dirname "$target")" || {
			printf "ERROR: failed to create: %s\n" "$(dirname "$target")" >&2
			return 1
		}

		if [[ ! -e "$target" ]]; then
			vprint "Create: $target"
			touch "$target" || {
				printf "ERROR: failed to touch: %s\n" "$target" >&2
				return 1
			}
		else
			vprint "Exists:  $target"
		fi

		if [[ -e "$link" && ! -L "$link" ]]; then
			printf "ERROR: %s exists and is not a symlink (won't overwrite)\n" "$link" >&2
			return 1
		fi

		if [[ -L "$link" ]]; then
			current="$(readlink "$link" 2>/dev/null || true)"
			if [[ "$current" != "$rel_target" ]]; then
				printf "ERROR: %s points to '%s' (expected '%s')\n" \
					"$link" "$current" "$rel_target" >&2
				return 1
			fi
			vprint "OK:      $link -> $current"
			continue
		fi

		vprint "Link:    $link -> $rel_target"
		ln -s "$rel_target" "$link" || {
			printf "ERROR: failed to link: %s -> %s\n" "$link" "$rel_target" >&2
			return 1
		}
	done
}