# Custom arrow theme - deep dark red
# Color: 124 (deep dark red)

NCOLOR="white"

# Nerd Font icons
ICON_GIT=$'\uf418'      #
ICON_PYTHON=$'\ue73c'   #
ICON_NODE=$'\ue718'     #
ICON_TIMER=$'\uf520'    #
ICON_UP=$'\uf062'       #
ICON_DOWN=$'\uf063'     #
ICON_STASH=$'\uf48e'    #

# Command duration tracking
_CMD_START_TIME=""

function preexec() {
  _CMD_START_TIME=$EPOCHREALTIME
}

function precmd() {
  if [[ -n "$_CMD_START_TIME" ]]; then
    local end=$EPOCHREALTIME
    local duration=$(( end - _CMD_START_TIME ))
    _CMD_DURATION=$(printf "%.0f" $duration)
    _CMD_START_TIME=""
  else
    _CMD_DURATION=0
  fi
}

# Show command duration (only if > 3 seconds)
function cmd_duration() {
  if [[ $_CMD_DURATION -gt 3 ]]; then
    local mins=$(( _CMD_DURATION / 60 ))
    local secs=$(( _CMD_DURATION % 60 ))
    if [[ $mins -gt 0 ]]; then
      echo " %F{yellow}${ICON_TIMER} ${mins}m${secs}s%f"
    else
      echo " %F{yellow}${ICON_TIMER} ${secs}s%f"
    fi
  fi
}

# Root indicator
local root_indicator=""
if [ $UID -eq 0 ]; then
  root_indicator="%F{196}[root] %f"
fi

# Python version from pyproject.toml (uv/poetry) or .python-version
function python_info() {
  if [[ -f "pyproject.toml" ]]; then
    # Try requires-python from pyproject.toml (e.g., ">=3.11" -> "3.11")
    local py_version=$(grep -E '^requires-python' pyproject.toml 2>/dev/null | sed -E 's/.*[">= ]+([0-9]+\.[0-9]+).*/\1/')
    # Fallback: check .python-version file (used by uv/pyenv)
    if [[ -z "$py_version" ]] && [[ -f ".python-version" ]]; then
      py_version=$(cat .python-version | head -1)
    fi
    if [[ -n "$py_version" ]]; then
      echo " %F{214}${ICON_PYTHON} ${py_version}%f"
    fi
  fi
}

# Node version (only if package.json exists)
function node_info() {
  if [[ -f "package.json" ]]; then
    local node_version=$(node --version 2>/dev/null)
    if [[ -n "$node_version" ]]; then
      echo " %F{077}${ICON_NODE} ${node_version}%f"
    fi
  fi
}

# Git info with better formatting
function git_info() {
  local ref=$(git symbolic-ref HEAD 2>/dev/null | cut -d'/' -f3-)
  if [[ -n "$ref" ]]; then
    local info=""

    # Dirty indicator
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      info+="%F{208}*%f"
    fi

    # Ahead/behind remote
    local ahead_behind=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [[ -n "$ahead_behind" ]]; then
      local ahead=$(echo $ahead_behind | awk '{print $1}')
      local behind=$(echo $ahead_behind | awk '{print $2}')
      [[ $ahead -gt 0 ]] && info+=" %F{green}${ICON_UP}${ahead}%f"
      [[ $behind -gt 0 ]] && info+=" %F{red}${ICON_DOWN}${behind}%f"
    fi

    # Stash count
    local stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    [[ $stash_count -gt 0 ]] && info+=" %F{cyan}${ICON_STASH}${stash_count}%f"

    echo " %F{$NCOLOR}${ICON_GIT} ${ref}%f${info}"
  fi
}

# Last command exit code (only show if non-zero)
function exit_code() {
  local code=$?
  if [[ $code -ne 0 ]]; then
    echo "%F{196}[$code] %f"
  fi
}

# Left prompt: [root] directory ➤
PROMPT='${root_indicator}%F{$NCOLOR}%c ❯ %f'

# Right prompt: duration | git | python | node
RPROMPT='$(cmd_duration)$(git_info)$(python_info)$(node_info)'

# Git theme settings (fallback)
ZSH_THEME_GIT_PROMPT_PREFIX="git:"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# LS Colors
export LSCOLORS="exfxcxdxbxbxbxbxbxbxbx"
export LS_COLORS="di=34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:"
