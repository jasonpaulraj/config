local wezterm = require 'wezterm'

return {
    -- Set default home directory
    default_cwd = "E:\\WebDevelopment\\projects",

    -- Set default color scheme
    color_scheme = "OneDark",

    -- Font configuration
    -- font = wezterm.font("Fira Code", {
    --     weight = "Regular"
    -- }),
    font_size = 12,

    -- Window settings
    initial_cols = 120,
    initial_rows = 40,
    window_padding = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5
    },

    -- Tab bar configuration
    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,
    use_fancy_tab_bar = false,

    -- Key bindings
    keys = {{
        key = "t",
        mods = "CTRL|SHIFT",
        action = wezterm.action {
            SpawnTab = "CurrentPaneDomain"
        }
    }, {
        key = "w",
        mods = "CTRL|SHIFT",
        action = wezterm.action {
            CloseCurrentTab = {
                confirm = true
            }
        }
    }, {
        key = "1",
        mods = "CTRL",
        action = wezterm.action {
            ActivateTab = 0
        }
    }, {
        key = "2",
        mods = "CTRL",
        action = wezterm.action {
            ActivateTab = 1
        }
    }, {
        key = "3",
        mods = "CTRL",
        action = wezterm.action {
            ActivateTab = 2
        }
    }, {
        key = "v",
        mods = "CTRL|SHIFT",
        action = wezterm.action {
            PasteFrom = "Clipboard"
        }
    }, {
        key = "c",
        mods = "CTRL|SHIFT",
        action = wezterm.action {
            CopyTo = "Clipboard"
        }
    }},

    -- Mouse bindings
    mouse_bindings = {{
        event = {
            Down = {
                streak = 1,
                button = "Right"
            }
        },
        mods = "NONE",
        action = wezterm.action {
            PasteFrom = "Clipboard"
        }
    }},

    -- Additional settings for development
    enable_scroll_bar = true,
    scrollback_lines = 10000,
    adjust_window_size_when_changing_font_size = false,
    default_prog = {"cmd.exe"} -- Default shell
}
