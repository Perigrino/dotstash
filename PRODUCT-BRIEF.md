# PRODUCT-BRIEF: Dotstash

**Date:** 2026-08-22
**Status:** Diagnostic complete — recommendation below
**Reviewed:** `src/cli.js`, `lib/dotstash.js` (~330 LOC), `SwiftApp/` scaffold, README

---

## 1. What it is today

A Node CLI that manages dotfiles by copying them into `~/.dotstash/` (manifest:
`dotstash.json`) and symlinking them back into `$HOME`.

| Command | Behavior |
|---|---|
| `add <file>` | Copy file/dir into stash |
| `link [name]` | Symlink stash → home (**destructive**: overwrites target) |
| `list` / `status` | Inventory + health check |
| `remove [-d]` | Untrack, optionally delete stashed copy |

Plus an early SwiftUI app: menu-bar shell, dotfile grid, diff viewer, file watcher.

---

## 2. The Seven Questions

### Who is this for?
Today: you. The CLI re-implements what chezmoi, GNU Stow, yadm, and the bare-git-repo
technique already do — and those are mature, documented, and battle-tested. There is no
segment of developers waiting for a fourth symlink manager CLI.

### What's the pain?
Two real pains exist here, and only one is unserved:

1. **Served pain:** keeping dotfiles consistent across machines. Solved by bare git repo
   (zero tooling), Stow, chezmoi. Building here = competing on parity, not value.
2. **Unserved pain:** *visibility*. Dotfile managers are all CLIs. Nobody has built a
   polished native GUI showing what's tracked, what drifted, and what changed — with
   diffs and live watching. On macOS specifically, this niche is empty.

### Why now?
- You already wrote the hard 20% (SwiftUI views, file watcher, diff viewer scaffold).
- macOS share among devs keeps growing; native Swift quality bar (menu bar, previews)
  is something Electron/cross-platform tools never bothered to hit.
- Nothing about the CLI side is "now" — nothing changed in that market since chezmoi won.

### What's the 10-star version?
"GitHub Desktop for dotfiles": a macOS menu-bar app where every config file is a card;
drift is highlighted live as you edit; tapping a card opens a diff of stash vs. disk;
one click restores or accepts changes; machines sync via a git remote behind the scenes.
Zero terminal knowledge required to have professional-grade dotfile hygiene.

### What's the MVP?
SwiftUI menu-bar app that:
1. Reads/writes the same `~/.dotstash/` layout (backed by a plain git repo instead of raw copies)
2. Shows tracked files + drift status (already scaffolded in `DotfileGridView`)
3. One-click diff → restore or accept (`DiffViewer` already scaffolded)

CLI shrinks to a thin convenience wrapper over the same lib — not the product surface.

### Anti-goals (explicitly NOT building)
- ❌ Template engines, secret encryption, scripting hooks (chezmoi territory)
- ❌ Windows/Linux GUIs (macOS-native or nothing)
- ❌ A better CLI than chezmoi — that war is over
- ❌ Cloud accounts / sync service (plain git remotes are enough)

### How do you know it's working?
- **You use it:** your own dotfiles live in it within 2 weeks (dogfood gate)
- **Drift caught ≥ 1 time** the watcher flags a change you'd otherwise have missed
- If shared publicly: stars are vanity; the metric is *any* non-you commit or issue

---

## 3. Risks

| # | Risk | Severity | Note |
|---|---|---|---|
| 1 | **Data loss in current `link()`** — deletes the on-disk file before symlinking, so edits made after `add` are silently destroyed | 🔴 High | Fix before any use: diff-and-refuse, or auto-re-stash on conflict |
| 2 | No versioning — copy-stash loses history; one bad `remove -d` is unrecoverable | 🔴 High | Replace stash with a git repo; solves sync too |
| 3 | Basename collisions — two dirs both adding `.zshrc` overwrite each other in the flat stash | 🟡 Med | Namespace by source path |
| 4 | Solo-maintainer scope creep: two frontends (CLI + Swift) double the surface | 🟡 Med | Pick Swift as the product; freeze CLI features |
| 5 | Niche may be empty because demand is small, not because nobody tried | 🟡 Unknown | Cheap test: ship MVP, post to r/macapps + HN Show, watch |

## 4. Go / No-Go

> **NO-GO** as a standalone CLI dotfiles manager. The space is saturated; the feature set
> trails free alternatives; risk #1 makes it actively dangerous today.
>
> **CONDITIONAL GO** as a pivot: **native macOS GUI ("GitHub Desktop for dotfiles")**
> backed by a git repo instead of raw copies. That niche is genuinely empty, the hard
> UI work is already scaffolded, and git eliminates risks #1–#3 in one move.

### Recommended sequence
1. Fix `link()` data-loss behavior (refuse on drift unless `--force`) — 1 evening
2. Swap copy-stash for a git-backed store — small refactor of `lib/dotstash.js`
3. Build the Swift MVP against the same store; demote CLI to debug tool
4. Dogfood 2 weeks → decide whether to publish

---

*Generated via product-lens diagnostic. Next lane if proceeding: `product-capability`
to turn the MVP definition into an implementation-ready plan.*
