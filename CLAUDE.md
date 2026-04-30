Skills are organized into bucket folders under `skills/`:

- `engineering/` — daily code work
- `productivity/` — daily non-code workflow tools
- `misc/` — kept around but rarely used
- `personal/` — tied to my own setup, not promoted
- `deprecated/` — no longer used

Every skill in `engineering/`, `productivity/`, or `misc/` must:

- have a reference in the top-level `README.md`
- be listed in its bucket's `<bucket>/.claude-plugin/plugin.json` (the per-category plugin)

Skills in `engineering/` and `productivity/` must additionally be listed in the root `.claude-plugin/plugin.json` (the `mattpocock-skills` plugin used by the npx installer). Skills in `misc/` are deliberately excluded from the root plugin — they're available only via the `misc` plugin in the marketplace.

Skills in `personal/` and `deprecated/` must not appear in any of the above.

The marketplace catalog is defined in `.claude-plugin/marketplace.json` and exposes four plugins: `mattpocock-skills`, `engineering`, `productivity`, `misc`. When adding a new bucket, add an entry to `marketplace.json` and create a `<bucket>/.claude-plugin/plugin.json` for it.

Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.

Each bucket folder has a `README.md` that lists every skill in the bucket with a one-line description, with the skill name linked to its `SKILL.md`.
