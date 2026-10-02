# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`docs/GLOSSARY.md`**: this repo's domain vocabulary. It is the single source of truth for names — note its anti-terms section, which lists the words this project deliberately avoids.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. They are numbered and immutable; supersede rather than edit.
- **`docs/CONVENTIONS.md`**: the layout and naming contract (layer folders, class naming, dependency rules, where tests live). It outranks ticket prose.
- **`docs/design/`**: the referenced specs. `docs/design/index.md` is the entry point; each ticket cites the specific file(s) it belongs to.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo (this one):

```
/
├── AGENTS.md
├── docs/
│   ├── GLOSSARY.md
│   ├── CONVENTIONS.md
│   ├── TESTING.md
│   ├── adr/
│   │   ├── 0001-one-way-dependency-rule.md
│   │   └── ...
│   ├── agents/                  ← this skill's config
│   └── design/                  ← the specs issues cite
├── domain/                      ← the five layers sit at the repo root
├── application/
├── presentation/
├── infrastructure/
├── editor/
└── tests/
```

There is no `GLOSSARY-MAP.md`, so there is no multi-context routing: one glossary, one ADR log.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `docs/GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids — this repo ports a known codebase, so the anti-terms section carries real meaning (e.g. a downed player is *down*, never *dead*; the players are *brothers*).

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0001 (one-way dependency rule), but worth reopening because…_