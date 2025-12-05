-- Custom Theme for Neovim
-- Generated from centralized theme system

local M = {}

M.colors = {
  -- Dark theme colors
  dark = {
    -- Background colors
    bg = "#181818",
    bg_secondary = "#1B1B1B",
    bg_tertiary = "#1B1B1B",
    bg_selection = "#282F38",
    bg_surface = "#1B1B1B",
    bg_overlay = "#292826",
    
    -- Foreground colors
    fg = "#EDEDED",
    fg_secondary = "#C3C8C6",
    fg_muted = "#707B84",
    fg_subtle = "#707B84",
    
    -- Accent colors
    red = "#FF7B72",
    orange = "#FF570D",
    yellow = "#ff8a31",
    green = "#97B5A6",
    cyan = "#8A9AA6",
    blue = "#CCD5E4",
    purple = "#8A92A7",
    pink = "#8A92A7",
    
    -- Semantic colors
    error = "#FF7B72",
    warning = "#FF570D",
    success = "#97B5A6",
    info = "#CCD5E4",
    keyword = "#97B5A6",
    command = "#CCD5E4",
    operator = "#ff8a31",
    comment = "#707B84",
    string = "#CCD5E4",
    ["function"] = "#CCD5E4",
    type = "#8A9AA6",
    number = "#FF7B72",
    boolean = "#8A92A7",
    variable = "#EDEDED",
    property = "#8A9AA6",
    method = "#FF570D",
    tag = "#CCD5E4",
    attribute = "#8A9AA6",
    
    -- Highlights
    highlight_low = "#2F2E3E",
    highlight_med = "#545168",
    highlight_high = "#6F6C85",
    
    -- Special
    cursor = "#FF570D",
    none = "NONE",
  },
  
  -- Light theme colors
  light = {
    -- Background colors
    bg = "#FDF6E3",
    bg_secondary = "#F9F2DF",
    bg_tertiary = "#FDF6E3",
    bg_selection = "#f4eeee",
    bg_surface = "#F9F2DF",
    bg_overlay = "#EBE4D6",
    
    -- Foreground colors
    fg = "#2D4A3D",
    fg_secondary = "#575279",
    fg_muted = "#9893a5",
    fg_subtle = "#8A92A7",
    
    -- Accent colors
    red = "#ED333B",
    orange = "#d7827e",
    yellow = "#69756C",
    green = "#5E7270",
    cyan = "#4A7C59",
    blue = "#286983",
    purple = "#B8713A",
    pink = "#8A92A7",
    
    -- Semantic colors
    error = "#ED333B",
    warning = "#69756C",
    success = "#5E7270",
    info = "#4A7C59",
    keyword = "#ED333B",
    command = "#286983",
    operator = "#4A7C59",
    comment = "#9893a5",
    string = "#4A7C59",
    ["function"] = "#286983",
    type = "#4A7C59",
    number = "#ED333B",
    boolean = "#B8713A",
    variable = "#2D4A3D",
    property = "#4A7C59",
    method = "#d7827e",
    tag = "#286983",
    attribute = "#4A7C59",
    
    -- Highlights
    highlight_low = "#E8EAED",
    highlight_med = "#D5D8DD",
    highlight_high = "#C2C6CC",
    
    -- Special
    cursor = "#FF570D",
    none = "NONE",
  }
}

-- Get current theme based on vim background
function M.get_colors()
  return vim.o.background == "light" and M.colors.light or M.colors.dark
end

return M