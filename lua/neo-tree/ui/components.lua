-- This file contains the built-in components. Each componment is a function 
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

local highlights = require("neo-tree.ui.highlights")

local M = {}

M.clipboard = function(config, node, state)
    local clipboard = state.clipboard or {}
    local clipboard_state = clipboard[node:get_id()]
    if not clipboard_state then
        return {}
    end
    return {
        text = " (".. clipboard_state.action .. ")",
        highlight = config.highlight or "Comment"
    }
end

M.current_filter = function(config, node, state)
    local filter = node.search_pattern or ""
    if filter == "" then
        return {}
    end
    return {
        {
            text = 'Find ',
            highlight = "Comment"
        },
        {
            text = string.format('"%s"', filter),
            highlight = config.highlight or highlights.FILE_NAME
        },
        {
            text = " in ",
            highlight = "Comment"
        },
    }
end

M.git_status = function(config, node, state)
    local git_status_lookup = state.git_status_lookup
    if not git_status_lookup then
        return {}
    end
    local git_status = git_status_lookup[node.path]
    if not git_status then
        return {}
    end

    local highlight = "Comment"
    if git_status:match("M") then
        highlight = highlights.GIT_MODIFIED
    elseif git_status:match("[ACR]") then
        highlight = highlights.GIT_ADDED
    end

    return {
        text = " [" .. git_status .. "]",
        highlight = highlight
    }
end

M.icon = function(config, node, state)
    local icon = config.default or " "
    local padding = config.padding or " "
    local highlight = config.highlight or highlights.FILE_ICON
    if node.type == "directory" then
        highlight = highlights.DIRECTORY_ICON
        if node:is_expanded() then
            icon = config.folder_open or "-"
        else
            icon = config.folder_closed or "+"
        end
    elseif node.type == "file" then
        local success, web_devicons = pcall(require, 'nvim-web-devicons')
        if success then
            local devicon, hl = web_devicons.get_icon(node.name, node.ext)
            icon = devicon or icon
            highlight = hl or highlight
        end
    end
    return {
        text = icon .. padding,
        highlight = highlight
    }
end

M.name = function(config, node, state)
    local highlight = config.highlight or highlights.FILE_NAME
    if node.type == "directory" then
        highlight = highlights.DIRECTORY_NAME
    end
    if node:get_depth() == 1 then
        highlight = highlights.ROOT_NAME
    else
        local git_status = state.components.git_status(config, node, state)
        if git_status and git_status.highlight then
            highlight = git_status.highlight
        end
    end
    return {
        text = node.name,
        highlight = highlight
    }
end

return M
