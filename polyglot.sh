#              _             _       _
#  _ __   ___ | |_   _  __ _| | ___ | |_
# | '_ \ / _ \| | | | |/ _` | |/ _ \| __|
# | |_) | (_) | | |_| | (_| | | (_) | |_
# | .__/ \___/|_|\__, |\__, |_|\___/ \__|
# |_|            |___/ |___/
#
# Polyglot Prompt
#
# A dynamic color Git prompt for zsh, bash, ksh93, mksh, pdksh, oksh, dash,
# yash,busybox ash, and osh
#
#
# Source this file from a relevant dotfile (e.g. .zshrc, .bashrc, .shrc, .kshrc,
# .mkshrc, .yashrc, or ~/.config/oil/oshrc) thus:
#
#   . /path/to/polyglot.sh
#
# Set $POLYGLOT_PROMPT_DIRTRIM to the number of directory elements you would
# like to have displayed in your prompt (the default is 2). For example,
#
# POLYGLOT_PROMPT_DIRTRIM=3
#
# results in
#
#   ~/foo/bar/bat/quux
#
# displaying as
#
#   ~/.../bar/bat/quux
#
#
# Copyright 2017-2024 Alexandros Kozak
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#
# https://github.com/agkozak/polyglot
#

# shellcheck shell=ksh
# shellcheck disable=SC2016,SC2034,SC2088,SC3024

# Only run in interactive shells
case $- in
  *i*) ;;
  *) return ;;
esac

# Bail if the shell doesn't have command
if ! type command > /dev/null 2>&1; then
  printf '%s\n' 'Polyglot Prompt does not support your shell.' >&2
  return 1
fi

# Don't let virtual env active scripts alter prompt
VIRTUAL_ENV_DISABLE_PROMPT=1
# Determine the directory where this script resides
if [ -n "$POLYGLOT_DIR" ]; then
  POLYGLOT_BASE_DIR="$POLYGLOT_DIR"
elif [ -n "$ZSH_VERSION" ]; then
  POLYGLOT_BASE_DIR=$(dirname "${(%):-%x}")
elif [ -n "$BASH_VERSION" ]; then
  POLYGLOT_BASE_DIR=$(dirname "${BASH_SOURCE[0]}")
elif (eval 'test -n "${.sh.file}"') 2>/dev/null; then
  POLYGLOT_BASE_DIR=$(dirname "$(eval 'echo "${.sh.file}"')")
else
  # Fallback for other shells (dash, pdksh, etc.)
  # If sourced via relative path (e.g. . ./polyglot.sh), $0 might preserve it in some shells,
  # but in others $0 is the shell name. We default to current directory if not found.
  case "$0" in
    */*) POLYGLOT_BASE_DIR=$(dirname "$0") ;;
    *) POLYGLOT_BASE_DIR="." ;;
  esac
fi

# Load core functionality
if [ -f "$POLYGLOT_BASE_DIR/lib/core.sh" ]; then
  . "$POLYGLOT_BASE_DIR/lib/core.sh"
else
  # Try relative to PWD if detection failed
  if [ -f "./lib/core.sh" ]; then
     POLYGLOT_BASE_DIR="."
     . "./lib/core.sh"
  else
     printf '%s\n' "Polyglot Error: Could not automatically determine installation directory." >&2
     printf '%s\n' "Please set 'POLYGLOT_DIR' to the directory containing polyglot.sh before sourcing it." >&2
     printf '%s\n' "Example: POLYGLOT_DIR=~/polyglot . ~/polyglot/polyglot.sh" >&2
     return 1
  fi
fi

# Load shell-specific functionality
if [ -n "$ZSH_VERSION" ] && [ "${0#-}" != 'ksh' ] &&
  [ "${0#-}" != 'bash' ] && [ "${0#-}" != 'sh' ]; then
  . "$POLYGLOT_BASE_DIR/lib/zsh.sh"

elif [ -n "$BASH_VERSION" ]; then
  . "$POLYGLOT_BASE_DIR/lib/bash.sh"

elif [ -n "$KSH_VERSION" ] || _polyglot_is_dtksh || [ -n "$ZSH_VERSION" ] &&
  ! _polyglot_is_pdksh ; then
  . "$POLYGLOT_BASE_DIR/lib/ksh.sh"

elif _polyglot_is_pdksh || [ "${0#-}" = 'dash' ] || _polyglot_is_busybox ||
  _polyglot_is_yash || _polyglot_sh_is_dash || [ "${0#-}" = 'osh' ]; then
  . "$POLYGLOT_BASE_DIR/lib/sh.sh"

else
  printf '%s\n' 'Polyglot Prompt does not support your shell.' >&2
fi

# Clean up environment
unset POLYGLOT_BASE_DIR
unset -f _polyglot_is_ssh _polyglot_basename _polyglot_is_busybox \
  _polyglot_is_dtksh _polyglot_is_pdksh _polyglot_sh_is_dash

# vim: ts=2:et:sts=2:sw=2
