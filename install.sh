#!/bin/bash
set -e

REPO_URL="https://github.com/unger1984/codepatrol.git"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Remote install: if templates/ not found locally, clone the repo to a temp dir
CLONED_DIR=""
if [ ! -d "$SCRIPT_DIR/templates" ]; then
    if ! command -v git &>/dev/null; then
        echo "Error: git is required for remote installation"
        exit 1
    fi
    CLONED_DIR=$(mktemp -d)
    echo "Cloning codepatrol..."
    git clone --depth 1 "$REPO_URL" "$CLONED_DIR" 2>/dev/null
    SCRIPT_DIR="$CLONED_DIR"
    trap 'rm -rf "$CLONED_DIR"' EXIT
fi

TEMPLATES_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
PLATFORMS_DIR="$SCRIPT_DIR/platforms"
LEGACY_SKILLS="cpatrol cpresume cpexecute cpplanreview cpplanfix cpreview cpfix cpdocs cprules cp-idea cp-plan cp-execute cp-plan-review cp-plan-fix cp-resume cp-docs cp-rules"
LEGACY_SKILL_A="code""-review"
LEGACY_SKILL_B="code""-review""-fix"

usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build    Generate skills/ from templates using Claude platform values"
    echo "  claude   Generate and install skills to ~/.claude/skills/"
    echo "  codex    Generate and install skills to ~/.codex/skills/"
    echo "  cursor   Generate and install skills to ~/.cursor/skills/"
    echo ""
    exit 1
}

clean_installed_skills() {
    local target_dir="$1"
    mkdir -p "$target_dir"

    # Clean current skills (derived from templates)
    for skill_dir in "$TEMPLATES_DIR"/*/; do
        local skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == _* ]] && continue
        rm -rf "$target_dir/$skill_name"
    done

    # Clean legacy skill names from previous versions
    for skill_name in $LEGACY_SKILLS "$LEGACY_SKILL_A" "$LEGACY_SKILL_B"; do
        rm -rf "$target_dir/$skill_name"
    done
}

# Resolve {{@platform-include:filename}} directives by inlining _shared/filename-{platform}.md
# Usage: resolve_platform_includes <file> <base_dir> <platform>
resolve_platform_includes() {
    local file="$1"
    local base_dir="$2"
    local platform="$3"

    while grep -q '{{@platform-include:' "$file"; do
        local include_name
        include_name=$(grep -m1 -o '{{@platform-include:[^}]*}}' "$file" | sed 's/{{@platform-include://;s/}}//')
        local full_path="$base_dir/_shared/${include_name}-${platform}.md"

        if [ ! -f "$full_path" ]; then
            echo "Error: platform include file not found: $full_path"
            exit 1
        fi

        # Replace the include line with file contents (portable across GNU/BSD)
        local tmp="$file.pinc.tmp"
        awk -v pattern="{{@platform-include:${include_name}}}" -v inc="$full_path" '
            $0 ~ pattern { while ((getline line < inc) > 0) print line; close(inc); next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
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

        # Replace the include line with file contents (portable across GNU/BSD)
        local tmp="$file.inc.tmp"
        awk -v pattern="{{@include:${include_path}}}" -v inc="$full_path" '
            $0 ~ pattern { while ((getline line < inc) > 0) print line; close(inc); next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
    done
}

# Substitute placeholders in a template file using values from an env file
# Usage: substitute <template_file> <env_file> <output_file> <platform>
substitute() {
    local template="$1"
    local env_file="$2"
    local output="$3"
    local platform="$4"

    cp "$template" "$output"

    # Resolve platform-specific includes first, then generic includes
    resolve_platform_includes "$output" "$TEMPLATES_DIR" "$platform"
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
            # Replace placeholder with value (awk handles literal strings via variable)
            awk -v ph="$placeholder" -v val="$value" '{
                idx = index($0, ph)
                while (idx > 0) {
                    $0 = substr($0, 1, idx-1) val substr($0, idx+length(ph))
                    idx = index($0, ph)
                }
                print
            }' "$output" > "$output.tmp" && mv "$output.tmp" "$output"
        fi
    done < <(cat "$env_file"; echo)
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
            substitute "$template_file" "$env_file" "$out_skill_dir/$filename" "$platform"
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
        local_dir="$HOME/.agents/skills"
        legacy_dir="$HOME/.codex/skills"
        tmp_dir=$(mktemp -d)
        generate "codex" "$tmp_dir"
        # Clean legacy install path (~/.codex/skills) from previous versions
        clean_installed_skills "$legacy_dir"
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
    cursor)
        local_dir="$HOME/.cursor/skills"
        tmp_dir=$(mktemp -d)
        generate "cursor" "$tmp_dir"
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
