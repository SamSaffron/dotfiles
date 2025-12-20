#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "time"

TITLE = "Hyprland Shortcuts"
APP_ID = ENV.fetch("HYPR_HELP_APP_ID", "io.hypr.help")

DEFAULT_CFG = File.join(ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config")), "hypr", "hyprland.conf")
cfg_env = ENV["HYPR_HELP_CONFIG"].to_s
CFG = cfg_env.empty? ? DEFAULT_CFG : cfg_env

TYPE_TITLES = {
  "bind" => "Keyboard",
  "bindm" => "Mouse",
  "bindel" => "Key (repeat)",
  "bindl" => "Key (lockscreen)",
}.freeze

def die(message)
  warn("hypr-help: #{message}")
  exit(1)
end

def command_exists?(command)
  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
    path = File.join(dir, command)
    File.file?(path) && File.executable?(path)
  end
end

def toggle_existing(class_name, title)
  output = `hyprctl clients -j 2>/dev/null`
  return false if output.to_s.strip.empty?

  clients = JSON.parse(output)
  addrs = clients.filter_map do |client|
    next unless client["class"] == class_name || client["title"] == title
    client["address"]
  end
  return false if addrs.empty?

  addrs.each do |addr|
    system("hyprctl", "dispatch", "closewindow", "address:#{addr}", out: File::NULL, err: File::NULL)
  end

  true
rescue JSON::ParserError
  false
end

def pretty_key(key)
  key_map = {
    "return" => "Enter",
    "escape" => "Escape",
    "space" => "Space",
    "left" => "Left",
    "right" => "Right",
    "up" => "Up",
    "down" => "Down",
    "Print" => "PrintScreen",
    "mouse_down" => "ScrollDown",
    "mouse_up" => "ScrollUp",
    "mouse:272" => "MouseLeft",
    "mouse:273" => "MouseRight",
    "XF86AudioRaiseVolume" => "VolumeUp",
    "XF86AudioLowerVolume" => "VolumeDown",
    "XF86AudioMute" => "Mute",
    "XF86AudioMicMute" => "MicMute",
    "XF86MonBrightnessUp" => "BrightnessUp",
    "XF86MonBrightnessDown" => "BrightnessDown",
  }

  key_map.fetch(key, key)
end

def pretty_mod(mod)
  mod_map = {
    "SUPER" => "Super",
    "SHIFT" => "Shift",
    "CTRL" => "Ctrl",
    "ALT" => "Alt",
  }

  mod_map.fetch(mod, mod)
end

def parse_binds(cfg_path)
  var_re = /^\s*(\$\w+)\s*=\s*(.*?)\s*$/
  bind_re = /^\s*(bindm|bindl|bindel|bind)\s*=\s*(.*?)\s*$/

  vars = {}
  binds = []

  File.foreach(cfg_path, mode: "r:UTF-8", invalid: :replace, undef: :replace) do |raw|
    line = raw.chomp
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?("#")

    code, comment = line.split("#", 2)
    code = code.rstrip
    desc = comment ? comment.strip : ""

    if (m = code.match(var_re))
      vars[m[1]] = m[2].strip
      next
    end

    m = code.match(bind_re)
    next unless m

    bind_type = m[1]
    rhs = m[2]
    rhs = rhs.gsub(/\$\w+/) { |name| vars.fetch(name, name) }
    parts = rhs.split(",").map(&:strip)
    next if parts.length < 3

    mods = parts[0]
    key = parts[1]
    action = parts[2]
    arg = parts[3..].to_a.join(",").strip

    mods_pretty = if mods.to_s.strip.empty?
      ""
    else
      mods.split.map { |mod| pretty_mod(mod) }.join("+")
    end

    key_pretty = pretty_key(key)
    combo = mods_pretty.empty? ? key_pretty : "#{mods_pretty}+#{key_pretty}"

    binds << {
      type: bind_type,
      key: combo,
      action: action,
      arg: arg,
      desc: desc,
    }
  end

  type_order = { "bind" => 0, "bindm" => 1, "bindel" => 2, "bindl" => 3 }
  binds.sort_by { |b| [type_order.fetch(b[:type], 99), b[:key].downcase, b[:action], b[:arg]] }
end

def clear_list(list)
  child = list.first_child
  while child
    next_child = child.next_sibling
    if list.respond_to?(:remove)
      list.remove(child)
    else
      child.unparent
    end
    child = next_child
  end
end

def build_header(size_groups)
  header = Gtk::Box.new(:horizontal, 18)
  header.add_css_class("table-header")
  header.set_margin_start(12)
  header.set_margin_end(12)
  header.set_margin_top(6)
  header.set_margin_bottom(6)

  labels = [
    ["Type", :type],
    ["Key", :key],
    ["Action", :action],
    ["Arg", :arg],
    ["Notes", :notes],
  ]

  labels.each do |text, key|
    label = Gtk::Label.new(text)
    label.add_css_class("header-label")
    label.set_xalign(0.0)
    label.set_halign(:start)

    if key == :notes
      label.set_hexpand(true)
      label.set_halign(:fill)
    else
      size_groups.fetch(key).add_widget(label)
    end

    header.append(label)
  end

  header
end

def build_row(bind, index, size_groups)
  row = Gtk::ListBoxRow.new
  row.add_css_class("list-row")
  row.add_css_class(index.even? ? "row-even" : "row-odd")
  row.set_margin_start(6)
  row.set_margin_end(6)
  row.set_margin_top(4)
  row.set_margin_bottom(4)
  row.selectable = false if row.respond_to?(:selectable=)

  box = Gtk::Box.new(:horizontal, 18)
  box.set_margin_start(10)
  box.set_margin_end(10)
  box.set_margin_top(6)
  box.set_margin_bottom(6)
  row.set_child(box)

  type_label = Gtk::Label.new(bind[:type_title])
  type_label.set_xalign(0.0)
  type_label.set_halign(:start)
  size_groups.fetch(:type).add_widget(type_label)
  box.append(type_label)

  key_label = Gtk::Label.new(bind[:key])
  key_label.set_xalign(0.0)
  key_label.set_halign(:start)
  key_label.add_css_class("mono")
  size_groups.fetch(:key).add_widget(key_label)
  box.append(key_label)

  action_label = Gtk::Label.new(bind[:action])
  action_label.set_xalign(0.0)
  action_label.set_halign(:start)
  size_groups.fetch(:action).add_widget(action_label)
  box.append(action_label)

  arg_label = Gtk::Label.new(bind[:arg])
  arg_label.set_xalign(0.0)
  arg_label.set_halign(:start)
  size_groups.fetch(:arg).add_widget(arg_label)
  box.append(arg_label)

  notes_label = Gtk::Label.new(bind[:desc])
  notes_label.set_xalign(0.0)
  notes_label.set_halign(:fill)
  notes_label.set_hexpand(true)
  notes_label.set_wrap(true)
  notes_label.wrap_mode = :word_char
  notes_label.add_css_class("notes")
  box.append(notes_label)

  row
end

command_exists?("hyprctl") || die("hyprctl not found")
File.readable?(CFG) || die("cannot read #{CFG}")

exit(0) if toggle_existing(APP_ID, TITLE)

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "gtk4", "~> 4.0"
end

require "gtk4"

binds = parse_binds(CFG)
binds.each do |bind|
  type_title = TYPE_TITLES.fetch(bind[:type], bind[:type])
  bind[:type_title] = type_title
  bind[:search] = [type_title, bind[:key], bind[:action], bind[:arg], bind[:desc]].join(" ").downcase
end

timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")

css = <<~CSS
  * {
    font-family: "Iosevka Aile", "Fira Sans", "Noto Sans", "Cantarell", sans-serif;
  }

  .root {
    background-image: linear-gradient(135deg, #f7f1e3 0%, #eef6ff 55%, #fdf2f2 100%);
    color: #1f2937;
  }

  .title {
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 0.4px;
  }

  .muted {
    color: #6b7280;
  }

  .tip {
    color: #374151;
    font-weight: 600;
  }

  .card {
    background-color: rgba(255, 255, 255, 0.9);
    border: 1px solid rgba(0, 0, 0, 0.08);
    border-radius: 16px;
    padding: 6px;
  }

  .table-header label {
    color: #111827;
    font-weight: 600;
  }

  .list {
    background-color: transparent;
  }

  .list-row {
    border-radius: 10px;
  }

  .row-even {
    background-color: rgba(255, 255, 255, 0.7);
  }

  .row-odd {
    background-color: rgba(241, 245, 249, 0.9);
  }

  .mono {
    font-family: "Iosevka Term", "JetBrains Mono", "Fira Code", monospace;
  }

  .notes {
    color: #374151;
  }

  entry.search {
    border-radius: 999px;
    padding: 6px 12px;
    background-color: rgba(255, 255, 255, 0.95);
  }
CSS

app = Gtk::Application.new(APP_ID, :flags_none)
app.signal_connect("activate") do |application|
  provider = Gtk::CssProvider.new
  provider.load(data: css)
  Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, Gtk::StyleProvider::PRIORITY_APPLICATION)

  window = Gtk::ApplicationWindow.new(application)
  window.title = TITLE
  window.set_default_size(980, 680)

  controller = Gtk::EventControllerKey.new
  controller.propagation_phase = :capture if controller.respond_to?(:propagation_phase=)
  controller.signal_connect("key-pressed") do |_controller, keyval, _keycode, _state|
    if keyval == Gdk::Keyval::KEY_Escape
      window.close
      true
    else
      false
    end
  end
  window.add_controller(controller)

  shortcut_controller = Gtk::ShortcutController.new
  shortcut_controller.set_scope(:global) if shortcut_controller.respond_to?(:set_scope)
  trigger = Gtk::KeyvalTrigger.new(Gdk::Keyval::KEY_Escape, 0)
  shortcut_controller.add_shortcut(
    Gtk::Shortcut.new(
      trigger,
      Gtk::CallbackAction.new { window.close; true }
    )
  )
  window.add_controller(shortcut_controller)

  root = Gtk::Box.new(:vertical, 12)
  root.add_css_class("root")
  root.set_margin_top(16)
  root.set_margin_bottom(16)
  root.set_margin_start(16)
  root.set_margin_end(16)
  root.set_hexpand(true)
  root.set_vexpand(true)

  header = Gtk::Box.new(:horizontal, 18)
  header.set_hexpand(true)

  left = Gtk::Box.new(:vertical, 4)
  left.set_hexpand(true)

  title_label = Gtk::Label.new(TITLE)
  title_label.add_css_class("title")
  title_label.set_xalign(0.0)

  subtitle = Gtk::Label.new("Shortcuts from #{CFG}")
  subtitle.add_css_class("muted")
  subtitle.set_xalign(0.0)

  meta = Gtk::Label.new("Generated on #{timestamp}")
  meta.add_css_class("muted")
  meta.set_xalign(0.0)

  tip = Gtk::Label.new("Tip: press Esc to close")
  tip.add_css_class("tip")
  tip.set_xalign(0.0)

  count_label = Gtk::Label.new("")
  count_label.add_css_class("muted")
  count_label.set_xalign(0.0)

  left.append(title_label)
  left.append(subtitle)
  left.append(meta)
  left.append(tip)
  left.append(count_label)

  right = Gtk::Box.new(:vertical, 4)
  right.set_halign(:end)

  search_label = Gtk::Label.new("Filter")
  search_label.add_css_class("muted")
  search_label.set_xalign(0.0)

  search = Gtk::SearchEntry.new
  search.add_css_class("search")
  search.placeholder_text = "Key, action, arg, notes"
  if search.respond_to?(:add_controller)
    search_controller = Gtk::EventControllerKey.new
    search_controller.propagation_phase = :capture if search_controller.respond_to?(:propagation_phase=)
    search_controller.signal_connect("key-pressed") do |_ctrl, keyval, _keycode, _state|
      if keyval == Gdk::Keyval::KEY_Escape
        window.close
        true
      else
        false
      end
    end
    search.add_controller(search_controller)
  end

  right.append(search_label)
  right.append(search)

  header.append(left)
  header.append(right)

  card = Gtk::Box.new(:vertical, 6)
  card.add_css_class("card")
  card.set_hexpand(true)
  card.set_vexpand(true)

  size_groups = {
    type: Gtk::SizeGroup.new(:horizontal),
    key: Gtk::SizeGroup.new(:horizontal),
    action: Gtk::SizeGroup.new(:horizontal),
    arg: Gtk::SizeGroup.new(:horizontal),
  }

  card.append(build_header(size_groups))

  scroller = Gtk::ScrolledWindow.new
  scroller.set_policy(:automatic, :automatic)
  scroller.set_hexpand(true)
  scroller.set_vexpand(true)

  list = Gtk::ListBox.new
  list.add_css_class("list")
  list.selection_mode = :none
  list.set_hexpand(true)
  list.set_vexpand(true)

  scroller.set_child(list)
  card.append(scroller)

  render_rows = lambda do |rows|
    clear_list(list)
    rows.each_with_index do |bind, index|
      list.append(build_row(bind, index, size_groups))
    end
    count_label.label = "Showing #{rows.size} of #{binds.size} shortcuts"
  end

  search.signal_connect("search-changed") do
    query = search.text.to_s.downcase.strip
    filtered = query.empty? ? binds : binds.select { |bind| bind[:search].include?(query) }
    render_rows.call(filtered)
  end

  render_rows.call(binds)

  root.append(header)
  root.append(card)
  window.set_child(root)
  window.present
end

app.run
