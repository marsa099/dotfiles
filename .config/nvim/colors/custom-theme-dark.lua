-- Custom Dark Theme for Neovim
-- Generated from centralized theme system

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "custom-theme-dark"
vim.o.background = "dark"

-- Color palette
local c = {
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
  keyword = "#6BAFA7",
  command = "#CCD5E4",
  operator = "#B8AFA0",
  comment = "#707B84",
  string = "#A3B18A",
  ["function"] = "#D4A373",
  type = "#88A4C0",
  class = "#88A4C0",
  interface = "#6BAFA7",
  struct = "#A690B8",
  enum = "#88A4C0",
  number = "#CC8B8B",
  boolean = "#A690B8",
  variable = "#EDEDED",
  property = "#88A4C0",
  method = "#D4A373",
  tag = "#6BAFA7",
  attribute = "#88A4C0",
  controlFlow = "#A690B8",
  parameter = "#C3C8C6",
  constant = "#CC8B8B",

  -- Highlights
  highlight_low = "#2F2E3E",
  highlight_med = "#545168",
  highlight_high = "#6F6C85",

  -- Diff backgrounds
  diff_add_bg = "#1C3528",
  diff_delete_bg = "#3B1E1E",
  diff_change_bg = "#2E2A1A",
  diff_text_bg = "#2A3A4A",

  -- Special
  cursor = "#FF570D",
  none = "NONE",
}

-- Helper to set highlights
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ************** UI **************
-- Windows
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg_surface })
hl("FloatBorder", { fg = c.bg_overlay, bg = c.bg_surface })
hl("FloatTitle", { fg = c.blue, bg = c.bg_surface })
hl("WinSeparator", { fg = c.bg_secondary })

-- Diff
hl("Added", { fg = c.green, bg = c.diff_add_bg })
hl("Changed", { fg = c.yellow, bg = c.diff_change_bg })
hl("Removed", { fg = c.red, bg = c.diff_delete_bg })

-- Elements
hl("ColorColumn", {})
hl("Conceal", { fg = c.fg })
hl("CurSearch", { fg = c.bg, bg = c.red })
hl("Cursor", { bg = c.cursor })
hl("CursorLine", { bg = c.bg_secondary })
hl("CursorLineNr", { fg = c.fg, bold = true })
hl("Delimiter", { fg = c.fg })
hl("Directory", { fg = c.blue })
hl("EndOfBuffer", { link = "NonText" })
hl("Error", { fg = c.error })
hl("ErrorMsg", { link = "Error" })
hl("FoldColumn", { link = "NonText" })
hl("Folded", { fg = c.blue, bg = c.bg_secondary })
hl("IncSearch", { link = "Search" })
hl("LineNr", { link = "NonText" })
hl("MatchParen", { fg = c.yellow, bg = c.bg_secondary })
hl("ModeMsg", { fg = c.purple })
hl("MoreMsg", { link = "ModeMsg" })
hl("MsgArea", { fg = c.fg })
hl("MsgSeparator", { fg = c.bg_surface })
hl("NonText", { fg = c.fg_muted })
hl("Pmenu", { fg = c.fg, bg = c.bg_surface })
hl("PmenuMatch", { fg = c.blue })
hl("PmenuSbar", { link = "Pmenu" })
hl("PmenuSel", { bg = c.bg_selection })
hl("PmenuMatchSel", { link = "PmenuSel" })
hl("PmenuThumb", { bg = c.fg_muted })
hl("Question", { fg = c.green })
hl("QuickFixLine", { link = "Search" })
hl("Search", { fg = c.bg, bg = c.yellow })
hl("SignColumn", { fg = c.fg })
hl("SpecialChar", { link = "Special" })
hl("SpecialComment", { fg = c.yellow })
hl("SpecialKey", { fg = c.yellow })
hl("StatusLine", { fg = c.fg })
hl("StatusLineNC", {})
hl("Substitute", { fg = c.green, bg = c.bg_secondary })
hl("TabLine", { fg = c.fg_muted, bg = c.bg })
hl("TabLineFill", { fg = c.fg_muted, bg = c.bg })
hl("TabLineSel", { fg = c.blue, bold = true })
hl("TermCursor", { link = "Cursor" })
hl("Title", { link = "Directory" })
hl("Todo", { link = "SpecialComment" })
hl("Visual", { bg = c.bg_selection })
hl("WarningMsg", { link = "Error" })
hl("Whitespace", { link = "NonText" })
hl("WinBar", { fg = c.fg })
hl("WinBarNC", { link = "WinBar" })

