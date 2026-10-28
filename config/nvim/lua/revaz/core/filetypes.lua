local function is_ansible_path(path)
	local normalized = path:gsub("\\", "/")

	for _, directory in ipairs({ "/playbooks/", "/group_vars/", "/host_vars/" }) do
		if normalized:find(directory, 1, true) then
			return true
		end
	end

	if not normalized:find("/roles/", 1, true) then
		return false
	end

	for _, directory in ipairs({ "/tasks/", "/handlers/", "/defaults/", "/vars/", "/meta/" }) do
		if normalized:find(directory, 1, true) then
			return true
		end
	end

	return false
end

local function is_ansible_playbook(bufnr)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
		if line:match("^%s*%-?%s*hosts%s*:") then
			return true
		end
	end

	return false
end

local function yaml_filetype(path, bufnr)
	local has_buffer = bufnr and vim.api.nvim_buf_is_valid(bufnr)
	if is_ansible_path(path) or (has_buffer and is_ansible_playbook(bufnr)) then
		return "yaml.ansible"
	end

	return "yaml"
end

vim.filetype.add({
	extension = {
		yaml = yaml_filetype,
		yml = yaml_filetype,
	},
})
