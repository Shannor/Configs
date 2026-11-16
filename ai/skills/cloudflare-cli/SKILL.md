---
name: cloudflare-cli
description: Manage Cloudflare (Workers, KV, D1, R2, DNS, zones, WAF, Access, cache, AI Gateway, etc.) using the `cf` CLI (beta), which covers the entire Cloudflare API. Use when the user asks to deploy, inspect, configure, or debug anything on Cloudflare, or to migrate a Worker from Wrangler.
---

# Cloudflare CLI (`cf`)

`cf` is Cloudflare's agent-first CLI (open beta) covering 3,000+ API operations. It replaces the Cloudflare MCP server. Install: `npm i -g cf` (under the asdf-managed Node, then `asdf reshim nodejs`). Source: https://github.com/cloudflare/cf

## Key behaviors

- **JSON is the default output.** Filter with `jq` instead of parsing tables.
- **Do not guess commands.** There are thousands. Discover them:
  ```bash
  cf cli search "<what you want to do>"   # natural-language command search
  cf <product> --help                      # e.g. cf workers --help
  ```
- Global flags: `-z/--zone <id|domain>`, `--profile <name>`, `-m/--mode <mode>`, `--local`, `-q/--quiet`.
- Prefer `cf` over `wrangler` for new work; `cf` delegates to Wrangler where needed (esbuild, Rust, Python Workers).

## Auth

```bash
cf auth whoami                  # check current login
cf auth login                   # OAuth login (opens browser; ask the user to do this)
cf auth list                    # profiles
cf auth create <name>           # named profile
cf auth activate <name> [dir]   # bind profile to a directory
cf auth scopes [product]        # OAuth scopes granted
```

Use `--profile <name>` when the user has multiple accounts. Never print or store tokens.

## Common tasks

```bash
cf workers list
cf init                 # new project
cf deploy               # deploy (static sites need no config)
cf build                # build for Cloudflare
cf migrate              # convert Wrangler config to cloudflare.config.ts
cf cli search "create kv namespace"
```

## Configuration: `cloudflare.config.ts`

Typed replacement for `wrangler.toml/jsonc`:

```ts
import { bindings, defineConfig, triggers } from "cf/config";
import * as entrypoint from "./index.js" with { type: "cf-worker" };

export default defineConfig(({ mode }) => ({
  worker: {
    name: "example-worker",
    entrypoint,
    compatibilityDate: "2026-09-27",
    env: {
      API_TOKEN: bindings.secret(),
      CACHE: bindings.kv({ id: mode === "production" ? "prod-id" : "staging-id" }),
      DATABASE: bindings.d1({ name: `example-${mode}-database` }),
    },
    triggers: [triggers.fetch({ pattern: "example.com/*" })],
  },
}));
```

- Vary environments with the `mode` argument (`-m/--mode`), not copied `env` blocks.
- Bindings: `text`, `secret`, `kv`, `d1`, `r2`, `queue`, `ai`, `vectorize`, `worker`.
- Triggers: `fetch`, `scheduled`, `queue`, `email`.
- Use the LSP/type-check to validate edits to this file.

## Guidance

- Read-only commands (`list`, `get`) are safe to run freely. Confirm with the user before destructive or billing actions (deletes, purges, domain purchases, DNS/WAF changes, production deploys).
- Keep output small: pipe through `jq` to select only needed fields.
- It is beta; if a command fails unexpectedly, check `cf <cmd> --help` and `cf cli search`, and fall back to `wrangler` if necessary.
