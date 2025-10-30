#!/usr/bin/env zsh
# corpus_core.sh - Core Library (Fixed Version)

# -----------------------
# Core Initialization
# -----------------------
corpus_init() {
    # Environment validation
    if [[ -z "$CORPUS_DIR" ]]; then
        echo "Error: CORPUS_DIR environment variable not set" >&2
        exit 1
    fi
    
    if [[ ! -d "$CORPUS_DIR" ]]; then
        echo "Error: Corpus directory does not exist: $CORPUS_DIR" >&2
        exit 1
    fi
    
    # Load configuration
    corpus_load_config
    
    # Load other libraries with proper path resolution
    local lib_dir
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        lib_dir="$(dirname "${BASH_SOURCE[0]}")"
    elif [[ -n "${(%):-%x}" ]]; then
        lib_dir="$(dirname "${(%):-%x}")"  # zsh equivalent
    else
        lib_dir="$CORPUS_DIR/_lib"
    fi
    
    # Load libraries with better error handling
    source "$lib_dir/corpus_ui.sh" || {
        echo "Error: Cannot load UI library from $lib_dir/corpus_ui.sh" >&2
        exit 1
    }
    source "$lib_dir/corpus_layers.sh" || {
        echo "Error: Cannot load layers library from $lib_dir/corpus_layers.sh" >&2
        exit 1
    }
    source "$lib_dir/corpus_utils.sh" || {
        echo "Error: Cannot load utils library from $lib_dir/corpus_utils.sh" >&2
        exit 1
    }
}

# -----------------------
# Configuration Management
# -----------------------
corpus_load_config() {
    # Hardcoded configuration to avoid zsh variable conflicts
    CORPUS_CONFIG_FILE="$CORPUS_DIR/_config/corpus.conf"
    
    # Set defaults directly
    export CORPUS_FEEDBACK_STYLE="pathological"
    export CORPUS_LANGUAGE="mixed"  
    export CORPUS_DEFAULT_STATUS="probe"
    export CORPUS_AUTO_TIMESTAMP="true"
    export CORPUS_DEFAULT_EDITOR="code"
    
    # Create config file if it doesn't exist (but don't parse it for now)
    if [[ ! -f "$CORPUS_CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CORPUS_CONFIG_FILE")"
        cat > "$CORPUS_CONFIG_FILE" << 'EOF'
# Corpus Configuration File
feedback:
  style: pathological
  language: mixed

defaults:
  editor: code
  status: probe
  auto_timestamp: true
EOF
    fi
}

corpus_create_default_config() {
    local config_dir="$CORPUS_DIR/_config"
    mkdir -p "$config_dir"
    
    cat > "$CORPUS_CONFIG_FILE" << 'EOF'
# Corpus Configuration File
feedback:
  style: pathological
  language: mixed

defaults:
  editor: code
  status: probe
  auto_timestamp: true

layers:
  enabled: all
EOF
}

# -----------------------
# Core Commands  
# -----------------------
corpus_navigate() {
    builtin cd "$CORPUS_DIR"
    echo -e "\033[32m\033[1m[Corpus]\033[0m Navigated to Corpus directory"
}

corpus_version() {
    echo "Corpus Knowledge Management System"
    echo "Version: 2.0.0-beta (Refactored)"
    echo "Path: $CORPUS_DIR"
}

corpus_help() {
    cat << 'EOF'
Corpus - Pathological Knowledge Management System

USAGE:
    corpus <command> [arguments] [options]

COMMANDS:
    create <layer> [content]    Create a new entry in the specified layer
    nav, cd                     Navigate to Corpus directory
    layers, list                List all available layers
    help [command]              Show help information
    version                     Show version information

OPTIONS:
    --status=<status>           Set entry status (probe, draft, evergreen, canon)
    --editor=<editor>           Override default editor
    --no-edit                   Don't open editor after creation
    --type=<type>               Special type (e.g., paper for reliquia)

EXAMPLES:
    corpus create frag "new idea about consciousness"
    corpus create rel @smith2024 --type=paper
    corpus create inc --status=draft --no-edit
    corpus nav

EOF
}
