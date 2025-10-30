#!/usr/bin/env zsh
# create.sh - Creation Commands (Modern implementation)

# -----------------------
# Main Create Function
# -----------------------
corpus_create() {
    corpus_trace_function
    
    # Parse arguments properly
    local layer="$1"
    local content="$2"
    shift 2 2>/dev/null || { 
        # Handle case where there are fewer than 2 arguments
        [[ $# -gt 0 ]] && shift
        true
    }
    
    # Process remaining options
    corpus_parse_options "$@"
    
    # Validate input
    if [[ -z "$layer" ]]; then
        corpus_error "Layer must be specified"
        echo >&2
        corpus_list_layers
        return 1
    fi
    
    # Validate and normalize layer
    if ! corpus_layer_exists "$layer"; then
        corpus_error "Unknown layer: $layer"
        echo >&2
        
        # Provide suggestions if partial match
        local suggestions
        suggestions=($(corpus_get_layer_suggestions "$layer"))
        if [[ ${#suggestions[@]} -gt 0 ]]; then
            echo "Did you mean:" >&2
            printf '  %s\n' "${suggestions[@]}" >&2
            echo >&2
        fi
        
        corpus_list_layers
        return 1
    fi
    
    local normalized_layer="$(corpus_normalize_layer "$layer")"
    
    # Check content requirement
    if corpus_layer_requires_arg "$normalized_layer"; then
        if [[ -z "$content" ]]; then
            corpus_error "Layer '$layer' requires content argument"
            echo >&2
            echo "Usage: corpus create $layer \"your content here\"" >&2
            return 1
        fi
    fi
    
    # Get target directory
    local layer_path="$(corpus_get_layer_path "$normalized_layer")"
    local target_dir="$CORPUS_DIR/$layer_path"
    
    corpus_debug "Target directory: $target_dir"
    
    # Ensure target directory exists
    if ! corpus_ensure_directory "$target_dir"; then
        return 1
    fi
    
    # Handle special creation types
    case "$normalized_layer" in
        "rel")
            if corpus_is_citation "$content"; then
                corpus_create_reliquia_citation "$normalized_layer" "$content" "$target_dir"
                return $?
            fi
            ;;
    esac
    
    # Standard creation flow
    corpus_create_standard_entry "$normalized_layer" "$content" "$target_dir"
}

# -----------------------
# Standard Entry Creation
# -----------------------
corpus_create_standard_entry() {
    local layer="$1"
    local content="$2"
    local target_dir="$3"
    
    corpus_debug "Creating standard entry: layer=$layer, content=$content"
    
    # Generate filename
    local filename="$(corpus_generate_filename "$layer" "$content")"
    local file_path="$target_dir/$filename"
    
    # Select template
    local template_file="$CORPUS_DIR/_template/tp_${layer}.md"
    
    if [[ ! -f "$template_file" ]]; then
        corpus_error "Template not found: $template_file"
        return 1
    fi
    
    # Determine metadata
    local entry_status="${ARG_status:-${CORPUS_DEFAULT_STATUS:-probe}}"
    local layer_path="$(corpus_get_layer_path "$layer")"
    
    # Create entry
    if ! corpus_expand_template "$template_file" "$file_path" \
        "layer" "$layer_path" \
        "status" "$entry_status" \
        "title" "$content"; then
        return 1
    fi
    
    corpus_success "Created $layer entry: $filename"
    
    # Open in editor unless disabled
    if [[ "${ARG_no_edit:-}" != "true" ]]; then
        corpus_open_editor "$file_path" "${ARG_editor:-}"
    fi
    
    return 0
}

# -----------------------
# Citation Entry Creation
# -----------------------
corpus_create_reliquia_citation() {
    local layer="$1"
    local citation_input="$2"
    local target_dir="$3"
    
    local citation_key="$(corpus_extract_citation_key "$citation_input")"
    corpus_debug "Processing citation: $citation_key"
    
    # Try BibTeX extraction
    local bibtex_script="$CORPUS_DIR/_scripts/parse_bibtex.py"
    local zotero_bib="${ZOTERO_BIB_FILE:-}"
    
    if [[ -f "$bibtex_script" && -f "$zotero_bib" ]]; then
        corpus_create_reliquia_with_bibtex "$layer" "$citation_key" "$target_dir" "$bibtex_script" "$zotero_bib"
        return $?
    else
        corpus_debug "BibTeX processing unavailable, using fallback"
        corpus_create_reliquia_fallback "$layer" "$citation_key" "$target_dir"
        return $?
    fi
}

corpus_create_reliquia_with_bibtex() {
    local layer="$1"
    local citation_key="$2"
    local target_dir="$3"
    local bibtex_script="$4"
    local zotero_bib="$5"
    
    local metadata
    if metadata="$(python3 "$bibtex_script" "$zotero_bib" "$citation_key" 2>/dev/null)"; then
        corpus_debug "BibTeX metadata extracted successfully"
        
        # Parse metadata into local variables
        local title="" author="" year="" journal="" doi=""
        
        while IFS='=' read -r key value; do
            case "$key" in
                "title") title="$value" ;;
                "author") author="$value" ;;
                "year") year="$value" ;;
                "journal") journal="$value" ;;
                "doi") doi="$value" ;;
            esac
        done <<< "$metadata"
        
        # Generate filename and create file
        local filename="$(corpus_generate_filename "$layer" "$citation_key")"
        local file_path="$target_dir/$filename"
        local template_file="$CORPUS_DIR/_template/tp_rel_paper.md"
        
        if ! corpus_expand_template "$template_file" "$file_path" \
            "layer" "$(corpus_get_layer_path "$layer")" \
            "status" "${ARG_status:-${CORPUS_DEFAULT_STATUS:-probe}}" \
            "citation_key" "@$citation_key" \
            "title" "$title" \
            "author" "$author" \
            "year" "$year" \
            "journal" "$journal" \
            "doi" "$doi"; then
            return 1
        fi
        
        corpus_success "Created reliquia paper with metadata: $filename"
        
        if [[ "${ARG_no_edit:-}" != "true" ]]; then
            corpus_open_editor "$file_path" "${ARG_editor:-}"
        fi
        
        return 0
    else
        corpus_warning "Failed to extract BibTeX metadata for: $citation_key"
        corpus_create_reliquia_fallback "$layer" "$citation_key" "$target_dir"
        return $?
    fi
}

