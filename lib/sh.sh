if _polyglot_is_ssh || _polyglot_is_superuser; then
  POLYGLOT_HOSTNAME_STRING=$(hostname)
  POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%%\.*}"
else
  POLYGLOT_HOSTNAME_STRING=''
fi

# pdksh uses an arbitrary non-printing character to delimit color escape
# sequences in the prompt. In practice, however, it is impossible to find
# one single non-printing character that will work with all operating systems
# and terminals. The Polyglot Prompt defaults to \021 for OpenBSD/NetBSD
# and \016 for everything else. If you want to specify your own non-printing
# character, do so thus:
#
# POLYGLOT_NP="\016" # Set this variable to whatever value you like
#
# Or set POLYGLOT_PDKSH_COLORS=0 to disable color entirely in pdksh.

case ${POLYGLOT_UNAME} in
  NetBSD*|OpenBSD*) POLYGLOT_NP=${POLYGLOT_NP:-"\021"} ;;
  *) POLYGLOT_NP=${POLYGLOT_NP:-"\016"} ;;
esac

if _polyglot_is_pdksh &&
   _polyglot_has_colors &&
   [ ${POLYGLOT_PDKSH_COLORS:-1} -ne 0 ]; then

  PS1=$(print "$POLYGLOT_NP\r")
  case $POLYGLOT_UNAME in
    NetBSD*|OpenBSD*) PS1=$PS1$(print "$POLYGLOT_NP") ;;
  esac
  PS1=$PS1$(print "\033[31;1m$POLYGLOT_NP")
  PS1=$PS1'$(_polyglot_exit_status $?)'
  PS1=$PS1$(print "$POLYGLOT_NP\033[0m$POLYGLOT_NP")
  PS1=$PS1'$(_polyglot_venv)'
  if ! _polyglot_is_superuser; then
    PS1=$PS1$(print "$POLYGLOT_NP\033[32;1m$POLYGLOT_NP")
  else
    PS1=$PS1$(print "$POLYGLOT_NP\033[7m$POLYGLOT_NP")
  fi
  PS1=$PS1'${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
  PS1=$PS1$(print "$POLYGLOT_NP\033[0m$POLYGLOT_NP")
  PS1=$PS1' '
  PS1=$PS1$(print "$POLYGLOT_NP\033[34;1m$POLYGLOT_NP")
  PS1=$PS1'$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
  PS1=$PS1$(print "$POLYGLOT_NP\033[0m\033[33m$POLYGLOT_NP")
  PS1=$PS1'$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
  PS1=$PS1$(print "$POLYGLOT_NP\033[0m$POLYGLOT_NP")
  PS1=$PS1' \$ '

elif _polyglot_is_yash || [ "${0#-}" = 'osh' ] && _polyglot_has_colors; then
  PS1='\[\e[01;31m\]$(_polyglot_exit_status $?)\[\e[0m\]'
  PS1=$PS1'$(_polyglot_venv)'
  if ! _polyglot_is_superuser; then
    PS1=$PS1'\[\e[01;32m\]${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\[\e[0m\] '
  else
    PS1=$PS1'\[\e[7m\]${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\[\e[0m\] '
  fi
  PS1=$PS1'\[\e[01;34m\]$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\[\e[0m\]'
  PS1=$PS1'\[\e[33m\]$(_polyglot_branch_status $POLYGLOT_KSH_BANG)\[\e[0m\] \$ '
else
  PS1='$(_polyglot_exit_status $?)$(_polyglot_venv)${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) '
  if ! _polyglot_is_superuser; then
    PS1=$PS1'$ '
  else
    PS1=$PS1'# '
  fi
fi
