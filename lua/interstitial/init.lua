local M = {
	path = os.getenv("HOME") .. "/Notes",
}

local function state_path()
	return vim.fs.joinpath(vim.fn.stdpath("data"), "interstitial.state")
end

local function read_state()
	local state_fp = state_path()
	local file = io.open(state_fp, "r")
	if not file then
		return nil
	end
	local path = file:read("*l")
	file:close()
	if not path or path:match("^%s*$") then
		return nil
	end
	return { path = path }
end

local function write_state(state)
	local state_fp = state_path()
	local file = io.open(state_fp, "w")
	if not file then
		vim.notify(
			"Failed to write to interstitial.state file: " .. state_fp,
			vim.log.levels.ERROR,
			{ title = "Interstitial" }
		)
		return false
	end
	file:write(state.path)
	file:close()
	return true
end

local function init_state(opts)
	local state = read_state()
	if state then
		return state
	end
	local path = (opts and opts.path) or default_opts.path
	state = { path = path }
	if write_state(state) then
		return state
	end
	return nil
end

function M.append()
	if vim.fn.isdirectory(M.path) == 0 then
		if not vim.fn.mkdir(M.path, "p") then
			vim.notify("Failed to create notes directories", vim.log.levels.ERROR, { title = "Interstitial" })
			return
		end
	end

	local date_str = os.date("%Y-%m-%d")
	local time_str = os.date("%H:%M:%S")
	local filename = date_str .. ".md"
	local filepath = vim.fs.joinpath(M.path, filename)
	local exists = vim.fn.filereadable(filepath) == 1

	-- create new
	if not exists then
		local file = io.open(filepath, "w")
		if not file then
			vim.notify("Failed to create note: " .. filepath, vim.log.levels.ERROR, { title = "Interstitial" })
			return
		end
		file:write("# " .. date_str .. "\n")
		file:close()
		vim.notify("Created new note: " .. filepath, vim.log.levels.INFO, { title = "Interstitial" })
	end
	-- always append whether created or existing
	local file = io.open(filepath, "a")
	if not file then
		vim.notify("Failed to append to note: " .. filepath, vim.log.levels.ERROR, { title = "Interstitial" })
		return
	end
	file:write("\n\n## " .. time_str .. "\n")
	file:close()
	vim.cmd("edit " .. filepath)
end

function M.set_notes_base_path(path)
	local expanded_path = vim.fn.expand(path)
	local state = { path = path }
	if write_state(state) then
		M.path = expanded_path
		vim.notify("Updated notes base path to: " .. expanded_path, vim.log.levels.INFO, { title = "Interstitial" })
		return true
	end
	return false
end

function M.setup(opts)
	local state = init_state(opts)
	if not state then
		vim.notify("Failed to initialize interstitial.nvim", vim.log.levels.ERROR, { title = "Interstitial" })
		return
	end

	M.path = state.path

	vim.api.nvim_create_user_command("Interstitial", M.append, {
		nargs = 0,
		desc = "Open or create a date-stamped markdown file for interstitial notes.",
	})
end

return M
