# Interactive shell. Env lives in .zshenv. No framework.

# --- history ---
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
[[ -d $HISTFILE:h ]] || mkdir -p "$HISTFILE:h"
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE SHARE_HISTORY EXTENDED_HISTORY

# --- opts ---
setopt AUTO_CD NO_BEEP GLOB_DOTS INTERACTIVE_COMMENTS

# --- cached tool init: regenerate only when the binary is newer than the cache ---
_zcache="$XDG_CACHE_HOME/zsh"; [[ -d $_zcache ]] || mkdir -p "$_zcache"
_cached_eval() {
  local f="$_zcache/$1.zsh" bin
  bin=$(command -v "$2") || return 0
  [[ -s $f && $f -nt $bin ]] || "${@:2}" >| "$f"
  source "$f"
}

# --- completion ---
autoload -Uz compinit
_zcompdump="$_zcache/zcompdump-$ZSH_VERSION"
if [[ -n $_zcompdump(#qN.mh+24) ]]; then compinit -d "$_zcompdump"; touch "$_zcompdump"; else compinit -C -d "$_zcompdump"; fi
[[ $_zcompdump.zwc -nt $_zcompdump ]] || zcompile "$_zcompdump" 2>/dev/null
if (( $+commands[dircolors] )); then _cached_eval dircolors dircolors -b
elif (( $+commands[gdircolors] )); then _cached_eval dircolors gdircolors -b; fi

zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$_zcache/zcompcache"
zstyle ':completion:*:*:kill:*' command 'ps -u $USER -o pid,%cpu,comm'

# --- plugins (submodules). fzf-tab before widget-wrapping plugins; highlighting last ---
source "$ZDOTDIR/plugins/fzf-tab/fzf-tab.plugin.zsh"
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:(cp|mv|rm|bat|less|e|lite-xl):*' fzf-preview \
  'bat --color=always --style=numbers --line-range=:100 $realpath 2>/dev/null || eza -1 --color=always --icons=auto $realpath'

source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#888888'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_MANUAL_REBIND=1  # widgets are all bound by the first precmd; skip the per-prompt rebind
bindkey '^ ' autosuggest-accept

# --- prompt ---
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{blue}git:(%F{red}%b%F{blue})%f%m'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}git:(%F{red}%b|%a%F{blue})%f%m'
zstyle ':vcs_info:git*+set-message:*' hooks git-dirty
+vi-git-dirty() {
  [[ -n $(GIT_OPTIONAL_LOCKS=0 git status --porcelain 2>/dev/null | head -c1) ]] && hook_com[misc]=' %F{yellow}✗%f'
}
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%(?.%F{green}.%F{red})➜%f %F{cyan}%1~%f${vcs_info_msg_0_} '

# --- keys: alt+arrow / alt+f,b word motion across xterm, ghostty, macOS terminals ---
bindkey '^[[1;3C' forward-word; bindkey '^[^[[C' forward-word; bindkey '^[f' forward-word
bindkey '^[[1;3D' backward-word; bindkey '^[^[[D' backward-word; bindkey '^[b' backward-word

# --- tools (each optional; Ctrl-R/Ctrl-T/Alt-C from fzf) ---
_cached_eval fzf fzf --zsh
_cached_eval zoxide zoxide init zsh --cmd cd
_cached_eval direnv direnv hook zsh
bindkey -s '\ez' 'cdi\n'

# --- aliases ---
(( $+commands[fdfind] && ! $+commands[fd] )) && alias fd=fdfind
(( $+commands[batcat] && ! $+commands[bat] )) && alias bat=batcat
alias ls='eza --group-directories-first --icons=auto'
alias la='eza -a --icons=auto'
alias cp='cp -iv' rm='rm -iv' mkdir='mkdir -pv' df='df -h'
alias e='lite-xl'
export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT='-c'

# --- widgets ---
# proj: jump into any $DEV_DIR project (ctrl-x ctrl-p); feeds zoxide on landing
proj() {
  local dir
  dir=$(fd . "$DEV_DIR" -t d -d 2 | fzf --preview 'eza -la --icons=auto --color=always {}') || return
  cd "$dir" && zoxide add "$dir"
}
bindkey -s '^X^P' 'proj\n'

# fzf-rg: live content grep, open hit at line in $EDITOR (ctrl-x ctrl-g)
fzf-rg-widget() {
  local sel
  sel=$(rg --line-number --no-heading --color=always --smart-case '' 2>/dev/null \
    | fzf --ansi --disabled --delimiter : \
        --bind 'change:reload:rg --line-number --no-heading --color=always --smart-case {q} 2>/dev/null || true' \
        --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window '+{2}/2')
  if [[ -n $sel ]]; then
    BUFFER="$EDITOR +${${sel#*:}%%:*} ${(q)${sel%%:*}}"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N fzf-rg-widget
bindkey '^X^G' fzf-rg-widget

source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
