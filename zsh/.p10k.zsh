# Two-line Lined prompt for Powerlevel10k (Sleek Slanted Dark Slate Theme)
# Designed for slanted geometric pills, high contrast readability, dragon prompt, and cat logo.

() {
  emulate -L zsh

  # Keep prompt compact and focused.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(my_arch_logo dir vcs my_target_ip my_vpn my_internet_status newline prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv node_version go_version rust_version docker_context kubectl aws ssh root_indicator)
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

  # Mode
  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_ICON_PADDING=none
  
  # Set slanted/diagonal caps for the entire prompt blocks
  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
  typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # Separator trick to make each segment its own slanted pill
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '

  # Spacing
  typeset -g POWERLEVEL9K_LEFT_LEFT_WHITESPACE=
  typeset -g POWERLEVEL9K_LEFT_RIGHT_WHITESPACE=
  typeset -g POWERLEVEL9K_RIGHT_LEFT_WHITESPACE=
  typeset -g POWERLEVEL9K_RIGHT_RIGHT_WHITESPACE=

  # Horizontal connection line (Subtle Dark Slate Bullets - low profile connection)
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='•'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND='#444454'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_BACKGROUND=

  # --- UNIFIED DARK THEME COLORS ---
  local pill_bg='#1e1e24'       # Elegant obsidian/dark slate background for all pills
  
  # Highly compatible color names/indices to guarantee Zsh rendering
  local text_fg='white'
  local accent_blue='39'        # Bright cyan/blue (256-color palette)
  local accent_cyan='cyan'
  local accent_green='green'
  local accent_yellow='yellow'
  local accent_red='red'

  # --- CUSTOM SEGMENT STYLE MAPPINGS ---
  typeset -g POWERLEVEL9K_MY_ARCH_LOGO_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_MY_ARCH_LOGO_FOREGROUND="$text_fg"

  typeset -g POWERLEVEL9K_MY_TARGET_IP_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_MY_TARGET_IP_FOREGROUND="$text_fg"

  typeset -g POWERLEVEL9K_MY_VPN_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_MY_VPN_FOREGROUND="$text_fg"

  typeset -g POWERLEVEL9K_MY_INTERNET_STATUS_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_MY_INTERNET_STATUS_FOREGROUND="$text_fg"

  # --- CUSTOM SEGMENT FUNCTIONS ---
  
  # 1. OS & Cat Pill (Placed at the very beginning of the left prompt)
  prompt_my_arch_logo() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
      p10k segment -b "$pill_bg" -f "$accent_blue" -t " %F{white}macOS %F{red}󰄛"
    else
      p10k segment -b "$pill_bg" -f "$accent_blue" -t "󰣇 %F{white}Arch %F{red}󰄛"
    fi
  }

  # 2. Target IP Pill
  prompt_my_target_ip() {
    local target_file="$HOME/.tmux/target_ip"
    if [[ -f "$target_file" ]]; then
      local target=$(cat "$target_file")
      if [[ -n "$target" ]]; then
        p10k segment -b "$pill_bg" -f "$accent_yellow" -t "🎯 %F{white}$target"
      fi
    fi
  }

  # 3. VPN Pill
  prompt_my_vpn() {
    local vpn_ip=""
    local vpn_dev=""
    for dev in tun0 tun1 wg0 wg1 ppp0 utun0 utun1 utun2 utun3; do
      local ip=""
      if [[ "$OSTYPE" == "darwin"* ]]; then
        ip=$(ifconfig "$dev" 2>/dev/null | awk '/inet / {print $2}')
      else
        if command -v ip >/dev/null 2>&1; then
          ip=$(ip -4 addr show "$dev" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
        else
          ip=$(ifconfig "$dev" 2>/dev/null | awk '/inet / {print $2}')
        fi
      fi
      if [[ -n "$ip" ]]; then
        vpn_ip="$ip"
        vpn_dev="$dev"
        break
      fi
    done
    if [[ -n "$vpn_ip" ]]; then
      p10k segment -b "$pill_bg" -f "$accent_cyan" -t "󰆧 %F{white}$vpn_dev: $vpn_ip"
    fi
  }

  # 4. Internet Status Pill
  prompt_my_internet_status() {
    local has_internet=false
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if route -n get default 2>/dev/null | grep -q gateway; then
        has_internet=true
      fi
    else
      if command -v ip >/dev/null 2>&1; then
        if ip route | grep -q default; then
          has_internet=true
        fi
      elif route -n | grep -q '^0.0.0.0'; then
        has_internet=true
      fi
    fi

    if [[ "$has_internet" == "true" ]]; then
      p10k segment -b "$pill_bg" -f "$accent_green" -t " %F{white}Online"
    else
      p10k segment -b "$pill_bg" -f "$accent_red" -t " %F{white}Offline"
    fi
  }

  # --- DIRECTORY SEGMENT (DARK PILL, WHITE TEXT, CYAN ANCHORS) ---
  typeset -g POWERLEVEL9K_DIR_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_DIR_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND="$accent_cyan"
  typeset -g POWERLEVEL9K_DIR_VISUAL_IDENTIFIER_COLOR="$accent_cyan"
  typeset -g POWERLEVEL9K_DIR_ICON=''

  # --- GIT (VCS) SEGMENT (DARK PILL, WHITE TEXT, COLOR-STATUS ICONS) ---
  typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_VCS_CLEAN_VISUAL_IDENTIFIER_COLOR="$accent_green"
  
  typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_VCS_MODIFIED_VISUAL_IDENTIFIER_COLOR="$accent_yellow"
  
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_VISUAL_IDENTIFIER_COLOR="$accent_red"

  typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_VISUAL_IDENTIFIER_COLOR="$accent_red"
  
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=false
  unset POWERLEVEL9K_VCS_CONTENT_EXPANSION
  unset POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=' '

  # --- BACKGROUND JOBS (DARK PILL, WHITE TEXT, YELLOW ICON) ---
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_COLOR="$accent_yellow"
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_ICON=''

  # --- ROOT INDICATOR (DARK PILL, WHITE TEXT, RED ICON) ---
  typeset -g POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_ROOT_INDICATOR_VISUAL_IDENTIFIER_COLOR="$accent_red"

  # --- SSH STATUS (DARK PILL, WHITE TEXT, BLUE ICON) ---
  typeset -g POWERLEVEL9K_SSH_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_SSH_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_SSH_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_SSH_ICON='󰖟'

  # --- DEV LANGUAGE & TOOL SEGMENTS (DARK PILLS, WHITE TEXT, BLUE ICONS) ---
  typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_VIRTUALENV_ICON=''

  typeset -g POWERLEVEL9K_NODE_VERSION_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_NODE_VERSION_ICON=''

  typeset -g POWERLEVEL9K_GO_VERSION_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_GO_VERSION_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_GO_VERSION_ICON=''

  typeset -g POWERLEVEL9K_RUST_VERSION_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_RUST_VERSION_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_RUST_VERSION_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_RUST_VERSION_ICON=''

  typeset -g POWERLEVEL9K_DOCKER_CONTEXT_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_DOCKER_CONTEXT_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_DOCKER_CONTEXT_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_DOCKER_CONTEXT_ICON=''

  # --- RIGHT PROMPT SEGMENTS (STATUS & EXEC TIME) ---
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_COLOR="$accent_red"
  
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND="$pill_bg"
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND="$text_fg"
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_COLOR="$accent_blue"
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_ICON=''

  # --- PROMPT SYMBOL STYLE (DRAGON GLYPH) ---
  typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND="$accent_green"
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND="$accent_red"
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND="$accent_blue"
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_FOREGROUND="$accent_red"
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='🐲'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='🐲'
}

(( ! $+functions[p10k] )) || p10k reload
