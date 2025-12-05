#!/usr/bin/env bash
#
# Parse a YAML theme file and export colors as environment variables
# Usage: source parse-theme.sh <theme-file>
#
# This script parses YAML without external dependencies using grep/sed/awk

set -euo pipefail

THEME_FILE="${1:-}"

if [[ ! -f "${THEME_FILE}" ]]; then
  echo "Error: Theme file not found: ${THEME_FILE}" >&2
  return 1 2>/dev/null || exit 1
fi

# Function to convert hex to RGB components
hex_to_rgb() {
  local hex="${1#\#}"  # Remove # if present
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "$r $g $b"
}

# Parse scheme name
export SCHEME=$(grep '^scheme:' "${THEME_FILE}" | sed 's/^scheme: *//; s/"//g')

# First, parse base colors (base00-base0F)
while IFS=': ' read -r key value; do
  # Clean up the value
  value="${value%%#*}"      # Remove comments
  value="${value//\"/}"      # Remove quotes
  value="${value// /}"       # Remove spaces
  value="${value//\#/}"      # Remove # if present

  if [[ -n "${value}" ]]; then
    # Export uppercase variable name
    var_name=$(echo "${key}" | tr '[:lower:]' '[:upper:]')
    export "${var_name}"="${value}"

    # Also export RGB components for rgba() usage
    if [[ "${value}" =~ ^[0-9a-fA-F]{6}$ ]]; then
      rgb=($(hex_to_rgb "${value}"))
      export "${var_name}_R"="${rgb[0]}"
      export "${var_name}_G"="${rgb[1]}"
      export "${var_name}_B"="${rgb[2]}"
    fi
  fi
done < <(grep -E '^base[0-9A-Fa-f]{2}: ' "${THEME_FILE}")

# Create a mapping of base color values for reference resolution
declare -A BASE_COLORS
for base in BASE00 BASE01 BASE02 BASE03 BASE04 BASE05 BASE06 BASE07 \
           BASE08 BASE09 BASE0A BASE0B BASE0C BASE0D BASE0E BASE0F; do
  if [[ -n "${!base:-}" ]]; then
    BASE_COLORS["${base,,}"]="${!base}"
  fi
done

# Parse semantic mappings
in_semantic=false
while IFS= read -r line; do
  # Check if we're entering the semantic section
  if [[ "${line}" =~ ^semantic: ]]; then
    in_semantic=true
    continue
  fi

  # If we're in semantic section and line starts without spaces, we've left it
  if [[ "${in_semantic}" == true ]] && [[ "${line}" =~ ^[^[:space:]] ]]; then
    break
  fi

  # Process semantic color definitions
  if [[ "${in_semantic}" == true ]] && [[ "${line}" =~ ^[[:space:]]+([a-z0-9_]+):[[:space:]]*(.*) ]]; then
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    # Clean up the value
    value="${value%%#*}"      # Remove comments
    value="${value//\"/}"      # Remove quotes
    value="${value// /}"       # Remove spaces

    if [[ -n "${value}" ]]; then
      var_name=$(echo "${key}" | tr '[:lower:]' '[:upper:]')

      # Check if value is a reference to a base color
      if [[ "${value}" =~ ^base[0-9A-Fa-f]{2}$ ]]; then
        # Resolve the reference
        ref_lower="${value,,}"
        if [[ -n "${BASE_COLORS[${ref_lower}]:-}" ]]; then
          resolved_value="${BASE_COLORS[${ref_lower}]}"
          export "${var_name}"="${resolved_value}"

          # Export RGB components if it's a valid hex color
          if [[ "${resolved_value}" =~ ^[0-9a-fA-F]{6}$ ]]; then
            rgb=($(hex_to_rgb "${resolved_value}"))
            export "${var_name}_R"="${rgb[0]}"
            export "${var_name}_G"="${rgb[1]}"
            export "${var_name}_B"="${rgb[2]}"
          fi
        fi
      else
        # Direct color value
        export "${var_name}"="${value}"

        # Export RGB components if it's a valid hex color
        if [[ "${value}" =~ ^[0-9a-fA-F]{6}$ ]]; then
          rgb=($(hex_to_rgb "${value}"))
          export "${var_name}_R"="${rgb[0]}"
          export "${var_name}_G"="${rgb[1]}"
          export "${var_name}_B"="${rgb[2]}"
        fi
      fi
    fi
  fi
done < "${THEME_FILE}"

# Handle special cases where semantic colors aren't defined
# If a semantic color is not defined, try to use a sensible base default
declare -A DEFAULTS=(
  [BACKGROUND]="${BASE00}"
  [FOREGROUND]="${BASE05}"
  [FOREGROUND_BRIGHT]="${BASE06}"
  [MODULE_BG]="${BASE00}"
  [WAYBAR_BG]="transparent"
  [WAYBAR_FG]="${BASE05}"
)

for key in "${!DEFAULTS[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    export "${key}"="${DEFAULTS[${key}]}"
    # Export RGB if needed
    if [[ "${DEFAULTS[${key}]}" =~ ^[0-9a-fA-F]{6}$ ]]; then
      rgb=($(hex_to_rgb "${DEFAULTS[${key}]}"))
      export "${key}_R"="${rgb[0]}"
      export "${key}_G"="${rgb[1]}"
      export "${key}_B"="${rgb[2]}"
    fi
  fi
done

# Debug output (commented out for production)
# echo "Parsed theme: ${SCHEME}"
# echo "Base colors loaded: $(env | grep -c '^BASE[0-9A-F]*=' || true)"
# echo "Semantic colors loaded: $(env | grep -c '^[A-Z_]*=' || true)"