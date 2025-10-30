#!/usr/bin/env zsh
# corpus_ui.sh - User Interface and Feedback System

# -----------------------
# Color and Style Configuration
# -----------------------
corpus_ui_init() {
    # Color codes
    if [[ "${CORPUS_FEEDBACK_STYLE}" == "pathological" ]]; then
        readonly UI_RED='\033[31m'
        readonly UI_GREEN='\033[32m'
        readonly UI_YELLOW='\033[33m'
        readonly UI_BLUE='\033[34m'
        readonly UI_MAGENTA='\033[35m'
        readonly UI_CYAN='\033[36m'
        readonly UI_WHITE='\033[37m'
        readonly UI_GRAY='\033[90m'
        readonly UI_RESET='\033[0m'
        readonly UI_BOLD='\033[1m'
        readonly UI_ITALIC='\033[3m'
    else
        # Minimal style - no colors
        readonly UI_RED=''
        readonly UI_GREEN=''
        readonly UI_YELLOW=''
        readonly UI_BLUE=''
        readonly UI_MAGENTA=''
        readonly UI_CYAN=''
        readonly UI_WHITE=''
        readonly UI_GRAY=''
        readonly UI_RESET=''
        readonly UI_BOLD=''
        readonly UI_ITALIC=''
    fi
}

# Initialize on load
corpus_ui_init

# -----------------------
# Feedback Functions
# -----------------------
corpus_success() {
    local message="$1"

    if [[ "${CORPUS_FEEDBACK_STYLE}" == "pathological" ]]; then
        echo -e "${UI_GREEN}${UI_BOLD}[Corpus]${UI_RESET} ${message}"
    else
        echo "[SUCCESS] $message"
    fi
}

corpus_info() {
    local message="$1"

    if [[ "${CORPUS_FEEDBACK_STYLE}" == "pathological" ]]; then
        echo -e "${UI_CYAN}${UI_BOLD}[Corpus]${UI_RESET} ${message}"
    else
        echo "[INFO] $message"
    fi
}

corpus_warning() {
    local message="$1"

    if [[ "${CORPUS_FEEDBACK_STYLE}" == "pathological" ]]; then
        echo -e "${UI_YELLOW}${UI_BOLD}[Corpus]${UI_RESET} ${UI_YELLOW}${message}${UI_RESET}" >&2
    else
        echo "[WARNING] $message" >&2
    fi
}

corpus_error() {
    local message="$1"

    if [[ "${CORPUS_FEEDBACK_STYLE}" == "pathological" ]]; then
        echo -e "${UI_RED}${UI_BOLD}[Corpus]${UI_RESET} ${UI_RED}${message}${UI_RESET}" >&2
    else
        echo "[ERROR] $message" >&2
    fi
}

corpus_pathological_feedback() {
    local type="$1"

    case "$type" in
        "created")
            echo -e "${UI_GREEN}The flesh takes form. A new lesion inscribed in the Corpus.${UI_RESET}"
            ;;
        "empty_shell")
            echo -e "${UI_YELLOW}A hollow shell awaits your inscription.${UI_RESET}"
            ;;
        "missing_arg")
            echo -e "${UI_RED}The blade lacks direction. Specify what shall be carved.${UI_RESET}"
            ;;
        "unknown_layer")
            echo -e "${UI_RED}No such chamber exists in this anatomy.${UI_RESET}"
            ;;
        *)
            echo -e "${UI_GRAY}The Corpus stirs...${UI_RESET}"
            ;;
    esac
}

# -----------------------
# Input Utilities
# -----------------------
corpus_prompt() {
    local prompt="$1"
    local default="${2:-}"
    local response

    if [[ -n "$default" ]]; then
        echo -ne "${UI_CYAN}${prompt} [${default}]: ${UI_RESET}"
    else
        echo -ne "${UI_CYAN}${prompt}: ${UI_RESET}"
    fi

    read response
    echo "${response:-$default}"
}

corpus_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    echo -ne "${UI_YELLOW}${prompt} [y/N]: ${UI_RESET}"
    read response

    case "${response:-$default}" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
