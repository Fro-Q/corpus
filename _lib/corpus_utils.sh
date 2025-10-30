#!/usr/bin/env zsh
# corpus_utils.sh - Utilities (Modern zsh implementation)

# -----------------------
# Argument Processing (Robust version)
# -----------------------
corpus_parse_options() {
    local args=("$@")
    
    # Clear any existing ARG_ variables
    unset ${(M)${(k)parameters}:#ARG_*} 2>/dev/null || true
    
    local positional_args=()
    local i=1
    
    while [[ $i -le ${#args[@]} ]]; do
        local arg="${args[$i]}"
        
        case "$arg" in
            --*=*)
                # Long option with value: --key=value
                local key="${arg#--}"
                key="${key%%=*}"
                local value="${arg#--*=}"
                export "ARG_${key}=${value}"
                ;;
            --*)
                # Long option flag: --flag  
                local key="${arg#--}"
                export "ARG_${key}=true"
                ;;
            -*)
                # Short options - could be enhanced later
                corpus_warning "Short options not fully implemented: $arg"
                ;;
            *)
                # Positional argument
                positional_args+=("$arg")
                ;;
        esac
        
        ((i++))
    done
    
    # Export positional arguments
    export CORPUS_POSITIONAL_ARGS=("${positional_args[@]}")
    export CORPUS_POSITIONAL_COUNT=${#positional_args[@]}
}

# -----------------------
# Safe File Operations
# -----------------------
corpus_timestamp() {
    date +%Y%m%d%H%M%S
}

corpus_date() {
    date +%Y-%m-%d  
}

corpus_safe_filename() {
    local input="$1"
    
    # Remove or replace problematic characters
    local safe="${input//[^a-zA-Z0-9\u4e00-\u9fff _-]/_}"
    safe="${safe//__*/_}"        # Replace multiple underscores
    safe="${safe#_}"             # Remove leading underscore
    safe="${safe%_}"             # Remove trailing underscore
    
    # Ensure non-empty result
    if [[ -z "$safe" ]]; then
        safe="unnamed"
    fi
    
    echo "$safe"
}

corpus_generate_filename() {
    local layer="$1"
    local content="${2:-}"
    local timestamp="$(corpus_timestamp)"
    
    if [[ -n "$content" ]]; then
        local safe_content="$(corpus_safe_filename "$content")"
        echo "${layer}_${safe_content}_${timestamp}.md"
    else
        echo "${layer}_${timestamp}.md"
    fi
}

corpus_ensure_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            corpus_error "Cannot create directory: $dir"
            return 1
        fi
        corpus_info "Created directory: $dir"
    fi
    
    return 0
}

# -----------------------
# Template Processing (Enhanced)
# -----------------------
corpus_expand_template() {
    local template_file="$1"
    local output_file="$2"
    shift 2
    
    if [[ ! -f "$template_file" ]]; then
        corpus_error "Template not found: $template_file"
        return 1
    fi
    
    if [[ ! -r "$template_file" ]]; then
        corpus_error "Cannot read template: $template_file"
        return 1
    fi
    
    local content
    content="$(<"$template_file")" || {
        corpus_error "Failed to read template content"
        return 1
    }
    
    # Process template variables in pairs
    while [[ $# -ge 2 ]]; do
        local placeholder="$1"
        local replacement="$2"
        shift 2
        
        # Replace {{placeholder}} with replacement
        content="${content//\{\{${placeholder}\}\}/${replacement}}"
    done
    
    # Set built-in template variables
    content="${content//\{\{date\}\}/$(corpus_date)}"
    content="${content//\{\{timestamp\}\}/$(corpus_timestamp)}"
    content="${content//\{\{corpus_dir\}\}/${CORPUS_DIR}}"
    
    # Write output with error checking
    if ! echo "$content" > "$output_file"; then
        corpus_error "Failed to write to: $output_file"
        return 1
    fi
    
    return 0
}

# -----------------------
# Citation Processing
# -----------------------
corpus_is_citation() {
    local input="$1"
    [[ "$input" =~ ^@[a-zA-Z0-9_-]+$ ]]
}

corpus_extract_citation_key() {
    local input="$1"
    
    if [[ "$input" =~ ^@(.+)$ ]]; then
        echo "${match[1]}"
    else
        echo "$input"
    fi
}

# -----------------------
# Editor Integration (Enhanced)
# -----------------------
corpus_open_editor() {
    local file="$1"
    local editor="${2:-${CORPUS_DEFAULT_EDITOR:-code}}"
    
    # Validate file exists
    if [[ ! -f "$file" ]]; then
        corpus_error "File does not exist: $file"
        return 1
    fi
    
    # Editor priority and fallback chain
    case "$editor" in
        code|vscode)
            if command -v code &>/dev/null; then
                code "$file"
            elif command -v cursor &>/dev/null; then
                cursor "$file"
            else
                corpus_fallback_editor "$file"
            fi
            ;;
        nvim|vim)
            if command -v "$editor" &>/dev/null; then
                "$editor" "$file"
            else
                corpus_fallback_editor "$file"
            fi
            ;;
        *)
            if command -v "$editor" &>/dev/null; then
                "$editor" "$file"
            else
                corpus_fallback_editor "$file"
            fi
            ;;
    esac
}

corpus_fallback_editor() {
    local file="$1"
    
    # Try common editors in order
    local editors=(nvim vim nano code cursor subl atom)
    
    for editor in "${editors[@]}"; do
        if command -v "$editor" &>/dev/null; then
            corpus_info "Using fallback editor: $editor"
            "$editor" "$file"
            return 0
        fi
    done
    
    # No editor found
    corpus_warning "No suitable editor found. File created at: $file"
    return 1
}

# -----------------------
# Enhanced Logging
# -----------------------
corpus_debug() {
    if [[ "${CORPUS_DEBUG:-}" == "true" ]]; then
        echo -e "\033[90m[DEBUG]\033[0m $1" >&2
    fi
}

corpus_trace_function() {
    if [[ "${CORPUS_TRACE:-}" == "true" ]]; then
        echo -e "\033[90m[TRACE] ${funcstack[2]:-unknown} -> ${funcstack[1]:-unknown}\033[0m" >&2
    fi
}

