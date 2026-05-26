#!/usr/bin/env bash

# ==========================================================
# Premium Interactive Dotfiles Setup Script (~/dotfiles_zer0bav)
# Works on Arch Linux, Debian/Ubuntu, & macOS
# ==========================================================

# Colors (Dracula Theme Palette)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Clear screen and show premium banner
clear
echo -e "${PURPLE}${BOLD}"
echo "  ██████  ███████ ██████   ██████  ██████   █████  ██     ██"
echo " └─▄▀▀▄█ █▀▀▀▀▀  █▀▀▀▀▀█  █▀▀▀▀▀█ █▀▀▀▀▀█ █▀▀▀▀▀█ █      █ "
echo "   █▄▄▀  █████   ███████  ███████ ███████ ███████ ▀█▄  ▄█▀ "
echo "  ▄▀  █▄ █▄▄▄▄▄  █▄▄▄▄▄█  █▄▄▄▄▄█ █▄▄▄▄▄█ █▄▄▄▄▄█   █▄▄█   "
echo " └▀▀▀▀▀  ███████ ██████   ██████  ██████  ██████     ██    "
echo -e "${NC}"
echo -e "${CYAN}===================================================================${NC}"
echo -e "         Premium Keyboard-Driven workstation Installer (~/dotfiles_zer0bav) "
echo -e "                   Target: Linux / macOS / WSL                     "
echo -e "${CYAN}===================================================================${NC}"
echo ""

# OS Detection
OS="Unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/arch-release ]; then
        OS="Arch Linux"
    elif [ -f /etc/debian_version ]; then
        OS="Debian/Ubuntu"
    else
        OS="Linux"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
fi

echo -e "${BLUE}[i]${NC} Detected Operating System: ${GREEN}${BOLD}$OS${NC}"
echo ""

# Helper functions to print status
status_info() {
    echo -e "${CYAN}[*] $1${NC}"
}
status_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}
status_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}
status_error() {
    echo -e "${RED}[✘] $1${NC}"
}

# Helper to create backups and links
backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        status_warning "Backup: $dest already exists. Backing up to ${dest}.bak..."
        rm -rf "${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Create symbolic link
    ln -sf "$src" "$dest"
    status_success "Linked: $dest -> $src"
}

# 1. Ask for Target Platform Confirmation
echo -e "${BOLD}1. Confirm Installation Platform:${NC}"
echo -e "   [1] Linux (Arch Linux / Pacman)"
echo -e "   [2] Linux (Debian/Ubuntu / APT)"
echo -e "   [3] macOS (Homebrew)"
echo -e "   [4] Skip package installation (Apply configs only)"
read -p "Select platform [1-4]: " PLATFORM_CHOICE

# 2. Ask what components to install
echo ""
echo -e "${BOLD}2. Select configurations to install:${NC}"
read -p "Install Zsh Config (.zshrc, .p10k.zsh, Oh-My-Zsh & Plugins)? [Y/n]: " INSTALL_ZSH
read -p "Install Tmux Config (.tmux.conf & theme scripts)? [Y/n]: " INSTALL_TMUX
read -p "Install Neovim Config? [Y/n]: " INSTALL_NVIM
read -p "Install Kitty Config? [Y/n]: " INSTALL_KITTY
read -p "Install Fastfetch Config? [Y/n]: " INSTALL_FASTFETCH
read -p "Install Cava Config? [Y/n]: " INSTALL_CAVA
read -p "Install Lazygit Config? [Y/n]: " INSTALL_LAZYGIT
read -p "Install Opencode Config? [Y/n]: " INSTALL_OPENCODE

# Wayland/Hyprland choices (only show if not on macOS)
INSTALL_HYPR="n"
INSTALL_WAYBAR="n"
INSTALL_ROFI="n"
INSTALL_SWAYNC="n"
INSTALL_WALLUST="n"
INSTALL_WLOGOUT="n"

