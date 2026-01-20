setopt PROMPT_SUBST

###########################################################
# Runs right before the prompt is displayed
# Imitates bash's PROMPT_DIRTRIM behavior and calculates
# working branch and working copy status
###########################################################
_polyglot_precmd() {
  psvar[2]=$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")
  psvar[3]=$(_polyglot_branch_status)
  psvar[5]=$(_polyglot_venv)

  PS1=''
  # The ZSH vi mode indicator won't work in Emacs shell (but it does in term
  # and ansi-term)
  if [ "$TERM" != 'dumb' ]; then
    PS1+='%(4V.:.+)'
  fi
  if _polyglot_has_colors; then
    PS1+='%(?..%B%F{red}(%?%)%b%f )'
    PS1+='%5v'
    PS1+='%(!.%S.%B%F{green})%n%1v%(!.%s.%f%b) '
    PS1+='%B%F{blue}%2v%f%b'
    PS1+='%F{yellow}%3v%f %# '
  else
    PS1+='%(?..(%?%) )'
    PS1+='%5v'
    PS1+='%(!.%S.)%n%1v%(!.%s.) '
    PS1+='%2v'
    PS1+='%3v %# '
  fi
}

###########################################################
# Redraw the prompt when the vi mode changes
#
# Whn in vi mode, the prompt will use a bash 4.3-style
# mode indicator at the beginniing of the line: '+' for
# insert mode; ':' for command mode
#
# Underscores are used in this function's name to keep
# dash from choking on hyphens
###########################################################
_polyglot_zle_keymap_select() {
  [ "$KEYMAP" = 'vicmd' ] && psvar[4]='vicmd' || psvar[4]=''
  zle reset-prompt
  zle -R
}

zle -N _polyglot_zle_keymap_select
zle -A _polyglot_zle_keymap_select zle-keymap-select
zle -A _polyglot_zle_keymap_select zle-line-init

###########################################################
# Redraw prompt when terminal size changes
###########################################################
TRAPWINCH() {
  zle && zle -R
}

# TODO: add-zsh-hook was added in ZSH v4.3.4. It would be nice to be
# compatible with even earlier versions of ZSH, but that seems to require
# use of array syntax that is incompatible with ash.
autoload add-zsh-hook
add-zsh-hook precmd _polyglot_precmd

# Only display the $HOSTNAME for an ssh connection, except for a superuser
if _polyglot_is_ssh || _polyglot_is_superuser; then
  psvar[1]="@${HOST%%\.*}"
else
  psvar[1]=''
fi

unset RPROMPT               # Clean up detritus from previously loaded prompts
