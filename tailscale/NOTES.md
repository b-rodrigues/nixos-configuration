# Tailscale lockdown — notes

Final policy: `tailscale/policy.hujson` (fetched live 2026-10-25, ETag `df438d...`).
Default allow-all `* -> * : *` is gone. Deny-by-default.

## Devices (all yours, no shared, no stale at lockdown)

- `nixos-desktop` = `100.119.230.8` (desktop, agent-runner) → `tag:agent`
- `macbook` = `100.123.69.62` (Asahi laptop, personal, untagged)
- `pixel-8` = `100.102.86.44` (phone, personal, untagged)

No exit nodes / subnet routers (`enabledRoutes=[]`). Funnel off
(`tailscale serve/funnel status` = `No serve config` on nixos + macbook).

## Tags and ports

- `tag:agent` (only `nixos-desktop`):
  - Inbound: TCP `22` only from `autogroup:member` (laptop/phone).
    SSH itself is Tailscale SSH (`RunSSH=true` on nixos), so needs
    BOTH grants `:22` + `ssh accept member -> tag:agent`.
  - Outbound: `autogroup:internet:*` only. Cannot initiate to
    laptop/phone/desktop (deny tests prove it).
  - Exposes nothing else on tailnet. `llama-server :8080/:8081` bind
    `127.0.0.1` only + currently inactive. `sunshine` enabled in NixOS
    config but no unit found — not listening.

- Untagged personal (`macbook`, `pixel-8`):
  - `member -> macbook:*` + `member -> pixel-8:*` = full mesh among personal.
    This is what lets `phone -> macbook` work.
  - `member -> nixos-desktop:22` = SSH to server.
  - New phones/laptops are NOT automatic: add their `100.x` to `hosts`
    + one `member -> new-host:*` grant + update `tests` accept/deny.
    They can SSH out immediately (they are `member` as source),
    but others can't reach them until you add the grant.

## Debugging rule

If SSH/services fail, check policy BEFORE the server:

1. `tailscale status` — is the IP/tag what `hosts` says?
2. `GET /api/v2/tailnet/-/devices?fields=all` — tags present?
3. `POST .../acl/validate` — do `tests` still pass?
4. Then `ss -tlnp` / `tailscale debug prefs` (RunSSH) on the box.

Untagging `nixos` does NOT restore old allow-all — it just makes it
`member` again (can initiate to personal again, inbound still `:22` only).
Full rollback = re-apply the pre-lockdown allow-all file.