if [ "$PLATFORM_CHOICE" != "3" ]; then
    read -p "Install Hyprland Config? [Y/n]: " INSTALL_HYPR
    read -p "Install Waybar Config? [Y/n]: " INSTALL_WAYBAR
    read -p "Install Rofi Menu Config? [Y/n]: " INSTALL_ROFI
    read -p "Install Swaync Notification Config? [Y/n]: " INSTALL_SWAYNC
    read -p "Install Wallust Theme Config? [Y/n]: " INSTALL_WALLUST
    read -p "Install Wlogout Menu Config? [Y/n]: " INSTALL_WLOGOUT
fi

# Set defaults to Yes
INSTALL_ZSH=${INSTALL_ZSH:-Y}
INSTALL_TMUX=${INSTALL_TMUX:-Y}
INSTALL_NVIM=${INSTALL_NVIM:-Y}
INSTALL_KITTY=${INSTALL_KITTY:-Y}
INSTALL_FASTFETCH=${INSTALL_FASTFETCH:-Y}
INSTALL_CAVA=${INSTALL_CAVA:-Y}
INSTALL_LAZYGIT=${INSTALL_LAZYGIT:-Y}
INSTALL_OPENCODE=${INSTALL_OPENCODE:-Y}
INSTALL_HYPR=${INSTALL_HYPR:-Y}
INSTALL_WAYBAR=${INSTALL_WAYBAR:-Y}
INSTALL_ROFI=${INSTALL_ROFI:-Y}
INSTALL_SWAYNC=${INSTALL_SWAYNC:-Y}
INSTALL_WALLUST=${INSTALL_WALLUST:-Y}
INSTALL_WLOGOUT=${INSTALL_WLOGOUT:-Y}

# 3. Package Installation
echo ""
echo -e "${CYAN}===================================================================${NC}"
echo -e "                  Starting Package Installation                    "
echo -e "${CYAN}===================================================================${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_dependencies() {
    case $PLATFORM_CHOICE in
        1)
            status_info "Installing dependencies on Arch Linux via pacman..."
            sudo pacman -Syu --needed git curl tmux zsh neovim kitty fastfetch stow lazygit cava lsd fzf || status_error "Arch package install failed."
            if [[ "$INSTALL_HYPR" =~ ^[Yy]$ || "$INSTALL_WAYBAR" =~ ^[Yy]$ ]]; then
                sudo pacman -S --needed hyprland waybar swaync wlogout rofi wallust || status_warning "Desktop packages install failed."
            fi
            ;;
        2)
            status_info "Installing dependencies on Debian/Ubuntu via apt..."
            sudo apt update
            sudo apt install -y git curl tmux zsh neovim kitty fastfetch stow lazygit cava lsd fzf || status_error "Debian package install failed."
            ;;
        3)
            status_info "Installing dependencies on macOS via Homebrew..."
            if ! command -v brew &>/dev/null; then
                status_warning "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [ -f /opt/homebrew/bin/brew ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [ -f /usr/local/bin/brew ]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            brew install git curl tmux zsh neovim kitty fastfetch stow lazygit cava lsd fzf || status_error "Homebrew package install failed."
            ;;
        *)
            status_info "Skipping package installation."
            ;;
    esac
}

install_dependencies

# 4. Configuration Deployment
echo ""
echo -e "${CYAN}===================================================================${NC}"
echo -e "                 Deploying Configuration Files                     "
echo -e "${CYAN}===================================================================${NC}"

# ZSH Deployment
if [[ "$INSTALL_ZSH" =~ ^[Yy]$ ]]; then
    status_info "Installing Zsh Configurations..."
    
    # Install Oh My Zsh if not installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        status_info "Oh My Zsh not found. Installing..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install Powerlevel10k theme if not installed
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$P10K_DIR" ]; then
        status_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    fi

    # Install plugin: zsh-autosuggestions
    AUTOSUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$AUTOSUG_DIR" ]; then
        status_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG_DIR"
    fi

    # Install plugin: zsh-syntax-highlighting
    HIGHLIGHT_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ ! -d "$HIGHLIGHT_DIR" ]; then
        status_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HIGHLIGHT_DIR"
    fi

    backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# TMUX Deployment