corpus_create_reliquia_fallback() {
    local layer="$1"
    local citation_key="$2"
    local target_dir="$3"
    
    local filename="$(corpus_generate_filename "$layer" "$citation_key")"
    local file_path="$target_dir/$filename"
    local template_file="$CORPUS_DIR/_template/tp_rel_paper.md"
    
    if ! corpus_expand_template "$template_file" "$file_path" \
        "layer" "$(corpus_get_layer_path "$layer")" \
        "status" "${ARG_status:-${CORPUS_DEFAULT_STATUS:-probe}}" \
        "citation_key" "@$citation_key" \
        "title" "" \
        "author" "" \
        "year" "" \
        "journal" "" \
        "doi" ""; then
        return 1
    fi
    
    corpus_success "Created reliquia paper entry: $filename"
    
    if [[ "${ARG_no_edit:-}" != "true" ]]; then
        corpus_open_editor "$file_path" "${ARG_editor:-}"
    fi
    
    return 0
}

# -----------------------  
# File System Utilities (Enhanced)
# -----------------------
corpus_ensure_directory() {
    local dir="$1"
    
    if [[ -z "$dir" ]]; then
        corpus_error "Directory path cannot be empty"
        return 1
    fi
    
    # Check if it's within CORPUS_DIR for safety
    local abs_dir="$(realpath "$dir" 2>/dev/null || echo "$dir")"
    local abs_corpus="$(realpath "$CORPUS_DIR" 2>/dev/null || echo "$CORPUS_DIR")"
    
    if [[ "$abs_dir" != "$abs_corpus"* ]]; then
        corpus_error "Directory outside Corpus: $dir"
        return 1
    fi
    
    if [[ ! -d "$dir" ]]; then
        corpus_debug "Creating directory: $dir"
        if ! mkdir -p "$dir"; then
            corpus_error "Cannot create directory: $dir"
            return 1
        fi
    fi
    
    return 0
}

# Add alias for backward compatibility
corpus_ensure_dir() {
    corpus_ensure_directory "$@"
}

