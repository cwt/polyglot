###########################################################
# Create the bash $PROMPT_COMMAND
#
# If $1 is 0, bash's PROMPT_DIRTRIM abbreviations will be
# disabled; the only abbreviation that will occur is that
# $HOME will be displayed as ~.
#
# Arguments:
#   $1 Number of directory elements to display
###########################################################
_polyglot_prompt_command() {
  # $POLYGLOT_PROMPT_DIRTRIM must be greater than 0 and defaults to 2
  [ "$1" ] && PROMPT_DIRTRIM=$1 || PROMPT_DIRTRIM=2

  if ! _polyglot_is_superuser; then
    if _polyglot_has_colors; then
      PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
      PS1+="\$(_polyglot_venv)"
      PS1+="\[\e[01;32m\]\u$(printf '%s' "$POLYGLOT_HOSTNAME_STRING")\[\e[0m\] "
      case $BASH_VERSION in
        # bash, before v4.0, did not have $PROMPT_DIRTRIM
        1.*|2.*|3.*)
          PS1+="\[\e[01;34m\]\$(_polyglot_prompt_dirtrim \$POLYGLOT_PROMPT_DIRTRIM)\[\e[0m\]"
          ;;
        *) PS1+="\[\e[01;34m\]\w\[\e[0m\]" ;;
      esac
      PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] \$ "
    else
      PS1="\$(_polyglot_exit_status \$?)"
      PS1+="\$(_polyglot_venv)"
      PS1+="\u$(printf '%s' "$POLYGLOT_HOSTNAME_STRING") "
      case $BASH_VERSION in
        1.*|2.*|3.*)
         PS1="\$(_polyglot_prompt_dirtrim \$POLYGLOT_PROMPT_DIRTRIM)"
         ;;
        *) PS1+="\w" ;;
      esac
      PS1+="\$(_polyglot_branch_status) \$ "
    fi
  else  # Superuser
    if _polyglot_has_colors; then
      PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
      PS1+="\$(_polyglot_venv)"
      PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
      case $BASH_VERSION in
        1.*|2.*|3.*)
          PS1+="\[\e[01;34m\]\$(_polyglot_prompt_dirtrim \$POLYGLOT_PROMPT_DIRTRIM)\[\e[0m\]"
          ;;
        *) PS1+="\[\e[01;34m\]\w\[\e[0m\]" ;;
      esac
      PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] # "
    else
      PS1="\$(_polyglot_exit_status \$?)"
      PS1+="\$(_polyglot_venv)"
      PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
      case $BASH_VERSION in
        1.*|2.*|3.*)
          PS1+="\$(_polyglot_prompt_dirtrim \$POLYGLOT_PROMPT_DIRTRIM)"
          ;;
        *) PS1+="\w" ;;
      esac
      PS1+="\$(_polyglot_branch_status) # "
    fi
  fi
}

# Only display the $HOSTNAME for an ssh connection
if _polyglot_is_ssh; then
  POLYGLOT_HOSTNAME_STRING='@\h'
else
  POLYGLOT_HOSTNAME_STRING=''
fi

PROMPT_COMMAND='_polyglot_prompt_command $POLYGLOT_PROMPT_DIRTRIM'

# vi command mode
if [ "$TERM" != 'dumb' ]; then     # Line editing not enabled in Emacs shell
  bind 'set show-mode-in-prompt'                      # Since bash 4.3
  bind 'set vi-ins-mode-string "+"'
  bind 'set vi-cmd-mode-string ":"'
fi
