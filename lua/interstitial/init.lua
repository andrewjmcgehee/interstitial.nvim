local default_opts = {
	path = os.getenv("HOME") .. "/Notes",
}

local M = {
	config = default_opts,
}

function M.append()
	local path = M.config.path

	if vim.fn.isdirectory(path) == 1 then
		if not vim.fn.mkdir(path, "p") then
			vim.notify(
				"Failed to create requisite directories for interstitial.nvim notes.",
				vim.log.levels.ERROR,
				{ title = "Interstitial" }
			)
		end
	end

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
			vim.notify("Created new interstitial note: " .. filepath, vim.log.levels.INFO, { title = "Interstitial" })
		else
			vim.notify(
				"Failed to create interstitial note file: " .. filepath,
				vim.log.levels.ERROR,
				{ title = "Interstitial" }
			)
		end
	else
		-- append to pre-existing file
		local file = io.open(filepath, "a")
		if file then
			file:write("\n\n## " .. time_str .. "\n")
			file:close()
		else
			vim.notify(
				"Failed to append to interstitial note file: " .. filepath,
				vim.log.levels.ERROR,
				{ title = "Interstitial" }
			)
		end
	end
	vim.cmd("edit " .. filepath)
end

M.create_or_read_global_state_file = function()
	-- read or create the state file
	local path = M.config.path
	local state_fp = vim.fs.joinpath(vim.fn.stdpath("data"), "interstitial.state")
	local state_file = io.open(state_fp, "r")
	if not state_file then
		state_file = io.open(state_fp, "w")
		if not state_file then
			vim.notify("Failed to create interstitial.state file", vim.log.levels.ERROR, { title = "Interstitial" })
			return
		end
		state_file:write(path)
	else
		path = state_file:read("*l")
	end
	state_file:close()
	return {
		path = path,
	}
end

M.update_global_state_file = function(path)
	local new_state_fp = vim.fs.joinpath(vim.fn.stdpath("data"), "interstitial.state.new")
	local new_state_file = io.open(new_state_fp, "w")
	if not new_state_file then
		vim.notify("Failed to create interstitial.state.new file", vim.log.levels.ERROR, { title = "Interstitial" })
		return
	end
	new_state_file:write(path)
	new_state_file:close()
	-- move new state file to overwrite old
	local state_fp = vim.fs.joinpath(vim.fn.stdpath("data"), "interstitial.state")
	os.remove(state_fp)
	os.rename(new_state_fp, state_fp)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", default_opts, opts or {})
	local state = M.create_or_read_global_state_file()
	if not state then
		return
	end
	M.update_global_state_file(state.path)
	vim.api.nvim_create_user_command("Interstitial", M.append, {
		nargs = 0,
		desc = "Open or create a date-stamped markdown file for interstitial notes.",
	})
end

return M