-- ************** SYNTAX **************
hl("Comment", { fg = c.comment, italic = true })
hl("Constant", { fg = c.constant })
hl("Function", { fg = c["function"] })
hl("Keyword", { fg = c.keyword })
hl("Number", { fg = c.number })
hl("Operator", { fg = c.operator })
hl("String", { fg = c.string })
hl("Type", { fg = c.type })

hl("Boolean", { fg = c.boolean })
hl("Character", { link = "String" })
hl("Conditional", { fg = c.controlFlow })
hl("Define", { link = "PreProc" })
hl("Exception", { fg = c.controlFlow })
hl("Float", { link = "Number" })
hl("Identifier", { fg = c.fg })
hl("Include", { link = "PreProc" })
hl("Label", { link = "Conditional" })
hl("Macro", { link = "PreProc" })
hl("PreCondit", { link = "PreProc" })
hl("PreProc", { fg = c.fg })
hl("Repeat", { fg = c.controlFlow })
hl("Special", { fg = c.fg })
hl("Statement", { fg = c.controlFlow })
hl("StorageClass", { link = "Type" })
hl("Structure", { link = "Type" })
hl("Tag", { fg = c.fg })
hl("Typedef", { link = "Type" })

-- ************** FILETYPE **************
-- Diff
hl("DiffAdd", { link = "Added" })
hl("DiffChange", { link = "Changed" })
hl("DiffDelete", { link = "Removed" })
hl("DiffText", { bg = c.diff_text_bg })

-- Gitcommit diffs
hl("diffAdded", { link = "Added" })
hl("diffChanged", { link = "Changed" })
hl("diffRemoved", { link = "Removed" })

-- Gitcommit
hl("gitcommitHeader", {})
hl("gitcommitOnBranch", {})
hl("gitcommitType", { fg = c.purple })
hl("gitcommitArrow", { link = "Statement" })
hl("gitcommitBlank", { link = "Added" })
hl("gitcommitBranch", { link = "Added" })
hl("gitcommitDiscarded", { link = "Added" })
hl("gitcommitDiscardedFile", { link = "Added" })
hl("gitcommitDiscardedType", { link = "Removed" })
hl("gitcommitSummary", { link = "Directory" })
hl("gitcommitUnmerged", { link = "Added" })

-- Help
hl("helpCommand", { fg = c.fg })
hl("helpExample", { link = "String" })
hl("helpHyperTextEntry", { link = "Directory" })
hl("helpOption", { fg = c.fg })
hl("helpVim", { fg = c.fg })

-- Markdown
hl("markdownBlockquote", { fg = c.fg_subtle })
hl("markdownCodeBlock", { bg = c.bg_secondary })
hl("markdownHeadingRule", { link = "markdownRule" })
hl("markdownLinkText", { link = "String" })
hl("markdownListMarker", { fg = c.fg })
hl("markdownRule", { link = "NonText" })
hl("markdownUrl", { link = "@text.uri" })

-- ini
hl("dosiniHeader", { link = "@markup.heading.1.markdown" })
hl("dosiniLabel", { link = "@property" })

-- ************** TREESITTER **************
hl("@constant.builtin", { link = "Constant" })
hl("@function.call", { fg = c.fg })
hl("@function.method.call", { fg = c.fg })
hl("@markup.heading", { link = "Function" })
hl("@markup.raw.block", { link = "markdownCodeBlock" })
hl("@method.call", { fg = c.fg })
hl("@module", { fg = c.fg })
hl("@namespace", { fg = c.blue })
hl("@number.comment", { link = "Comment" })
hl("@property", { fg = c.fg })
hl("@punctuation", { fg = c.fg })
hl("@string.documentation", { link = "Comment" })
hl("@string.escape", { link = "@string.regex" })
hl("@string.regex", { fg = c.green })
hl("@string.special.symbol", { link = "@string.regex" })
hl("@text.literal", { fg = c.fg })
hl("@text.reference", { link = "String" })
hl("@text.uri", { fg = c.blue, underline = true })
hl("@type.builtin", { link = "@type" })

