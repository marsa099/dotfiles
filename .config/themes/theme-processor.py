#!/usr/bin/env python3

import json
import sys
import re
import os
from pathlib import Path

def load_colors(colors_file, theme_mode):
    """Load colors from JSON file for specified theme mode."""
    with open(colors_file, 'r') as f:
        data = json.load(f)
    return data['themes'][theme_mode]

def load_all_colors(colors_file):
    """Load all colors from JSON file."""
    with open(colors_file, 'r') as f:
        data = json.load(f)
    return data['themes']

def get_nested_color(colors, path, max_depth=5, theme_context=None):
    """Get color value from nested path with recursive reference resolution."""
    keys = path.split('.')
    value = colors
    for key in keys:
        if key in value:
            value = value[key]
        else:
            return None
    
    # If the value is a string that looks like another reference, resolve it recursively
    if isinstance(value, str) and '.' in value and max_depth > 0:
        # Check if this looks like a color reference (not a hex color)
        if not value.startswith('#'):
            # If we have a theme context and the reference doesn't include theme, prepend it
            if theme_context and not any(theme in value for theme in ['dark', 'light']):
                themed_reference = f"{theme_context}.{value}"
                resolved = get_nested_color(colors, themed_reference, max_depth - 1, theme_context)
            else:
                resolved = get_nested_color(colors, value, max_depth - 1, theme_context)
            if resolved:
                return resolved
    
    return value

def process_template(template_file, colors_file, theme_mode, output_file):
    """Process template file and replace color variables."""
    
    # Check if this is the nvim template which needs both themes
    is_nvim_template = 'nvim' in os.path.basename(template_file)
    
    if is_nvim_template:
        # Load all colors for nvim template
        all_colors = load_all_colors(colors_file)
        colors = all_colors  # Contains both 'dark' and 'light' themes
    else:
        # Load colors for specific theme mode
        colors = load_colors(colors_file, theme_mode)
    
    # Read template
    with open(template_file, 'r') as f:
        content = f.read()
    
    # Find all variables in format {{path.to.color}}
    variables = re.findall(r'\{\{([^}]+)\}\}', content)
    
    # Replace each variable with actual color value
    for var in variables:
        # Extract theme context if the path starts with dark/light
        theme_context = None
        if var.startswith(('dark.', 'light.')):
            theme_context = var.split('.')[0]
        
        color_value = get_nested_color(colors, var, 5, theme_context)
        if color_value:
            content = content.replace(f'{{{{{var}}}}}', color_value)
        else:
            print(f"Warning: Color not found for path '{var}'", file=sys.stderr)
    
    # Write output
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(content)
    
    print(f"Generated: {output_file}")

def main():
    if len(sys.argv) != 5:
        print("Usage: theme-processor.py <template_file> <colors_file> <theme_mode> <output_file>")
        sys.exit(1)
    
    template_file, colors_file, theme_mode, output_file = sys.argv[1:5]
    
    try:
        process_template(template_file, colors_file, theme_mode, output_file)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()