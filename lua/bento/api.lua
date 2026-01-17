--- Bento.nvim API module - Public API functions for buffer management
--- This module provides a clean public interface to bento functionality.
--- All implementations are in the main bento module; this is a thin wrapper.
--- @module bento.api

local M = {}

--- Check if a buffer is locked
--- @param buf_id number|nil Buffer ID (defaults to current buffer)
--- @return boolean
function M.is_locked(buf_id)
    return require("bento").is_locked(buf_id)
end

--- Toggle the lock status of a buffer
--- Locked buffers are protected from automatic deletion
--- @param buf_id number|nil Buffer ID (defaults to current buffer)
--- @return boolean Whether the buffer is now locked
function M.toggle_lock(buf_id)
    return require("bento").toggle_lock(buf_id)
end

--- Close all buffers matching the specified criteria
--- By default, closes ALL buffers including visible, locked, and current buffers.
--- Pass `false` for a parameter to exclude those buffers from being closed.
---
--- @param opts table|nil Options table with the following fields:
---   - visible (boolean): If false, do not close visible buffers (default: true)
---   - locked (boolean): If false, do not close locked buffers (default: true)
---   - current (boolean): If false, do not close the current buffer (default: true)
--- @return number Number of buffers closed
function M.close_all_buffers(opts)
    return require("bento").close_all_buffers(opts)
end

return M