-- Variables
hl("@variable", { fg = c.variable })
hl("@variable.parameter", { fg = c.parameter })
hl("@variable.member", { fg = c.property })

-- Constants
hl("@constant", { fg = c.constant })

-- Control flow keywords
hl("@keyword.return", { fg = c.controlFlow })
hl("@keyword.exception", { fg = c.controlFlow })
hl("@keyword.conditional", { fg = c.controlFlow })
hl("@keyword.repeat", { fg = c.controlFlow })

-- JSX/TSX (Legacy treesitter)
hl("@tag", { fg = c.tag })
hl("@tag.tsx", { fg = c.tag })
hl("@tag.jsx", { fg = c.tag })
hl("@tag.delimiter", { fg = c.tag })
hl("@tag.delimiter.tsx", { fg = c.tag })
hl("@tag.delimiter.jsx", { fg = c.tag })
hl("@tag.attribute", { fg = c.attribute })
hl("@tag.attribute.tsx", { fg = c.attribute })
hl("@tag.attribute.jsx", { fg = c.attribute })

-- JSX/TSX (New treesitter syntax)
hl("@tag.builtin", { fg = c.tag })
hl("@tag.component", { fg = c.tag })
hl("@tag.builtin.tsx", { fg = c.tag })
hl("@tag.component.tsx", { fg = c.tag })
hl("@tag.builtin.jsx", { fg = c.tag })
hl("@tag.component.jsx", { fg = c.tag })
hl("@markup.tag", { fg = c.tag })
hl("@markup.tag.delimiter", { fg = c.tag })
hl("@markup.tag.attribute", { fg = c.attribute })

-- Latex
hl("@markup.link.label", { link = "String" })
hl("@markup.link.latex", { link = "Keyword" })
hl("@markup.environment.latex", { link = "markdownCodeBlock" })
hl("@module.latex", { link = "Function" })
hl("@punctuation.special.latex", { link = "Function" })

for level = 1, 4 do
  hl("@markup.heading." .. level .. ".latex", { link = "String" })
end

-- Markdown
hl("@conceal.markdown_inline", { link = "Operator" })
hl("@markup.link.markdown_inline", { fg = c.fg })
hl("@markup.list.checked.markdown", { link = "DiagnosticOk" })
hl("@markup.list.unchecked.markdown", { link = "DiagnosticError" })
hl("@markup.quote.markdown", { link = "markdownBlockquote" })
hl("@markup.raw.markdown_inline", { fg = c.blue, bg = c.bg_secondary })
hl("@punctuation.special.markdown", { link = "@markup.quote.markdown" })

for level = 1, 6 do
  hl("@markup.heading." .. level .. ".markdown", { fg = c.blue })
end

-- Comment keywords
for comment_type, color in pairs({
  error = { bg = c.error, fg = c.fg },
  danger = { bg = c.error, fg = c.fg },
  warning = { bg = c.warning, fg = c.bg },
  todo = { bg = c.blue, fg = c.bg },
  note = { bg = c.fg, fg = c.bg },
}) do
  hl("@comment." .. comment_type, color)
  hl("@comment." .. comment_type .. ".comment", color)
end

-- ************** LSP **************
-- Diagnostics
for type, color in pairs({
  Error = c.error,
  Warn = c.warning,
  Info = c.info,
  Hint = c.cyan,
  Ok = c.green,
}) do
  hl("Diagnostic" .. type, { fg = color })
  hl("DiagnosticSign" .. type, { fg = color })
  hl("DiagnosticVirtualText" .. type, { fg = color })
  hl("DiagnosticUnderline" .. type, { sp = color, undercurl = true })
end
hl("DiagnosticUnnecessary", { fg = c.comment, undercurl = true })

-- Diagnostic line backgrounds (highlight entire line with error/warning)
hl("DiagnosticLineError", { bg = "#2d1f1f" })
hl("DiagnosticLineWarn", { bg = "#2d2a1a" })
hl("DiagnosticLineInfo", { bg = "#1f252d" })
hl("DiagnosticLineHint", { bg = "#1f2d2a" })

hl("LspCodeLens", { fg = c.fg_muted })
hl("LspSignatureActiveParameter", { sp = c.fg, underline = true })

