local utils = require("bento.utils")

local M = {}

BentoConfig = BentoConfig or {}
M.marks = {}

M.buffer_metrics = {}

function M.get_config()
    return BentoConfig or {}
end

-- Built-in actions
M.actions = {
    open = {
        key = "<CR>",
        hl = "DiagnosticVirtualTextHint",
        action = function(_, buf_name)
            local bufnr = vim.fn.bufnr(buf_name)
            if bufnr ~= -1 then
                vim.cmd("buffer " .. bufnr)
            else
                vim.cmd("edit " .. buf_name)
            end
            require("bento.ui").collapse_menu()
        end,
    },
    delete = {
        key = "<BS>",
        hl = "DiagnosticVirtualTextError",
        action = function(buf_id, _)
            vim.api.nvim_buf_delete(buf_id, { force = false })
            require("bento.ui").refresh_menu()
        end,
    },
    vsplit = {
        key = "|",
        hl = "DiagnosticVirtualTextInfo",
        action = function(_, buf_name)
            local bufnr = vim.fn.bufnr(buf_name)
            if bufnr ~= -1 then
                vim.cmd("vsplit | buffer " .. bufnr)
            else
                vim.cmd("vsplit " .. buf_name)
            end
            require("bento.ui").close_menu()
        end,
    },
    split = {
        key = "_",
        hl = "DiagnosticVirtualTextInfo",
        action = function(_, buf_name)
            local bufnr = vim.fn.bufnr(buf_name)
            if bufnr ~= -1 then
                vim.cmd("split | buffer " .. bufnr)
            else
                vim.cmd("split " .. buf_name)
            end
            require("bento.ui").close_menu()
        end,
    },
}

-- Keys to use for labels
M.line_keys = {
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
}

local function setup_main_keymap()
    local config = M.get_config()
    if config.main_keymap and config.main_keymap ~= "" then
        vim.keymap.set(
            "n",
            config.main_keymap,
            "<Cmd>lua require('bento.ui').handle_main_keymap()<CR>",
            { silent = true, desc = "Buffer Manager" }
        )
    end
end

local function setup_autocmds()
    vim.api.nvim_create_user_command("BentoToggle", function()
        require("bento.ui").toggle_menu()
    end, { desc = "Toggle bento menu" })

    vim.api.nvim_create_user_command("BentoToggleMinimalMenu", function()
        require("bento.ui").toggle_minimal_menu()
    end, { desc = "Toggle bento minimal menu rendering" })

    local function is_menu_buffer(bufnr)
        local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, "bento_menu")
        return ok and val
    end

    local augroup =
        vim.api.nvim_create_augroup("BentoRefresh", { clear = true })

    vim.api.nvim_create_autocmd(
        { "BufAdd", "BufDelete", "BufWipeout", "BufEnter", "WinEnter" },
        {
            group = augroup,
            callback = function(args)
                if is_menu_buffer(args.buf) then
                    return
                end
                if
                    vim.bo[args.buf].buftype ~= ""
                    and vim.bo[args.buf].buftype ~= "terminal"
                then
                    return
                end
                require("bento.ui").refresh_menu()
            end,
            desc = "Auto-refresh bento menu",
        }
    )

    vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            local win_id = vim.api.nvim_get_current_win()
            if not win_id or win_id == nil then
                return
            end
            require("bento.ui").set_last_editor_win(win_id)
        end,
        desc = "Update current window in bento menu",
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            require("bento.ui").collapse_menu()
        end,
        desc = "Collapse bento menu on cursor move",
    })
    vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            local win_id = vim.api.nvim_get_current_win()
            if not win_id or win_id == nil then
                return
            end
            require("bento.ui").set_last_editor_win(win_id)
        end,
        desc = "Update current window in bento menu",
    })

    vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
            require("bento.ui").refresh_menu()
        end,
        desc = "Refresh bento menu on window resize",
    })

    vim.api.nvim_create_autocmd("BufAdd", {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            require("bento").enforce_buffer_limit()
        end,
        desc = "Enforce maximum buffer limit",
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            if vim.bo[args.buf].buftype ~= "" then
                return
            end
            require("bento").record_access(args.buf)
        end,
        desc = "Track buffer access for deletion metrics",
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = augroup,
        callback = function(args)
            if is_menu_buffer(args.buf) then
                return
            end
            if vim.bo[args.buf].buftype ~= "" then
                return
            end
            require("bento").record_edit(args.buf)
        end,
        desc = "Track buffer edits for deletion metrics",
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = augroup,
        callback = function(args)
            require("bento").cleanup_metrics(args.buf)
        end,
        desc = "Clean up buffer metrics on deletion",
    })
end

-- Initialize or get metrics for a buffer
local function get_buffer_metrics(buf_id)
    if not M.buffer_metrics[buf_id] then
        M.buffer_metrics[buf_id] = {
            access_times = {},
            edit_times = {},
        }
    end
    return M.buffer_metrics[buf_id]
end

-- Record a buffer access event
function M.record_access(buf_id)
    local metrics = get_buffer_metrics(buf_id)
    table.insert(metrics.access_times, os.time())
end

-- Record a buffer edit event
function M.record_edit(buf_id)
    local metrics = get_buffer_metrics(buf_id)
    table.insert(metrics.edit_times, os.time())
end

-- Clean up metrics for deleted buffers
function M.cleanup_metrics(buf_id)
    M.buffer_metrics[buf_id] = nil
