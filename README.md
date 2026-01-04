<div align="center">

![logo](https://github.com/user-attachments/assets/2105a347-4218-4afb-b20b-74fcbcff4b5a)

# 🍱 bento.nvim

</div>

A minimalist, efficient, and extensible buffer manager for Neovim.

## Features

- **Transparent sidebar** with multiple collapsed states (dashes, filenames, full, or hidden) and expanded (labels + names) states
- **Smart label assignment** based on filenames for quick buffer switching
- **Last accessed buffer** quick switch (press `;` twice)
- **Extensible action system** with visual feedback (open, delete, custom actions)
- **Visual indicators** for current, active, and inactive buffers
- **Buffer limit enforcement** with configurable deletion metrics (optional)
- **Buffer locking** to protect important buffers from automatic deletion (persisted across sessions)
- **Auto-collapse** on selection and cursor movement
- **No dependencies**

## Installation

Neovim 0.9.0+ required. Works with any plugin manager:

```lua
-- lazy.nvim
{ "serhez/bento.nvim", opts = {} }

-- packer.nvim
use({ "serhez/bento.nvim", config = function() require("bento").setup() end })
```

## Quick Start

Works out of the box with defaults. The main keymap is `;`:

- `;` once → Open menu (collapsed, shows dashes)
- `;` twice → Expand menu (shows labels and names) / Switch to last accessed buffer
- Label key → Open that buffer
- `<CR>` → Enter open mode, then select buffer
- `<BS>` → Enter delete mode, then select buffer
- `|` → Enter vertical split mode, then select buffer
- `_` → Enter horizontal split mode, then select buffer
- `*` → Toggle lock on selected buffer (protected from auto-deletion)
- `ESC` → Collapse back to dashes

## Visual States

**Collapsed/Minimal:** Configurable via `minimal_menu` option:
- `nil` (default): No collapsed menu shown
- `"dashed"`: Shows dashes only
  - `──` = Active buffer (visible)
  - ` ─` = Inactive buffer (hidden)
- `"filename"`: Shows filenames only (no labels)
- `"full"`: Shows full menu (filenames + labels) with distinct highlighting

**Expanded:** Shows buffer names + labels (right-aligned)
- **Bold** = Current buffer
- Normal = Active in other windows
- *Dimmed* = Inactive
- `;` label = Last accessed buffer

## Actions

Actions change label colors for visual feedback. Built-in actions:
- **Open** (`<CR>`): Opens selected buffer in current window
- **Delete** (`<BS>`): Deletes selected buffer
- **Vertical Split** (`|`): Opens selected buffer in a vertical split
- **Horizontal Split** (`_`): Opens selected buffer in a horizontal split
- **Lock** (`*`): Toggles lock on selected buffer (locked buffers are protected from automatic deletion)

### Custom Actions

```lua
require("bento").setup({
    actions = {
        git_stage = {
            key = "g",
            hl = "DiffAdd", -- Optional: custom label color
            action = function(buf_id, buf_name)
                vim.cmd("!git add " .. vim.fn.shellescape(buf_name))
            end,
        },
    },
})
```

Action fields: `key` (required), `action` (required), `hl` (optional highlight group)

## Configuration

All options with defaults:

```lua
require("bento").setup({
    main_keymap = ";", -- Main toggle/expand key
    position = "middle-right", -- Menu position (see below)
    offset_x = 0, -- Horizontal offset from position
    offset_y = 0, -- Vertical offset from position
    dash_char = "─", -- Character for collapsed dashes
    lock_char = "🔒", -- Character shown before locked buffer names
    label_padding = 1, -- Padding around labels
    max_open_buffers = -1, -- Max buffers (-1 = unlimited)
    buffer_deletion_metric = "frecency_access", -- Metric for buffer deletion (see below)
    default_action = "open", -- Action when pressing label directly
    minimal_menu = nil, -- Collapsed menu style: nil, "dashed", "filename", or "full"

    -- Highlight groups
    highlights = {
        current = "Bold", -- Current buffer filename (in last editor window)
        active = "Normal", -- Active buffers visible in other windows
        inactive = "Comment", -- Inactive/hidden buffer filenames
        modified = "DiagnosticWarn", -- Modified/unsaved buffer filenames and dashes
        inactive_dash = "Comment", -- Inactive buffer dashes in collapsed state
        previous = "Search", -- Label for previous buffer (main_keymap label)
        label_open = "DiagnosticVirtualTextHint", -- Labels in open action mode
        label_delete = "DiagnosticVirtualTextError", -- Labels in delete action mode
        label_vsplit = "DiagnosticVirtualTextInfo", -- Labels in vertical split mode
        label_split = "DiagnosticVirtualTextInfo", -- Labels in horizontal split mode
        label_lock = "DiagnosticVirtualTextWarn", -- Labels in lock action mode
        label_minimal = "Visual", -- Labels in collapsed "full" mode
        window_bg = "BentoNormal", -- Menu window background
    },

    -- Custom actions
    actions = {},
})
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `main_keymap` | string | `";"` | Primary key for menu toggle and expand |
| `position` | string | `"middle-right"` | Menu position: `"top-left"`, `"top-right"`, `"middle-left"`, `"middle-right"`, `"bottom-left"`, `"bottom-right"` |
| `offset_x` | number | `0` | Horizontal offset from position |
| `offset_y` | number | `0` | Vertical offset from position |
| `dash_char` | string | `"─"` | Character for collapsed state lines |
| `lock_char` | string | `"🔒"` | Character displayed before locked buffer names |
| `label_padding` | number | `1` | Padding on left/right of labels |
| `max_open_buffers` | number | `-1` | Maximum number of buffers to keep open (`-1` = unlimited) |
| `buffer_deletion_metric` | string | `"frecency_access"` | Metric used to decide which buffer to delete when limit is reached (see below) |
| `default_action` | string | `"open"` | Default action mode when menu expands |
| `minimal_menu` | string/nil | `nil` | Collapsed menu style: `nil` (hidden), `"dashed"` (dash lines), `"filename"` (names only), `"full"` (names + labels) |
| `highlights` | table | See below | Highlight groups for all UI elements |
| `actions` | table | Built-in actions | Action definitions (see Actions section) |

### Buffer Deletion Metrics

When `max_open_buffers` is set to a positive value, bento will automatically delete buffers to stay within the limit. The `buffer_deletion_metric` option controls how buffers are prioritized for deletion:

| Metric | Description |
|--------|-------------|
| `"recency_access"` | Delete the buffer that was **accessed** (entered/viewed) least recently. Uses Neovim's built-in `lastused` tracking. |
| `"recency_edit"` | Delete the buffer that was **edited** least recently. Buffers you haven't modified in a while are deleted first. |
| `"frecency_access"` | Delete the buffer with the lowest **access frecency**. This is the default. Frecency combines frequency and recency - buffers you access often and recently score higher and are kept. |
| `"frecency_edit"` | Delete the buffer with the lowest **edit frecency**. Buffers you edit frequently and recently score higher and are kept. |

**Recency** metrics simply look at when the last event occurred. **Frecency** metrics use a decay-based algorithm that considers the entire history of events, giving higher scores to buffers that are both frequently and recently used.

### Highlights

All highlights are configurable under the `highlights` table:

| Key | Default | Description |
|-----|---------|-------------|
| `current` | `"Bold"` | Current buffer filename (in last editor window) |
| `active` | `"Normal"` | Active buffers visible in other windows |
| `inactive` | `"Comment"` | Inactive/hidden buffer filenames |
| `modified` | `"DiagnosticWarn"` | Modified/unsaved buffer filenames and dashes |
| `inactive_dash` | `"Comment"` | Inactive buffer dashes in collapsed state |
| `previous` | `"Search"` | Label for previous buffer (the `main_keymap` label) |
| `label_open` | `"DiagnosticVirtualTextHint"` | Labels in open action mode |
| `label_delete` | `"DiagnosticVirtualTextError"` | Labels in delete action mode |
| `label_vsplit` | `"DiagnosticVirtualTextInfo"` | Labels in vertical split mode |
| `label_split` | `"DiagnosticVirtualTextInfo"` | Labels in horizontal split mode |
| `label_lock` | `"DiagnosticVirtualTextWarn"` | Labels in lock action mode |
| `label_minimal` | `"Visual"` | Labels in collapsed "full" mode |
| `window_bg` | `"BentoNormal"` | Menu window background (transparent by default) |


## Lua API

```lua
-- Menu control
require("bento.ui").toggle_menu()
require("bento.ui").expand_menu()
require("bento.ui").collapse_menu()
require("bento.ui").close_menu()
require("bento.ui").refresh_menu()

-- Actions
require("bento.ui").set_action_mode("delete")
require("bento.ui").select_buffer(index)

-- Buffer locking (protects buffers from automatic deletion)
-- Lock state is persisted across sessions via :mksession
require("bento").toggle_lock()      -- Toggle lock on current buffer
require("bento").toggle_lock(bufnr) -- Toggle lock on specific buffer
require("bento").is_locked()        -- Check if current buffer is locked
require("bento").is_locked(bufnr)   -- Check if specific buffer is locked

-- Command
:BentoToggle
```

## Examples

### Custom Highlighting

```lua
require("bento").setup({
    highlights = {
        current = "Title",
        active = "Normal",
        inactive = "NonText",
        modified = "WarningMsg",
        inactive_dash = "NonText",
        previous = "WarningMsg",
        label_open = "IncSearch",
        label_delete = "DiagnosticError",
    },
})
```

### Override Built-in Actions

```lua
require("bento").setup({
    actions = {
        open = {
            key = "<C-o>", -- Change from default <CR>
            hl = "String",
            action = function(buf_id, buf_name)
                vim.cmd("buffer " .. buf_id)
                require("bento.ui").collapse_menu()
            end,
        },
    },
})
```

### Custom Action Examples

```lua
actions = {
    -- Git
    git_stage = {
        key = "g",
        action = function(_, buf_name)
            vim.cmd("!git add " .. vim.fn.shellescape(buf_name))
        end,
    },

    -- Copy path
    copy_path = {
        key = "y",
        action = function(_, buf_name)
            vim.fn.setreg("+", buf_name)
        end,
    },

    -- Open in split
    split = {
        key = "s",
        action = function(buf_id)
            vim.cmd("split | buffer " .. buf_id)
        end,
    },
}
```

## Acknowledgments & inspiration

- [buffer-sticks.nvim](https://github.com/ahkohd/buffer-sticks.nvim) by [`ahkohd`](https://github.com/ahkohd): this plugin inspired some of the ideas implemented in `bento` (e.g., the dashed menu). You should also check out this plugin, it's very good and it pursues solutions to many of the same problems.

- [buffer_manager.nvim](https://github.com/j-morano/buffer_manager.nvim) by [`j-morano`](https://github.com/j-morano): I took architectural ideas from this plugin initially, although at this point the differences may be too large to notice.
