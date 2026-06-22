# dv term-llm hub hook scripts

This directory contains a host-side `post-create` hook and helper scripts for making each new dv container show up in the central term-llm hub.

## Files

- `post-create` — dv creation hook entrypoint. Resolves `DV_CONTAINER_NAME`, syncs config, installs service.
- `post-remove` — dv removal hook entrypoint. Deregisters the removed container from the hub.
- `sync-term-llm-config` — copies `~/.config/term-llm` into the container as `/home/discourse/.config/term-llm`, excluding bulky runtime state like projects/containers/images.
- `install-term-llm-hub-service` — copies a hub-capable `term-llm` binary into the container and installs an in-container runit service at `/etc/service/term-llm-hub/run`.
- `hub-registration-token` — resolves the Hub registration token from env or `op-cache`.
- `discourse-developer/` — the term-llm agent definition copied into each container.

Keeping `discourse-developer/agent.yaml` and `discourse-developer/system.md` as normal files here makes the agent easy to review and edit without digging through shell heredocs.

## Token lookup

The hooks resolve the Hub registration token in this order:

1. `HUB_REGISTRATION_TOKEN`
2. `TERM_LLM_HUB_REGISTRATION_TOKEN`
3. `op-cache read "$TERM_LLM_HUB_REGISTRATION_TOKEN_OP"`

Copy `.env.example` to `.env` and set your private values:

```bash
cp .env.example .env
$EDITOR .env
```

`.env` is ignored by git.

## Debug output

Successful hooks are quiet by default. To see copy/service/deregistration details, set one of:

```bash
export DV_HOOK_DEBUG=1
# or
export TERM_LLM_HOOK_DEBUG=1
```

`DV_VERBOSE=1` also enables hook debug logging.

## dv config

`~/.config/dv/config.json` should have both hooks:

```json
"hooks": {
  "postCreate": [
    { "command": "$HOME/.config/dv/hooks/post-create \"$@\"" }
  ],
  "postRemove": [
    {
      "command": "$HOME/.config/dv/hooks/post-remove \"$@\"",
      "timeoutSeconds": 30,
      "ignoreErrors": true
    }
  ]
}
```

`postRemove` requires a dv build with removal hook support. Semantics:

- `preRemove` runs after confirmation but before Docker removal, for hooks that need the still-existing/running container.
- `postRemove` runs after Docker removal, image/config/proxy cleanup, and just before `Removal complete`.

This scaffold uses `postRemove` because hub deregistration does not need access to the container.

## Manual test

Create/register:

```bash
./post-create my-dv-container
```

Deregister:

```bash
./post-remove my-dv-container
```

Then inspect:

```bash
docker exec my-dv-container sv status term-llm-hub
docker exec my-dv-container ps aux | grep '[t]erm-llm serve web'
docker exec my-dv-container ls -la /home/discourse/.config/term-llm/agents/discourse-developer
```

## Service behavior

The service runs from `/var/www/discourse` and starts:

```bash
term-llm serve web \
  --agent discourse-developer \
  --yolo \
  --hub-url "$TERM_LLM_HUB_URL" \
  --hub-connect reverse \
  --hub-register
```

Node identity defaults to:

- `NODE_ID=<container>`
- `NODE_NAME=<container>`

The node token is generated once and persisted in `/etc/term-llm-hub.env` inside the container.
