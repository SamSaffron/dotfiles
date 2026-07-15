# Quarantined plugin updates

`lazy-lock.json` pins every normal install. Use `scripts/update` instead of
`:Lazy update` when changing those pins.

## Normal updates

The updater records when it first sees each upstream branch tip. A commit may be
promoted only when it was first observed at least seven days ago and is still
reachable at every later observation checkpoint. If an observed commit is not
reachable during a run, its timestamp is discarded; seeing it again starts a
new quarantine. Run the updater daily if daily continuity checks are desired.
This uses local first-seen times because Git commit dates can be backdated.

Run this periodically (weekly is sufficient, daily gives finer-grained updates):

```sh
./scripts/update
```

The updater prints phase changes and per-plugin `[completed/total]` progress as
work finishes. Git fetches/clones run concurrently with up to eight workers by
default. Override this when desired:

```sh
./scripts/update --jobs 12
```

`update` performs four steps:

1. Resolve plugin names and expected remote URLs from lazy.nvim's configuration.
   New plugin repositories are cloned with `--no-checkout`, so no plugin code is
   loaded before approval. Existing `origin` URLs must match the resolved specs.
2. Fetch branch tips and record observations in
   `stdpath("state")/lazy-quarantine.json` with owner-only permissions.
3. Put the newest eligible observations into `lazy-lock.json`, preserving
   lazy.nvim's one-plugin-per-line format.
4. Install missing plugins from their new exact pins and run `:Lazy restore`.
   If applying the pins fails, the updater restores the previous lockfile and
   attempts to restore all previous checkouts before reporting failure.

The first run normally observes commits without promoting them. This is also the
workflow for a newly added plugin spec: automatic startup installation is
disabled, the updater creates a no-checkout clone, and the plugin remains
unavailable until its first pin completes quarantine or passes reviewed mode.

Other useful commands are:

```sh
./scripts/update observe  # fetch and start/refresh quarantine only
./scripts/update promote  # change pins without fetching or syncing
./scripts/update status
```

## Urgent updates

To bypass the waiting period with an AI security review:

```sh
./scripts/update --urgent
```

For each plugin with an update, this first trusts any branch tip that has already
completed quarantine, then pipes the remaining commit list and complete patch
through `term-llm`. In other words, only the portion that bypasses the seven-day
wait requires AI approval. Every reviewed plugin must return a machine-readable
`PASS`; one failure, malformed response, non-fast-forward update, missing
command, oversized review input, timeout, or model error leaves the entire
lockfile unchanged. Review input is limited to 1,000,000 bytes per plugin so a
model cannot silently approve a patch that obviously exceeds the configured
review envelope. If all reviews pass, the updater pins the latest fetched branch
tips and installs/restores only those exact pins.

For a stricter review that walks the complete change from every currently
locked commit to the latest branch tip, regardless of age, use:

```sh
./scripts/update --conservative
```

`--urgent` and `--conservative` are mutually exclusive. Both promote to latest
only when every required review passes; conservative mode simply sends a larger
review scope to `term-llm`. Security reviews run two at a time by default and
report each verdict as it completes. Adjust that independently from Git workers:

```sh
./scripts/update --conservative --review-jobs 4
```

Set `TERM_LLM=/path/to/term-llm` or pass `--term-llm PATH` to select the binary.
Use `--no-sync` to update only the lockfile.

## Preventing accidental bypasses

The Neovim configuration blocks lazy.nvim's mutating discovery paths:

- `:Lazy update`, plus the Lazy UI's `U`/`u` keys
- `:Lazy sync`, plus the Lazy UI's `S` key
- `:Lazy install`, plus the Lazy UI's `I`/`i` keys
- equivalent direct calls through `require("lazy.manage")`

They display a message pointing back to this updater. `:Lazy restore` remains
available because it only applies commits already present in `lazy-lock.json`.
Automatic installation of missing plugins is disabled. The updater's internal
install path is accepted only when every missing plugin already has a lock
entry; a lockfile-mode install without a pin is rejected. `:Lazy check` remains
safe and enabled: it fetches and reports updates but does not check them out or
rewrite the lockfile.

This is a strong guard against mistakes inside Neovim, not a tamper-proof
sandbox. A person or plugin with access to the configuration, lockfile, local
observation state, Git checkouts, or `git`/`term-llm` executables can still
bypass it deliberately. The updater resolves the selected `term-llm` executable
to an absolute path for each reviewed run, but does not authenticate that local
binary.

AI review is defense in depth, not a security boundary. A malicious patch can
attempt prompt injection or conceal behavior across generated/binary content.
Review the resulting lockfile diff before committing it.

## Bootstrap

A new installation clones `lazy.nvim` without checking out its branch tip, then
checks out the exact commit already pinned in `lazy-lock.json`. Bootstrap fails
closed if that pin is unavailable.