-- Semantic Tokens - explicitly link to themed groups
hl("@lsp.type.variable", { fg = c.variable })
hl("@lsp.type.parameter", { fg = c.parameter })
hl("@lsp.type.property", { link = "@property" })
hl("@lsp.type.function", { link = "Function" })
hl("@lsp.type.method", { link = "Function" })
hl("@lsp.type.keyword", { link = "Keyword" })
hl("@lsp.type.comment", { link = "Comment" })
hl("@lsp.type.string", { link = "String" })
hl("@lsp.type.number", { link = "Number" })
hl("@lsp.type.operator", { link = "Operator" })
hl("@lsp.type.type", { link = "Type" })
hl("@lsp.type.class", { fg = c.class })
hl("@lsp.type.interface", { fg = c.interface })
hl("@lsp.type.struct", { fg = c.struct })
hl("@lsp.type.namespace", { link = "@namespace" })
hl("@lsp.type.enum", { fg = c.enum })
hl("@lsp.type.enumMember", { fg = c.constant })
hl("@lsp.mod.readonly", {})
hl("@lsp.mod.defaultLibrary", {})
hl("@lsp.typemod.variable.readonly", { link = "Identifier" })
hl("@lsp.typemod.variable.defaultLibrary", { link = "Identifier" })

-- ************** PLUGINS **************
-- folke/lazy.nvim
hl("LazyButton", { bg = c.bg_selection })
hl("LazyH2", { link = "FloatTitle" })
hl("LazyButtonActive", { link = "Search" })
hl("LazyCommit", { link = "" })
hl("LazyCommitType", { link = "@markup.heading.gitcommit" })
hl("LazyCommitIssue", { link = "Number" })
hl("LazyProgressDone", { link = "LazyComment" })
hl("LazyProgressTodo", { link = "FloatBorder" })
hl("LazyReasonCmd", { link = "Comment" })
hl("LazyReasonColorscheme", { link = "Comment" })
hl("LazyReasonEvent", { link = "Comment" })
hl("LazyReasonFt", { link = "Comment" })
hl("LazyReasonPlugin", { link = "Comment" })
hl("LazyReasonRequire", { link = "Comment" })
hl("LazyReasonSource", { link = "Comment" })
hl("LazyReasonStart", { link = "Comment" })
hl("LazySpecial", { link = "Comment" })

-- mason-org/mason.nvim
hl("MasonLink", { fg = c.blue })
hl("MasonError", { link = "DiagnosticError" })
hl("MasonMuted", { link = "Comment" })
hl("MasonHeader", { link = "FloatTitle" })
hl("MasonNormal", { link = "NormalFloat" })
hl("MasonHeading", { link = "FloatTitle" })
hl("MasonWarning", { link = "DiagnosticWarn" })
hl("MasonBackdrop", { link = "NormalFloat" })
hl("MasonHighlight", { fg = c.comment })
hl("MasonHighlightBlock", { bg = c.bg_secondary })
hl("MasonMutedBlock", { bg = c.bg_secondary })
hl("MasonMutedBlockBold", { link = "Comment" })
hl("MasonHeaderSecondary", { link = "Search" })
hl("MasonHighlightBlockBold", { link = "Search" })
hl("MasonHighlightSecondary", { link = "Search" })
hl("MasonHighlightBlockSecondary", {})
hl("MasonHighlightBlockBoldSecondary", {})

-- lewis6991/gitsigns.nvim
hl("GitSignsAdd", { fg = c.green })
hl("GitSignsChange", { fg = c.yellow })
hl("GitSignsDelete", { fg = c.red })
hl("GitSignsChangedelete", { link = "GitSignsChange" })
hl("GitSignsTopdelete", { link = "GitSignsDelete" })
hl("GitSignsUntracked", { link = "NonText" })
hl("GitSignsStagedAdd", { fg = c.green })
hl("GitSignsStagedChange", { fg = c.yellow })
hl("GitSignsStagedDelete", { fg = c.red })
hl("GitSignsStagedChangedelete", { link = "GitSignsStagedChange" })
hl("GitSignsStagedTopdelete", { link = "GitSignsStagedDelete" })
hl("GitSignsStagedUntracked", { link = "GitSignsStagedAdd" })
hl("GitSignsCurrentLineBlame", { link = "NonText" })
hl("GitSignsAddInline", { link = "Added" })
hl("GitSignsAddLnInline", { fg = c.fg, bg = c.diff_add_bg })
hl("GitSignsDeleteInline", { link = "Removed" })
hl("GitSignsDeleteLnInline", { fg = c.fg, bg = c.diff_delete_bg })
hl("GitSignsChangeInline", { link = "DiffText" })
hl("GitSignsChangeLnInline", { link = "Changed" })
hl("GitSignsDeleteVirtLn", { link = "Removed" })
hl("GitSignsDeleteVirtLnInLine", { link = "Removed" })
hl("GitSignsVirtLnum", { link = "LineNr" })

