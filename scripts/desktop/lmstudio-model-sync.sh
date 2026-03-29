#!/usr/bin/env bash
# Sync LM Studio model to Noctalia AI Assistant
# Queries the LM Studio server and updates noctalia settings if model changed

set -euo pipefail

LM_STUDIO_HOST="${LM_STUDIO_HOST:-192.168.1.7}"
LM_STUDIO_PORT="${LM_STUDIO_PORT:-1234}"
NOCTALIA_SETTINGS="${HOME}/.config/nixos/dotfiles/.config/noctalia/settings.json"
CACHE_FILE="${HOME}/.cache/lmstudio-current-model"

get_current_model() {
    local response
    response=$(curl -s --max-time 5 "http://${LM_STUDIO_HOST}:${LM_STUDIO_PORT}/v1/models" 2>/dev/null) || return 1
    
    # LM Studio returns model list - we want the first one (usually the loaded one)
    # In LM Studio, the first model in the list is typically the active one
    local model
    model=$(echo "$response" | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)
    
    if [[ -z "$model" ]]; then
        return 1
    fi
    
    echo "$model"
}

update_noctalia_model() {
    local model="$1"
    local current_model
    
    # Assistant panel is in left widgets at index 10
    current_model=$(jq -r '.bar.widgets.left[10].defaultSettings.ai.model // empty' "$NOCTALIA_SETTINGS" 2>/dev/null) || return
    
    if [[ "$model" != "$current_model" ]]; then
        echo "Updating model: $current_model -> $model"
        
        # Update the model in noctalia settings
        jq --arg model "$model" \
           '.bar.widgets.left[10].defaultSettings.ai.model = $model' \
           "$NOCTALIA_SETTINGS" > /tmp/noctalia-settings.tmp.json
        
        mv /tmp/noctalia-settings.tmp.json "$NOCTALIA_SETTINGS"
        
        echo "Model updated in settings.json"
    else
        echo "Model unchanged: $model"
    fi
}

main() {
    local model
    model=$(get_current_model) || {
        echo "Failed to get model from LM Studio at ${LM_STUDIO_HOST}:${LM_STUDIO_PORT}"
        exit 1
    }
    
    # Cache the current model
    echo "$model" > "$CACHE_FILE"
    
    update_noctalia_model "$model"
}

main "$@"