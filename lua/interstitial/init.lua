local default_opts = {
	path = os.getenv("HOME") .. "/Notes",
}

local M = {
	config = default_opts,
}

local function ensure_dirs(path)
	if vim.fn.isdirectory(path) == 1 then
		vim.fn.mkdir(path, "p")
	end
end

function M.append()
	local path = M.config.path
	ensure_dirs(path)

	local date_str = os.date("%Y-%m-%d")
	local time_str = os.date("%H:%M:%S")

	local filename = date_str .. ".md"
	local filepath = vim.fs.joinpath(path, filename)

	local exists = vim.fn.filereadable(filepath) == 1
	if not exists then
		local file = io.open(filepath, "w")
		if file then
			file:write("# " .. date_str .. "\n")
			file:close()
			vim.notify("Created new interstitial note: " .. filepath)
		else
			vim.notify("Failed to create interstitial note file: " .. filepath, vim.log.levels.ERROR)
		end
	else
		-- append to pre-existing file
		local file = io.open(filepath, "a")
		if file then
			file:write("\n\n## " .. time_str .. "\n")
			file:close()
		else
			vim.notify("Failed to append to interstitial note file: " .. filepath, vim.log.levels.ERROR)
		end
	end
	vim.cmd("edit " .. filepath)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", default_opts, opts or {})
	vim.api.nvim_create_user_command("Interstitial", M.append, {
		nargs = 0,
		desc = "Open or create a date-stamped markdown file for interstitial notes.",
	})
end

return M
