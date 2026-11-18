# BloxBot

Client-side Luau bundle for Blox League / Turbo Soccer. One paste, one
loadstring, works on Delta PC and Delta mobile.

## Loader

    loadstring(game:HttpGet("https://pastebin.com/raw/CGr0jphx"))()

**Delta PC:** attach → join match → paste the loader line → window opens → MODELS tab renders.

**Delta mobile:** attach → join match → paste the loader line → window opens (auto-fit ≤92% w/h) → MODELS tab renders. Close → 48px round reopen button on the right edge.

First run: CONFIG → compat check.

## Executor support matrix

| Executor    | PC | Mobile | Notes |
|-------------|----|--------|-------|
| Delta       | ✓  | ✓      | Primary target. |
| Wave        | ✓  | —      | |
| Synapse X   | ✓  | —      | |
| Fluxus      | ✓  | ✓      | Mobile lacks Drawing → native UI |
| Solara      | ✓  | —      | |
| AWP         | ✓  | —      | |
| Codex       | ✓  | ✓      | Mobile lacks Drawing → native UI |
| Hydrogen    | ✓  | ✓      | Session-only config on mobile |
| Arceus X    | —  | ✓      | No Drawing → native UI path |
| Electron    | ✓  | —      | |
| Swift       | ✓  | —      | |

## Hotkeys (desktop)

| Key          | Action |
|--------------|--------|
| RightShift   | Toggle window |
| RightControl | Pause / resume |
| F1…F12       | Quick-switch model |
| End          | Panic — stop, hide UI, disconnect |

## Config keys

| Key               | Type    | Default | Notes |
|-------------------|---------|---------|-------|
| ui_lib            | string  | native  | wired backend |
| theme             | string  | dark    | dark \| light |
| force_device      | string  | auto    | auto \| pc \| mobile |
| frame_budget_ms   | number  | nil     | nil → 1.0 PC / 2.0 mobile |
| active_model      | string  | botimus_crime | |
| active_mode       | string  | 1v1     | |
| humanize_enabled  | bool    | true    | |
| humanize_jitter   | number  | 0.15    | |
| humanize_delay_ms | number  | 25      | |
| ui_bounds         | table   | {100,100,620,460} | persisted on drag end |
| backend           | string  | auto    | auto \| virtual_user \| mouse \| touch |
| webhook_url       | string  | ""      | optional |
| log_level         | string  | info    | debug \| info \| warn \| error |

## Failure table

| Symptom | Likely cause | First move |
|---|---|---|
| script errors on load | missing global / wrong namespace | run compat check, switch executor |
| UI blank | Fluent/Rayfield/Kavo missing | native path auto-takes; check feature log |
| UI vanishes after a few seconds | CoreGui sweep | ensure gethui/protectgui path taken |
| reader returns nil | wrong instance path or experience updated | re-check constants, dump workspace |
| model ticks, no motion | no input backend | run compat check, switch backend in INPUT tab |
| config doesn't persist | writefile missing | session-only fallback, note in CONFIG tab |
| mobile frames drop | budget too high | lower frame_budget_ms, close other apps |
| touch tap misses | target <44px | native UI path guarantees 44px |
| shutdown leaves handles | teardown order | disconnect → destroy UI → exit |

## Instance-path updates

When GAME tab shows `MISSING ball|char|arena`:

1. Find the `game/constants.lua` block in the ROOT carrier.
2. Update `ball.name`, `arenas.folder`, `teams.red/blue`.
3. Re-run the loader — constants reload fresh each boot.