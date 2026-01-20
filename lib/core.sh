############################################################
# Display non-zero exit status
#
# Arguments:
#   $1 exit status of last command (always $?)
############################################################
_polyglot_exit_status() {
  case $1 in
    0) return ;;
    *) printf '(%d) ' "$1" ;;
  esac
}

###########################################################
# Is the user connected via SSH?
###########################################################
_polyglot_is_ssh() {
  [ -n "${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-}" ]
}

###########################################################
# Provide the effective user ID
###########################################################
_polyglot_euid() {
  case ${POLYGLOT_UNAME:=$(uname -s)} in
    SunOS) /usr/xpg4/bin/id -u ;;
    *) id -u ;;
  esac
}

###########################################################
# Is the user a superuser?
###########################################################
_polyglot_is_superuser() {
  # shellcheck disable=SC3028
  [ ${EUID:-$(_polyglot_euid)} -eq 0 ]
}

###########################################################
# Does the terminal support enough colors?
###########################################################
_polyglot_has_colors() {
  [ -n "$ZSH_VERSION" ] && setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL

  # The DragonFly BSD system console has trouble displaying colors in pdksh
  case ${POLYGLOT_UNAME:=$(uname -s)} in
    DragonFly)
      case $(who am i) in *ttyv*) return 1 ;; esac
      ;;
  esac

  case $TERM in
    *-256color) POLYGLOT_TERM_COLORS=256 ;;
    vt100|dumb) POLYGLOT_TERM_COLORS=-1 ;;
    *)
      if command -v tput > /dev/null 2>&1; then
        case ${POLYGLOT_UNAME:=$(uname -s)} in
          FreeBSD|DragonFly) POLYGLOT_TERM_COLORS=$(tput Co) ;;
          UWIN*) POLYGLOT_TERM_COLORS=$(tput cols) ;;
          *) POLYGLOT_TERM_COLORS=$(tput colors) ;;
        esac
      else
        POLYGLOT_TERM_COLORS=-1
      fi
      ;;
  esac
  if [ "${POLYGLOT_TERM_COLORS:-0}" -ge 8 ]; then
    unset POLYGLOT_TERM_COLORS
    return 0
  else
    unset POLYGLOT_TERM_COLORS
    return 1
  fi
}

############################################################
# Emulation of bash's PROMPT_DIRTRIM for all other shells
# and for bash before v4.0
#
# In $PWD, substitute $HOME with ~; if the remainder of the
# $PWD has more than a certain number of directory elements
# to display (default: 2), abbreviate it with '...', e.g.
#
#   $HOME/dotfiles/polyglot/img
#
# will be displayed as
#
#   ~/.../polyglot/img
#
# If $1 is 0, no abbreviation will occur other than that
# $HOME will be displayed as ~.
#
# Arguments:
#   $1 Number of directory elements to display
############################################################
_polyglot_prompt_dirtrim() {
  # Necessary for set -- $1 to undergo field separation in zsh
  [ -n "$ZSH_VERSION" ] && setopt LOCAL_OPTIONS SH_WORD_SPLIT \
    NO_WARN_CREATE_GLOBAL NO_WARN_NESTED_VAR 2> /dev/null

  POLYGLOT_DIRTRIM_ELEMENTS="${1:-2}"

  # If root has / as $HOME, print /, not ~
  [ "$PWD" = '/' ] && printf '%s' '/' && return
  [ "$PWD" = "$HOME" ] && printf '%s' '~' && return

  case $HOME in
    /) POLYGLOT_PWD_MINUS_HOME="$PWD" ;;            # In case root's $HOME is /
    *) POLYGLOT_PWD_MINUS_HOME="${PWD#"$HOME"}" ;;
  esac

  if [ "$POLYGLOT_DIRTRIM_ELEMENTS" -eq 0 ]; then
    [ "$HOME" = '/' ] && printf '%s' "$PWD" && return
    case $PWD in
      ${HOME}*) printf '~%s' "$POLYGLOT_PWD_MINUS_HOME" ;;
      *) printf '%s' "$PWD" ;;
    esac
  else
    # Calculate the part of $PWD that will be displayed in the prompt
    POLYGLOT_OLD_IFS="$IFS"
    IFS='/'
    # shellcheck disable=SC2086
    set -- $POLYGLOT_PWD_MINUS_HOME
    shift                                  # Discard empty first field preceding /

    # Discard path elements > $POLYGLOT_PROMPT_DIRTRIM
    while [ $# -gt "$POLYGLOT_DIRTRIM_ELEMENTS" ]; do
      shift
    done

    # Reassemble the remaining path elements with slashes
    while [ $# -ne 0 ]; do
      POLYGLOT_ABBREVIATED_PATH="${POLYGLOT_ABBREVIATED_PATH}/$1"
      shift
    done

    IFS="$POLYGLOT_OLD_IFS"

    # If the working directory has not been abbreviated, display it thus
    if [ "$POLYGLOT_ABBREVIATED_PATH" = "${POLYGLOT_PWD_MINUS_HOME}" ]; then
      if [ "$HOME" = '/' ]; then
        printf '%s' "$PWD"
      else
        case $PWD in
          ${HOME}*) printf '~%s' "${POLYGLOT_PWD_MINUS_HOME}" ;;
          *) printf '%s' "$PWD" ;;
        esac
      fi
    # Otherwise include an ellipsis to show that abbreviation has taken place
    else
      if [ "$HOME" = '/' ]; then
        printf '...%s' "$POLYGLOT_ABBREVIATED_PATH"
      else
        case $PWD in
          ${HOME}*) printf '~/...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
          *) printf '...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
        esac
      fi
    fi
  fi

  unset POLYGLOT_DIRTRIM_ELEMENTS POLYGLOT_PWD_MINUS_HOME POLYGLOT_OLD_IFS \
    POLYGLOT_ABBREVIATED_PATH
}

