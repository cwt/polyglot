if _polyglot_is_ssh || _polyglot_is_superuser; then
  POLYGLOT_HOSTNAME_STRING=$(hostname)
  POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%%\.*}"
else
  POLYGLOT_HOSTNAME_STRING=''
fi

if [ "${0#-}" = 'bash' ] || [ "${0#-}" = 'sh' ]; then
  POLYGLOT_KSH_BANG=''
else
  case $KSH_VERSION in
    *MIRBSD*) POLYGLOT_KSH_BANG='' ;;
    *) POLYGLOT_KSH_BANG='ksh' ;;
  esac
fi

case $KSH_VERSION in
  *MIRBSD*)
    # To know how long the prompt is, and thus to know how far it is to the
    # edge of the screen, mksh requires an otherwise unused character (in this
    # case \001) followed by a carriage return at the beginning of the
    # prompt, which is then used to mark off escape sequences as zero-length.
    # See https://www.mirbsd.org/htman/i386/man1/mksh.htm
    if ! _polyglot_is_superuser; then
      if _polyglot_has_colors; then
        PS1=$(print "\001\r\001\E[31;1m\001")
        PS1+='$(_polyglot_exit_status $?)'
        PS1+=$(print "\001\E[0m")
        PS1+='$(_polyglot_venv)'
        PS1+=$(print "\E[32;1m\001")
        PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
        PS1+=$(print "\001\E[0m\001")
        PS1+=' '
        PS1+=$(print "\001\E[34;1m\001")
        PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
        PS1+=$(print "\001\E[0m\E[33m\001")
        PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
        PS1+=$(print "\001\E[0m\001")
        PS1+=' \$ '
      else
        PS1='$(_polyglot_exit_status $?)'
        PS1+='$(_polyglot_venv)'
        PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING '
        PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
        PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
        PS1+=' \$ '
      fi
    else # Superuser
      if _polyglot_has_colors; then
        PS1=$(print "\001\r\001\E[31;1m\001")
        PS1+='$(_polyglot_exit_status $?)'
        PS1+=$(print "\001\E[0m")
        PS1+='$(_polyglot_venv)'
        PS1+=$(print "\E[7m\001")
        PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
        PS1+=$(print "\001\E[0m\001")
        PS1+=' '
        PS1+=$(print "\001\E[34;1m\001")
        PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
        PS1+=$(print "\001\E[0m\E[33m\001")
        PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
        PS1+=$(print "\001\E[0m\001")
        PS1+=' # '
      else
        PS1=$(print "\001\r")
        PS1+='$(_polyglot_exit_status $?)'
        PS1+='$(_polyglot_venv)'
        PS1+=$(print "\001\E[7m\001")
        PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
        PS1+=$(print "\001\E[0m\001")
        PS1+=' '
        PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
        PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
        PS1+=' # '
      fi
    fi
    ;;
  *)
    if ! _polyglot_is_superuser; then
      # zsh emulating other shells doesn't handle colors well
      if _polyglot_has_colors && [ -z "$ZSH_VERSION" ]; then
        # FreeBSD sh chokes on ANSI C quoting, so I'll avoid it
        PS1="$(print '\E[31;1m$(_polyglot_exit_status $?)\E[0m$(_polyglot_venv)\E[32;1m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m\E[33m$(_polyglot_branch_status $POLYGLOT_KSH_BANG)\E[0m \$ ')"
      else
        PS1='$(_polyglot_exit_status $?)$(_polyglot_venv)${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) \$ '
      fi
    else  # Superuser
      if _polyglot_has_colors && [ -z "$ZSH_VERSION" ]; then
        PS1="$(print '\E[31;1m$(_polyglot_exit_status $?)\E[0m$(_polyglot_venv)\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m\E[33m$(_polyglot_branch_status $POLYGLOT_KSH_BANG)\E[0m\E[0m # ')"
      else
        PS1="$(print '$(_polyglot_exit_status $?)$(_polyglot_venv)\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) # ')"
      fi
    fi
    ;;
esac