end

-- Calculate frecency score for a list of timestamps
-- Uses a decay-based algorithm where recent events score higher
-- Formula: sum of (1 / (1 + age_in_hours)) for each event
local function calculate_frecency(timestamps)
    if not timestamps or #timestamps == 0 then
        return 0
    end

    local now = os.time()
    local score = 0

    for _, timestamp in ipairs(timestamps) do
        local age_hours = (now - timestamp) / 3600
        score = score + (1 / (1 + age_hours))
    end

    return score
end

-- Get the metric value for a buffer based on the configured metric type
local function get_buffer_metric_value(buf_id, metric_type)
    local metrics = M.buffer_metrics[buf_id]

    if metric_type == "recency_access" then
        local buf_info = vim.fn.getbufinfo(buf_id)[1]
        if buf_info then
            return buf_info.lastused or 0
        end
        return 0
    elseif metric_type == "recency_edit" then
        if metrics and #metrics.edit_times > 0 then
            return metrics.edit_times[#metrics.edit_times]
        end
        return 0
    elseif metric_type == "frecency_access" then
        if metrics then
            return calculate_frecency(metrics.access_times)
        end
        return 0
    elseif metric_type == "frecency_edit" then
        if metrics then
            return calculate_frecency(metrics.edit_times)
        end
        return 0
    end

    local buf_info = vim.fn.getbufinfo(buf_id)[1]
    if buf_info then
        return buf_info.lastused or 0
    end
    return 0
end

-- Initialize marks for all valid buffers
function M.initialize_marks()
    for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf_id)
        if utils.buffer_is_valid(buf_id, buf_name) then
            table.insert(M.marks, { filename = buf_name, buf_id = buf_id })
        end
    end
end

-- Get buffer to delete based on configured metric (excluding current and visible buffers)
function M.get_lru_buffer()
    local config = M.get_config()
    local metric_type = config.buffer_deletion_metric or "recency_access"
    local current_buf = vim.api.nvim_get_current_buf()
    local visible_bufs = {}

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            visible_bufs[buf] = true
        end
    end

    local candidate_buf = nil
    local candidate_score = math.huge

    for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf_id)
        if
            utils.buffer_is_valid(buf_id, buf_name)
            and buf_id ~= current_buf
            and not visible_bufs[buf_id]
        then
            local score = get_buffer_metric_value(buf_id, metric_type)
            if score < candidate_score then
                candidate_score = score
                candidate_buf = buf_id
            end
        end
    end

    return candidate_buf
end

-- Enforce buffer limit by deleting LRU buffer if needed
function M.enforce_buffer_limit()
    local config = M.get_config()
    if config.max_open_buffers <= 0 then
        return
    end

    local valid_buffers = 0
    for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf_id)
        if utils.buffer_is_valid(buf_id, buf_name) then
            valid_buffers = valid_buffers + 1
        end
    end

    while valid_buffers > config.max_open_buffers do
        local lru_buf = M.get_lru_buffer()
        if not lru_buf then
            break
        end

        pcall(vim.api.nvim_buf_delete, lru_buf, { force = false })
        valid_buffers = valid_buffers - 1
    end
end

function M.setup(config)
    config = config or {}

    local default_config = {
        main_keymap = ";",
        position = "middle-right",
        offset_x = 0,
        offset_y = 0,
        dash_char = "─",
        label_padding = 1,
        default_action = "open",
        max_open_buffers = -1,
        buffer_deletion_metric = "frecency_access", -- "recency_access", "recency_edit", "frecency_access", "frecency_edit"
        minimal_menu = nil, -- nil | "dashed" | "filename" | "full"

        highlights = {
            current = "Bold",
            active = "Normal",
            inactive = "Comment",
            modified = "DiagnosticWarn",
            inactive_dash = "Comment",
            previous = "Search",
            label_open = "DiagnosticVirtualTextHint",
            label_delete = "DiagnosticVirtualTextError",
            label_vsplit = "DiagnosticVirtualTextInfo",
            label_split = "DiagnosticVirtualTextInfo",
            label_minimal = "Visual",
            window_bg = "BentoNormal",
        },
    }

    BentoConfig = utils.merge_tables(default_config, config)

    M.actions.open.hl = BentoConfig.highlights.label_open
    M.actions.delete.hl = BentoConfig.highlights.label_delete
    M.actions.vsplit.hl = BentoConfig.highlights.label_vsplit
    M.actions.split.hl = BentoConfig.highlights.label_split

    BentoConfig.actions = M.actions

    if config.actions then
        BentoConfig.actions = utils.merge_tables(M.actions, config.actions)
    end

    local reserved = { "<Esc>", BentoConfig.main_keymap }
    for _, action_config in pairs(BentoConfig.actions) do
        if action_config.key then
            table.insert(reserved, action_config.key)
        end
    end
    M.line_keys = vim.tbl_filter(function(key)
        return not vim.tbl_contains(reserved, key)
    end, M.line_keys)

    setup_main_keymap()

    vim.defer_fn(function()
        require("bento").enforce_buffer_limit()
    end, 50)

    vim.defer_fn(function()
        require("bento.ui").setup_state()
        if BentoConfig.minimal_menu then
            require("bento.ui").toggle_menu()
        end
    end, 100)

    setup_autocmds()

    M.initialize_marks()
end

return M