-- stevearc/aerial.nvim
hl("AerialLine", { bg = c.bg_selection })
hl("AerialNormal", { link = "" })

-- folke/edgy.nvim
hl("EdgyNormal", { fg = c.comment, bg = c.bg_surface })
hl("EdgyIcon", { fg = c.comment, bg = c.bg_surface })
hl("EdgyIconActive", { link = "EdgyIcon" })
hl("EdgyWinBar", { bg = c.bg_surface, underline = true, sp = c.bg_secondary })
hl("EdgyTitle", { bg = c.bg_surface })

-- hrsh7th/nvim-cmp
hl("CmpItemAbbrDeprecated", { strikethrough = true })
hl("CmpItemAbbrMatch", { link = "PmenuMatch" })
hl("CmpItemKind", { link = "Keyword" })

-- saghen/blink.cmp
hl("BlinkCmpDoc", { link = "Pmenu" })
hl("BlinkCmpDocBorder", { fg = c.bg_overlay, bg = c.bg_surface })
hl("BlinkCmpDocSeparator", { fg = c.bg_overlay })
hl("BlinkCmpGhostText", { link = "NonText" })
hl("BlinkCmpKind", { fg = c.blue })
hl("BlinkCmpLabel", { fg = c.fg })
hl("BlinkCmpLabelDetail", { link = "NonText" })
hl("BlinkCmpLabelDescription", { fg = c.fg_muted })
hl("BlinkCmpLabelMatch", { link = "PmenuMatch" })
hl("BlinkCmpMenuBorder", { fg = c.bg_overlay, bg = c.bg_surface })
hl("BlinkCmpMenuSelection", { link = "PmenuMatchSel" })

-- rrethy/vim-illuminate
hl("IlluminatedWordText", { link = "MatchParen" })
hl("IlluminatedWordRead", { link = "IlluminatedWordText" })
hl("IlluminatedWordWrite", { link = "IlluminatedWordText" })

-- echasnovski/mini.cursorword
hl("MiniCursorwordCurrent", {})
hl("MiniCursorword", { link = "IlluminatedWordText" })

-- rareitems/hl_match_area.nvim
hl("MatchArea", { link = "MatchParen" })

-- mcauley-penney/visual-whitespace.nvim
hl("VisualNonText", { fg = c.purple, bg = c.bg_selection })

-- mcauley-penney/match-visual.nvim
hl("VisualMatch", { link = "MatchParen" })

-- Neo-tree
hl("NeoTreeNormal", { fg = c.fg, bg = c.bg })
hl("NeoTreeNormalNC", { fg = c.fg, bg = c.bg })
hl("NeoTreeDirectoryName", { fg = c.blue })
hl("NeoTreeDirectoryIcon", { fg = c.blue })
hl("NeoTreeFileName", { fg = c.fg })
hl("NeoTreeFileIcon", { fg = c.fg })
hl("NeoTreeRootName", { fg = c.purple, bold = true })
hl("NeoTreeGitAdded", { fg = c.green })
hl("NeoTreeGitModified", { fg = c.yellow })
hl("NeoTreeGitDeleted", { fg = c.red })

-- Telescope
hl("TelescopeNormal", { fg = c.fg, bg = c.bg_surface })
hl("TelescopeBorder", { fg = c.bg_surface, bg = c.bg_surface })
hl("TelescopePromptNormal", { fg = c.fg, bg = c.bg_overlay })
hl("TelescopePromptBorder", { fg = c.bg_overlay, bg = c.bg_overlay })
hl("TelescopePromptTitle", { fg = c.bg, bg = c.purple })
hl("TelescopePreviewTitle", { fg = c.bg, bg = c.green })
hl("TelescopeResultsTitle", { fg = c.bg, bg = c.blue })
hl("TelescopeSelection", { bg = c.highlight_low })
hl("TelescopeMatching", { fg = c.yellow, bold = true })