###########################################################
# Display Mercurial branch/bookmark and status
#
# Arguments:
#   $1  If ksh, escape ! as !!
###########################################################
_polyglot_hg_status() {
  # Check if hg is available
  command -v hg >/dev/null 2>&1 || return

  # Check if in hg repo and get ref (bookmark or branch) in one go
  # Format: bookmarks|branch
  # If this fails (exit code != 0), we are likely not in a repo.
  POLYGLOT_HG_INFO=$(env hg log -r . -T "{bookmarks}|{branch}" 2>/dev/null)
  if [ $? -ne 0 ]; then return; fi

  POLYGLOT_HG_REF="${POLYGLOT_HG_INFO%%|*}"
  POLYGLOT_HG_BRANCH="${POLYGLOT_HG_INFO#*|}"

  # Use branch if no bookmarks
  [ -z "$POLYGLOT_HG_REF" ] && POLYGLOT_HG_REF="$POLYGLOT_HG_BRANCH"

  # Get status codes
  POLYGLOT_HG_STATUS_CODES=$(env hg status -T "{status}" 2>/dev/null)

  POLYGLOT_SYMBOLS=''

  # Modified
  case "$POLYGLOT_HG_STATUS_CODES" in *M*)
    if [ "$1" = 'ksh' ]; then
      POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!!"
    else
      POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!"
    fi
    ;;
  esac

  # Added
  case "$POLYGLOT_HG_STATUS_CODES" in *A*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}+" ;; esac

  # Removed / Deleted
  case "$POLYGLOT_HG_STATUS_CODES" in *R*|*\!*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}x" ;; esac

  # Untracked
  case "$POLYGLOT_HG_STATUS_CODES" in *\?*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}?" ;; esac

  [ -n "$POLYGLOT_SYMBOLS" ] && POLYGLOT_SYMBOLS=" $POLYGLOT_SYMBOLS"

  printf ' (%s%s)' "$POLYGLOT_HG_REF" "$POLYGLOT_SYMBOLS"

  unset POLYGLOT_HG_INFO POLYGLOT_HG_REF POLYGLOT_HG_BRANCH POLYGLOT_HG_STATUS_CODES POLYGLOT_SYMBOLS
}

