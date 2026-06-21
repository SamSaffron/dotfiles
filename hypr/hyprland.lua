-- Hyprland Lua config.
-- Ported from hyprland.conf for Hyprland >= 0.55.
-- See https://wiki.hypr.land/Configuring/Start/

----------------
--- MONITORS ---
----------------

hl.monitor({ output = "DP-1", mode = "highrr", position = "auto", scale = 1.6 })

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    debug = {
        disable_logs = false,
    },
})

-------------------
--- MY PROGRAMS ---
-------------------

local terminal    = "~/.config/hypr/terminal.sh"
local fileManager = "dolphin"
local menu        = "fuzzel"

-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("1password --silent")
    hl.exec_cmd("env QT_QPA_PLATFORM=xcb copyq")
    hl.exec_cmd("telegram-desktop -startintray")
    hl.exec_cmd("slack -u")
    hl.exec_cmd("signal-desktop --start-in-tray")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("opendeck --hide")

    -- jarvis-browser-proxy systemd env
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE")
end)

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("QT_ENABLE_HIGHDPI_SCALING", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("NVD_BACKEND", "direct")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

---------------------
--- LOOK AND FEEL ---
---------------------

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 4,
        border_size = 1,
        col = {
            active_border = "rgba(505050aa)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "master",
    },

    decoration = {
        rounding = 2,
        rounding_power = 4,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint",   style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",         style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",         style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear",   style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "slave",
        orientation = "center",
        mfact = 0.4,
        slave_count_for_center_master = 0,
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    plugin = {
        hyprbars = {
            bar_height = 26,
            bar_text_size = 11,
            bar_text_font = "SFMono Nerd Font Mono",
            bar_text_align = "left",
            bar_padding = 8,
            bar_button_padding = 6,
            bar_precedence_over_border = false,
            bar_part_of_window = true,
            bar_color = "rgba(1d2021ff)",
            col = {
                text = "rgba(a89984ff)",
            },
        },
    },
})

hl.plugin.hyprbars.add_button({
    bg_color = "rgba(665c54ff)",
    fg_color = "rgba(a89984ff)",
    size = 12,
    icon = "󰅖",
    action = "hyprctl dispatch killactive",
})

-------------
--- INPUT ---
-------------

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:swapescape",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("~/.config/hypr/exit.sh"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/toggle-master-layout.sh"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("swapnext"))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.layout("swapprev"))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("Print",          hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("SHIFT + Print",  hl.dsp.exec_cmd("~/.config/hypr/countdown 3 && hyprshot -z -m region --clipboard-only"))
hl.bind("CTRL + Print",   hl.dsp.exec_cmd("hyprshot -z -m output -m DP-1 --clipboard-only"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("wl-paste --type image/png --no-newline | swappy -f -"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/hypr/screen-record.sh"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("~/.config/hypr/help.sh"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                    { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

local floating_classes = {
    "kruler",
    "org.kde.kolourpaint",
    "pavucontrol",
    "simplescreenrecorder",
    "1Password",
    "slack",
    "TelegramDesktop",
    "Git-gui",
    "gitg",
    "org.gnome.gitg",
    "org.ksnip.ksnip",
    "org.hyprland.xdg-desktop-portal-hyprland",
    "xdg-desktop-portal-gtk",
}

for _, class in ipairs(floating_classes) do
    hl.window_rule({ match = { class = class }, float = true })
end

hl.window_rule({ match = { title = "(Terminator Preferences)" }, float = true })

-- Floating help popup (kitty --class hypr-help)
hl.window_rule({ match = { class = "io.hypr.help" }, float = true })
hl.window_rule({ match = { class = "io.hypr.help" }, center = true })
hl.window_rule({ match = { class = "io.hypr.help" }, size = { 980, 680 } })
hl.window_rule({ match = { class = "io.hypr.help" }, border_size = 0 })

hl.window_rule({ match = { class = ".*" }, ["hyprbars:no_bar"] = true })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, ["hyprbars:no_bar"] = false })
hl.window_rule({ match = { class = "kitty" }, ["hyprbars:no_bar"] = false })

hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
