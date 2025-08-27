# Repository Guidelines

## Project Structure & Module Organization
- `init.lua`: Entry point; sets globals and loads `config.lazy` (bootstraps lazy.nvim).
- `lua/config/`: Core setup — `options.lua`, `keymaps.lua`, `autocmds.lua`, and `lazy.lua` (plugin manager config).
- `lua/plugins/`: Topical plugin specs returning tables (e.g., `ui.lua`, `tools.lua`, `coding.lua`, `ai.lua`).
- `data/`: Extra runtime data and filetype tweaks (e.g., `plenary/filetypes/gjs.lua`).
- `lazy-lock.json`: Pinned plugin versions — commit intentional updates only.

## Build, Test, and Development Commands
- Install/sync plugins: `:Lazy sync` (uses `lazy-lock.json`).
- Check plugin health: `:Lazy check` and `:checkhealth`.
- Headless sanity check: `nvim --headless -u ./init.lua '+qa'` (should exit cleanly).
- Format current buffer: `:lua require("conform").format({ async = true })`.

## Coding Style & Naming Conventions
- Lua: 2‑space indent, no tabs; prefer `vim.opt`, `vim.api`, and table‑scoped locals over globals.
- New config belongs in `lua/config/*.lua`; keep files focused and small.
- New plugins: add a spec in `lua/plugins/<area>.lua` returning a list of plugin tables.
- Keymaps: use `desc` for discoverability (works with which‑key); avoid surprising global side effects.
- Keep names descriptive; group related plugins (e.g., UI, tools, coding, AI).

## Testing Guidelines
- Startup: `nvim --clean -u ./init.lua` loads without errors.
- After plugin edits: run `:Lazy sync` and `:checkhealth`.
- LSP/formatting: open a representative file (Lua, Ruby, JS) and verify diagnostics and formatting via Conform.

## Commit & Pull Request Guidelines
- Commits: imperative, concise; prefix scope when useful.
  - Examples: `plugins: add telescope fzf`, `config: tweak keymaps`, `ui: adjust lualine`.
- PRs: include a short summary, before/after notes (screenshots if UI‑adjacent), and call out any machine‑specific assumptions.
- Update `lazy-lock.json` only when intentionally bumping or pinning versions.
- Stage‑only workflow: do not create commits in this repo. Stage changes with `git add -A` and place a draft commit message (prefixed `DRAFT:`) in the PR description or comment. Do not run `git commit` unless explicitly requested.
  - Examples: `DRAFT: plugins: add telescope fzf`, `DRAFT: config: adjust keymaps`.

## Pull Request Checklist
- Staging only: changes are staged (`git add -A`); no local commits created.
- Draft message: PR description starts with `DRAFT: <scope>: <change>`.
- Linked issues: include `Fixes #<id>` or `Refs #<id>` when relevant.
- Validation: ran `:Lazy sync`, `:checkhealth`, and `nvim --headless -u ./init.lua '+qa'`.
- UI changes: include before/after screenshots or GIFs.
- Machine‑specific notes: call out any paths, env vars, or external tools.

## Security & Configuration Tips
- Avoid hardcoded absolute paths. Guard machine‑specific bits (e.g., `/home/sam/Source/discourse`) behind checks or make them configurable.
- Prefer lazy‑loading for experimental plugins; keep defaults stable and fast.
