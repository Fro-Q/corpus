#!/usr/bin/env zsh
# corpus_layers.sh - Layer System (Modern zsh implementation)

# Enable extended globbing and hash tables
setopt EXTENDED_GLOB
setopt HASH_LIST_ALL

# -----------------------
# Layer Data Structure (JSON-like approach)
# -----------------------

# Layer definitions using structured approach
readonly CORPUS_LAYER_DATA='
autopsia:incisio:inc:000_autopsia/010_incisio:Observational cuts and incisions:false
autopsia:pathologia:pat:000_autopsia/020_pathologia:Diagnostic analysis of problems:false
autopsia:satura:sat:000_autopsia/030_satura:Corrective suturing and healing:false
ingesta:fragmenta:frag:100_ingesta/110_fragmenta:Thought fragments and ideas:true
ingesta:reliquia:rel:100_ingesta/120_reliquia:Academic references and remnants:true
ingesta:impressio:imp:100_ingesta/130_impressio:Sensory impressions and experiences:true
ingesta:organon:org:100_ingesta/140_organon:Tools and methodologies:true
ingesta:toxicon:tox:100_ingesta/150_toxicon:Toxic or problematic thoughts:true
neoplasma:cor:cor:200_neoplasma/210_cor:Core ontological structures:true
neoplasma:vascula:vas:200_neoplasma/220_vascula:Connections and networks:true
neoplasma:abyssus:aby:200_neoplasma/230_oblivium/231_abyssus:Abyssal depths and unknowns:true
neoplasma:nodus:nod:200_neoplasma/230_oblivium/232_nodus:Complex knots and tangles:true
neoplasma:hallucina:hal:200_neoplasma/230_oblivium/233_hallucina:Projections and illusions:true
neoplasma:fluxus:flu:200_neoplasma/230_oblivium/234_fluxus:Emotional currents and flows:true
neoplasma:fractura:fra:200_neoplasma/230_oblivium/235_fractura:Breaks and measurements:true
neoplasma:chimera:chi:200_neoplasma/230_oblivium/236_chimera:Hybrid models and constructs:true
neoplasma:eruptio:eru:200_neoplasma/240_eruptio:Sudden emergences and insights:true
putredo:miasma:mia:300_putredo/310_miasma:Daily toxins and pollutants:true
putredo:ulcus:ulc:300_putredo/320_ulcus:Project ulcerations and problems:true
putredo:exhumatio:exh:300_putredo/330_exhumatio:Archaeological excavations:true
special:delirium:del:400_delirium:Extraordinary and wondrous:true
special:vigil:vig:500_vigil:Night watches and endurance:true
'

# -----------------------
# Modern Layer Query Functions
# -----------------------
corpus_layer_exists() {
    local layer="$1"
    
    # Search through layer data
    while IFS=':' read -r category full_name alias path description requires_arg; do
        [[ -z "$category" ]] && continue
        if [[ "$full_name" == "$layer" || "$alias" == "$layer" ]]; then
            return 0
        fi
    done <<< "$CORPUS_LAYER_DATA"
    
    return 1
}

corpus_get_layer_info() {
    local layer="$1"
    local field="${2:-all}"  # all, path, description, requires_arg, alias, category
    
    while IFS=':' read -r category full_name alias path description requires_arg; do
        [[ -z "$category" ]] && continue
        
        if [[ "$full_name" == "$layer" || "$alias" == "$layer" ]]; then
            case "$field" in
                "path") echo "$path" ;;
                "description") echo "$description" ;;
                "requires_arg") echo "$requires_arg" ;;
                "alias") echo "$alias" ;;
                "full_name") echo "$full_name" ;;
                "category") echo "$category" ;;
                "all") echo "$category:$full_name:$alias:$path:$description:$requires_arg" ;;
            esac
            return 0
        fi
    done <<< "$CORPUS_LAYER_DATA"
    
    return 1
}

corpus_get_layer_path() {
    corpus_get_layer_info "$1" "path"
}

corpus_get_layer_description() {
    corpus_get_layer_info "$1" "description"
}

corpus_layer_requires_arg() {
    local requires_arg="$(corpus_get_layer_info "$1" "requires_arg")"
    [[ "$requires_arg" == "true" ]]
}

corpus_normalize_layer() {
    local layer="$1"
    local alias="$(corpus_get_layer_info "$layer" "alias")"
    
    if [[ -n "$alias" ]]; then
        echo "$alias"
        return 0
    else
        return 1
    fi
}

# -----------------------
# Display Functions
# -----------------------
corpus_list_layers() {
    echo "Available Layers:"
    echo
    
    # Group by category
    local current_category=""
    local category_titles=(
        "autopsia:Autopsia (Self-Analysis):"
        "ingesta:Ingesta (Knowledge Intake):"
        "neoplasma:Neoplasma (Growth & Proliferation):"
        "putredo:Putredo (Decay & Maintenance):"
        "special:Special:"
    )
    
    for category_line in "${category_titles[@]}"; do
        local cat_key="${category_line%%:*}"
        local cat_title="${category_line#*:}"
        
        echo "$cat_title"
        
        while IFS=':' read -r category full_name alias path description requires_arg; do
            [[ -z "$category" || "$category" != "$cat_key" ]] && continue
            
            local display_name
            if [[ "$full_name" == "$alias" ]]; then
                display_name="$alias"
            else
                display_name="$full_name, $alias"
            fi
            
            printf "  %-20s - %s\n" "$display_name" "$description"
            
        done <<< "$CORPUS_LAYER_DATA"
        
        echo
    done
}

corpus_list_layers_json() {
    echo "{"
    local first=true
    
    while IFS=':' read -r category full_name alias path description requires_arg; do
        [[ -z "$category" ]] && continue
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        printf '  "%s": {' "$alias"
        printf '"full_name": "%s", ' "$full_name"
        printf '"path": "%s", ' "$path"
        printf '"description": "%s", ' "$description"
        printf '"requires_arg": %s, ' "$requires_arg"
        printf '"category": "%s"}' "$category"
        
    done <<< "$CORPUS_LAYER_DATA"
    
    echo
    echo "}"
}

# -----------------------
# Layer Validation
# -----------------------
corpus_validate_layer() {
    local layer="$1"
    
    if ! corpus_layer_exists "$layer"; then
        corpus_error "Unknown layer: $layer"
        echo >&2
        echo "Available layers:" >&2
        corpus_list_layers >&2
        return 1
    fi
    
    return 0
}

corpus_get_layer_suggestions() {
    local partial="$1"
    local suggestions=()
    
    while IFS=':' read -r category full_name alias path description requires_arg; do
        [[ -z "$category" ]] && continue
        
        if [[ "$full_name" == "$partial"* || "$alias" == "$partial"* ]]; then
            suggestions+=("$alias")
        fi
    done <<< "$CORPUS_LAYER_DATA"
    
    printf '%s\n' "${suggestions[@]}"
}

