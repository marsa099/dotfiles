local function find_git_root(start_path)
	local path = vim.fn.fnamemodify(start_path, ":h") -- Start from the directory where the file is created
	while path and path ~= "/" do
		if vim.fn.isdirectory(path .. "/.git") == 1 then
			return path -- Return the first found .git directory as root
		end
		path = vim.fn.fnamemodify(path, ":h") -- Move up one directory
	end
	return nil -- No .git directory found
end

vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.cs",
	callback = function()
		local filename = vim.fn.expand("%:t:r") -- Get filename without extension
		local filepath = vim.fn.expand("%:p") -- Get full file path

		-- Skip template generation if the filename starts with "I" (e.g., interface files)
		if filename:match("^I[A-Z]") then
			return
		end

		local git_root = find_git_root(filepath) -- Find the nearest .git directory

		if not git_root then
			return -- No .git directory found, skip template
		end

		-- Generate namespace based on relative path from git root
		local relative_path = filepath:sub(#git_root + 2):gsub("%.cs$", "")
		local namespace = relative_path:gsub("/", "."):gsub("%." .. filename .. "$", "")

		-- Fix leading dot if present
		if namespace:sub(1, 1) == "." then
			namespace = namespace:sub(2)
		end

		-- Generate class template
		local template = string.format(
			[[
namespace %s
{
    public class %s
    {
    }
}
]],
			namespace,
			filename
		)

		-- Insert template only if the file is empty
		if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
			vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.split(template, "\n"))
		end
	end,
})
