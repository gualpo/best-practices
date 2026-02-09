#!/bin/bash

: '
Author:		Gustav Poulsgaard
Date:		05-02-2026
Purpose:	Utility functions for setting up projects
Usage:
	Source this script in your script to setup directories
	e.g. setup_new_project.sh
'


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
		# make target directory if it doesn't exist
		mkdir -p "$(dirname "$target")" || {
			printf "ERROR: failed to create: %s\n" "$(dirname "$target")" >&2
			return 1
		}
		# create target file if it doesn't exist
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



# ------------------------------------------------------------------
# human-readable logical conditions
# ------------------------------------------------------------------
_is_symlink() { [[ -L "$1" ]]; }
_exists() { [[ -e "$1" ]]; }
_is_dir() { [[ -d "$1" ]]; }
_is_file() { [[ -f "$1" ]]; }

# ------------------------------------------------------------------
# small helpers (keep output + errors consistent)
# ------------------------------------------------------------------
_err() {
	printf "ERROR: %s\n" "$*" >&2
}

_vprint() {
	# usage: _vprint "$verbose" "message"
	(( $1 )) && printf "%s\n" "${*:2}" >&2
}

_abspath_dir() {
	# prints absolute path of a directory (or fails)
	( cd "$1" 2>/dev/null && pwd )
}

_ensure_dir() {
	# usage: _ensure_dir "dirpath"
	mkdir -p "$1" || { _err "failed to create directory: $1"; return 1; }
}

_touch_if_missing() {
	# usage: _touch_if_missing "$path" "$verbose"
	local path="$1"
	local verbose="$2"

	if ! _exists "$path"; then
		_vprint "$verbose" "Create:  $path"
		touch "$path" || { _err "failed to touch: $path"; return 1; }
	else
		_vprint "$verbose" "Exists:  $path"
	fi
}


_assert_link_is_symlink_or_missing() {
	# usage: _assert_link_is_symlink_or_missing "$link"
	local link="$1"

	if _exists "$link" && ! _is_symlink "$link"; then
		_err "$link exists and is not a symlink (won't overwrite)"
		return 1
	fi
}

_assert_existing_symlink_points_to() {
	# usage: _assert_existing_symlink_points_to "$link" "$expected_rel_target"
	local link="$1"
	local expected="$2"
	local current

	current="$(readlink "$link" 2>/dev/null || true)"
	if [[ "$current" != "$expected" ]]; then
		_err "$link points to '$current' (expected '$expected')"
		return 1
	fi
}

_make_or_verify_symlink() {
	# usage: _make_or_verify_symlink "$link" "$rel_target" "$verbose"
	local link="$1"
	local rel_target="$2"
	local verbose="$3"

	if _is_symlink "$link"; then
		_assert_existing_symlink_points_to "$link" "$rel_target" || return 1
		_vprint "$verbose" "OK:      $link -> $rel_target"
		return 0
	fi

	_vprint "$verbose" "Link:    $link -> $rel_target"
	ln -s "$rel_target" "$link" || { _err "failed to link: $link -> $rel_target"; return 1; }
}

# ------------------------------------------------------------------
# provision_file
#
# Default convention:
#	- Canonical file:	backup/<filename>
#	- Symlink:		<filename>
#
# Optional admin convention (--admin):
#	- Canonical file:	.admin/backup/<filename>
#	- Symlink:		<filename>
#
# Options:
#	-d DIR	Where to provision the file(s)
#	-v	Verbose
#	-a	Admin mode (use .admin/backup)
# ------------------------------------------------------------------
provision_file() {
	local base_dir="$PWD"
	local verbose=0
	local use_admin=0

	local opt OPTARG OPTIND=1
	while getopts ":d:va" opt; do
		case "$opt" in
			d) base_dir="$OPTARG" ;;
			v) verbose=1 ;;
			a) use_admin=1 ;;
			\?) _err "unknown option: -$OPTARG"; return 2 ;;
			:) _err "option -$OPTARG requires an argument"; return 2 ;;
		esac
	done
	shift $((OPTIND - 1))

	[[ $# -ge 1 ]] || {
		_err "Usage: provision_file [-v] [-a] [-d DIR] filename [filename ...]"
		return 2
	}

	base_dir="$(_abspath_dir "$base_dir")" || { _err "base_dir does not exist: $base_dir"; return 1; }

	local store_prefix="backup"
	(( use_admin )) && store_prefix=".admin/backup"

	_vprint "$verbose" "Base directory: $base_dir"
	_vprint "$verbose" "Store prefix:   $store_prefix"

	_ensure_dir "$base_dir/$store_prefix" || return 1

	local filename rel_target target link
	for filename in "$@"; do
		rel_target="$store_prefix/$filename"
		target="$base_dir/$rel_target"
		link="$base_dir/$filename"

		# support nested filenames under backup/ (and .admin/backup/)
		_ensure_dir "$(dirname "$target")" || return 1

		_touch_if_missing "$target" "$verbose" || return 1

		_assert_link_is_symlink_or_missing "$link" || return 1

		_make_or_verify_symlink "$link" "$rel_target" "$verbose" || return 1
	done
}