#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
PLATFORMS_DIR="$SCRIPT_DIR/platforms"
MANAGED_SKILLS="using-codepatrol cpatrol cpresume cpexecute cpplanreview cpplanfix cpreview cpfix cpdocs cprules"
LEGACY_SKILL_A="code""-review"
LEGACY_SKILL_B="code""-review""-fix"

usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build    Generate skills/ from templates using Claude platform values"
    echo "  claude   Generate and install skills to ~/.claude/skills/"
    echo "  codex    Generate and install skills to ~/.codex/skills/"
    echo ""
    exit 1
}

clean_installed_skills() {
    local target_dir="$1"
    mkdir -p "$target_dir"

    for skill_name in $MANAGED_SKILLS "$LEGACY_SKILL_A" "$LEGACY_SKILL_B"; do
        rm -rf "$target_dir/$skill_name"
    done
}

# Resolve {{@include:relative/path}} directives by inlining file contents
# Usage: resolve_includes <file> <base_dir>
resolve_includes() {
    local file="$1"
    local base_dir="$2"

    while grep -q '{{@include:' "$file"; do
        local include_path
        include_path=$(grep -m1 -o '{{@include:[^}]*}}' "$file" | sed 's/{{@include://;s/}}//')
        local full_path="$base_dir/$include_path"

        if [ ! -f "$full_path" ]; then
            echo "Error: include file not found: $full_path"
            exit 1
        fi

        # Use sed to replace the include line with file contents
        # The 'r' command reads a file, and 'd' deletes the matched line
        sed -i '' "/{{@include:${include_path//\//\\/}}}/{
r $full_path
d
}" "$file"
    done
}

# Substitute placeholders in a template file using values from an env file
# Usage: substitute <template_file> <env_file> <output_file>
substitute() {
    local template="$1"
    local env_file="$2"
    local output="$3"

    cp "$template" "$output"

    # Resolve includes before variable substitution
    resolve_includes "$output" "$TEMPLATES_DIR"

    # Read env file line by line and substitute each variable
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [ -z "$key" ] && continue
        [[ "$key" == \#* ]] && continue

        placeholder="{{${key}}}"

        if [ -z "$value" ]; then
            # Empty value — remove the entire line containing the placeholder
            grep -v "$placeholder" "$output" > "$output.tmp" && mv "$output.tmp" "$output"
        else
            # Escape special characters for awk
            escaped_value=$(printf '%s' "$value" | sed 's/[&/\]/\\&/g')
            awk -v ph="$placeholder" -v val="$escaped_value" '{gsub(ph, val); print}' "$output" > "$output.tmp" && mv "$output.tmp" "$output"
        fi
    done < "$env_file"
}

# Generate skills from templates for a given platform
# Usage: generate <platform>
generate() {
    local platform="$1"
    local env_file="$PLATFORMS_DIR/${platform}.env"
    local output_dir="$2"

    if [ ! -f "$env_file" ]; then
        echo "Error: platform file not found: $env_file"
        exit 1
    fi

    echo "Generating skills for $platform..."

    mkdir -p "$output_dir"

    # Process each template directory (skip _shared — it contains include-only files)
    for skill_dir in "$TEMPLATES_DIR"/*/; do
        local skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == _* ]] && continue
        local out_skill_dir="$output_dir/$skill_name"

        mkdir -p "$out_skill_dir"

        # Process each file in the skill directory
        for template_file in "$skill_dir"*.md; do
            [ -f "$template_file" ] || continue
            local filename=$(basename "$template_file")
            substitute "$template_file" "$env_file" "$out_skill_dir/$filename"
        done

        echo "  $skill_name: done"
    done

    echo "Generated to: $output_dir"
}

case "${1:-}" in
    build)
        rm -rf "$SKILLS_DIR"
        generate "claude" "$SKILLS_DIR"
        ;;
    claude)
        local_dir="$HOME/.claude/skills"
        rm -rf "$SKILLS_DIR"
        generate "claude" "$SKILLS_DIR"
        clean_installed_skills "$local_dir"
        # Copy to Claude skills directory
        for skill_dir in "$SKILLS_DIR"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        ;;
    codex)
        local_dir="$HOME/.codex/skills"
        tmp_dir=$(mktemp -d)
        generate "codex" "$tmp_dir"
        # Copy to Codex skills directory
        clean_installed_skills "$local_dir"
        for skill_dir in "$tmp_dir"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        rm -rf "$tmp_dir"
        ;;
    *)
        usage
        ;;
esac

echo "Done."