###########################################################
# Display current branch name, followed by symbols
# representing changes to the working copy
#
# Arguments:
#   $1  If ksh, escape ! as !!
#
# shellcheck disable=SC2120
###########################################################
_polyglot_branch_status() {
  [ -n "$ZSH_VERSION" ] && setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL \
    NO_WARN_NESTED_VAR > /dev/null 2>&1

  POLYGLOT_REF="$(env git symbolic-ref --quiet HEAD 2> /dev/null)"
  case $? in        # See what the exit code is.
    0) ;;           # $POLYGLOT_REF contains the name of a checked-out branch.
    128)            # No Git repository here.
      _polyglot_hg_status "$1"
      return
      ;;
    # Otherwise, see if HEAD is in a detached state.
    *) POLYGLOT_REF="$(env git rev-parse --short HEAD 2> /dev/null)" || return ;;
  esac

  if [ -n "$POLYGLOT_REF" ]; then
    if [ "${POLYGLOT_SHOW_UNTRACKED:-1}" -eq 0 ]; then
      POLYGLOT_GIT_STATUS=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 env git status -uno 2>&1)
    else
      POLYGLOT_GIT_STATUS=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 env git status 2>&1)
    fi

    POLYGLOT_SYMBOLS=''

    case $POLYGLOT_GIT_STATUS in
      *' have diverged,'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&*" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'Your branch is behind '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'Your branch is ahead of '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}*" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'new file:   '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}+" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'deleted:    '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}x" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'modified:   '*)
        if [ "$1" = 'ksh' ]; then
          POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!!"
        else
          POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!"
        fi
        ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'renamed:    '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}>" ;;
    esac
    case $POLYGLOT_GIT_STATUS in
      *'Untracked files:'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}?" ;;
    esac

    [ -n "$POLYGLOT_SYMBOLS" ] && POLYGLOT_SYMBOLS=" $POLYGLOT_SYMBOLS"

    printf ' (%s%s)' "${POLYGLOT_REF#refs/heads/}" "$POLYGLOT_SYMBOLS"
  fi

  unset POLYGLOT_REF POLYGLOT_GIT_STATUS POLYGLOT_SYMBOLS
}

###########################################################
# Native sh alternative to basename. See
# https://github.com/dylanaraps/pure-sh-bible
#
# Arguments:
#   $1 Filename
#   $2 Suffix
###########################################################
_polyglot_basename() {
  POLYGLOT_BASENAME_DIR=${1%"${1##*[!/]}"}
  POLYGLOT_BASENAME_DIR=${POLYGLOT_BASENAME_DIR##*/}
  POLYGLOT_BASENAME_DIR=${POLYGLOT_BASENAME_DIR%"$2"}

  printf '%s\n' "${POLYGLOT_BASENAME_DIR:-/}"

  unset POLYGLOT_BASENAME_DIR
}

###########################################################
# Tests to see if the current shell is busybox ash
###########################################################
_polyglot_is_busybox() {
  case $(help 2> /dev/null) in
    'Built-in commands:'*) return 0 ;;
    *) return 1 ;;
  esac
}

###########################################################
# Test to see if the current shell is pdksh or oksh
###########################################################
_polyglot_is_pdksh() {
  case $KSH_VERSION in
    *'PD KSH'*)
      if [ "${POLYGLOT_UNAME:=$(uname -s)}" = 'OpenBSD' ] ||
         [ "${0#-}" = 'oksh' ]; then
        POLYGLOT_KSH_BANG='ksh'
      fi
      return 0
      ;;
    *) return 1 ;;
  esac
}

###########################################################
# Test to see if the current shell is dtksh (Desktop Korn
# Shell).
###########################################################
_polyglot_is_dtksh() {
  case ${0#-} in
    *dtksh) return 0 ;;
    *) return 1 ;;
  esac
}

###########################################################
# Test to see if sh is really dash
###########################################################
_polyglot_sh_is_dash() {
  case $(ls -l "$(command -v "${0#-}")") in
    *dash*) return 0 ;;
    *) return 1 ;;
  esac
}

_polyglot_is_yash()
{
  case "${0#-}" in
    *yash) return 0 ;;
    *) return 1 ;;
  esac
}

###########################################################
# Output virtual environment name
###########################################################
_polyglot_venv() {
  # pipenv/poetry: when the virtualenv is in the project directory
  if [ "${VIRTUAL_ENV##*/}" = '.venv' ]; then
    POLYGLOT_VENV=${VIRTUAL_ENV%/.venv}
    POLYGLOT_VENV=${POLYGLOT_VENV##*/}
  # pipenv
  elif [ -n "$PIPENV_ACTIVE" ]; then
    POLYGLOT_VENV=${VIRTUAL_ENV%-*}
    POLYGLOT_VENV=${POLYGLOT_VENV##*/}
  # virtualenv/venv
  elif [ -n "$VIRTUAL_ENV" ]; then
    POLYGLOT_VENV=${VIRTUAL_ENV##*/}
  # conda
  elif [ -n "$CONDA_DEFAULT_ENV" ]; then
    POLYGLOT_VENV=$CONDA_DEFAULT_ENV
  fi

  [ -n "$POLYGLOT_VENV" ] && printf '(%s) ' "$POLYGLOT_VENV"

  unset POLYGLOT_VENV
}