if [[ "$INSTALL_TMUX" =~ ^[Yy]$ ]]; then
    status_info "Installing Tmux Configurations..."
    backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    backup_and_link "$DOTFILES_DIR/tmux/.tmux" "$HOME/.tmux"
    
    # Reload tmux config if inside tmux
    if [ -n "$TMUX" ]; then
        tmux source-file "$HOME/.tmux.conf"
    fi
fi

# NEOVIM Deployment
if [[ "$INSTALL_NVIM" =~ ^[Yy]$ ]]; then
    status_info "Installing Neovim Configurations..."
    backup_and_link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# KITTY Deployment
if [[ "$INSTALL_KITTY" =~ ^[Yy]$ ]]; then
    status_info "Installing Kitty Configurations..."
    backup_and_link "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
fi

# FASTFETCH Deployment
if [[ "$INSTALL_FASTFETCH" =~ ^[Yy]$ ]]; then
    status_info "Installing Fastfetch Configurations..."
    backup_and_link "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
fi

# CAVA Deployment
if [[ "$INSTALL_CAVA" =~ ^[Yy]$ ]]; then
    status_info "Installing Cava Configurations..."
    backup_and_link "$DOTFILES_DIR/cava" "$HOME/.config/cava"
fi

# LAZYGIT Deployment
if [[ "$INSTALL_LAZYGIT" =~ ^[Yy]$ ]]; then
    status_info "Installing Lazygit Configurations..."
    backup_and_link "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"
fi

# OPENCODE Deployment
if [[ "$INSTALL_OPENCODE" =~ ^[Yy]$ ]]; then
    status_info "Installing Opencode Configurations..."
    backup_and_link "$DOTFILES_DIR/opencode" "$HOME/.config/opencode"
fi

# HYPRLAND Deployment
if [[ "$INSTALL_HYPR" =~ ^[Yy]$ ]]; then
    status_info "Installing Hyprland Configurations..."
    backup_and_link "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
fi

# WAYBAR Deployment
if [[ "$INSTALL_WAYBAR" =~ ^[Yy]$ ]]; then
    status_info "Installing Waybar Configurations..."
    backup_and_link "$DOTFILES_DIR/waybar" "$HOME/.config/waybar"
fi

# ROFI Deployment
if [[ "$INSTALL_ROFI" =~ ^[Yy]$ ]]; then
    status_info "Installing Rofi Configurations..."
    backup_and_link "$DOTFILES_DIR/rofi" "$HOME/.config/rofi"
fi

# SWAYNC Deployment
if [[ "$INSTALL_SWAYNC" =~ ^[Yy]$ ]]; then
    status_info "Installing Swaync Configurations..."
    backup_and_link "$DOTFILES_DIR/swaync" "$HOME/.config/swaync"
fi

# WALLUST Deployment
if [[ "$INSTALL_WALLUST" =~ ^[Yy]$ ]]; then
    status_info "Installing Wallust Configurations..."
    backup_and_link "$DOTFILES_DIR/wallust" "$HOME/.config/wallust"
fi

# WLOGOUT Deployment
if [[ "$INSTALL_WLOGOUT" =~ ^[Yy]$ ]]; then
    status_info "Installing Wlogout Configurations..."
    backup_and_link "$DOTFILES_DIR/wlogout" "$HOME/.config/wlogout"
fi

echo ""
echo -e "${CYAN}===================================================================${NC}"
echo -e "             Setup Completed Successfully!                         "
echo -e "${CYAN}===================================================================${NC}"
echo -e "${GREEN}Restart your terminal or run 'source ~/.zshrc' to apply changes.${NC}"
echo ""
