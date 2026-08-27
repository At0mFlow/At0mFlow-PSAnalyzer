# Public repository boundary

Use Australian English. Write clearly, naturally and concisely. Never use em
dashes.

This repository is public and contains only the standalone At0mFlow PSAnalyzer
wrapper, its tests, synthetic examples, documentation and brand assets.

## Non-negotiable separation rules

- Never copy code, prompts, rules, configuration, schemas, data or assets from
  the At0mFlow product repository into this repository, except approved public
  brand assets.
- Never add At0mFlow scoring, AI analysis, code rewriting, cleanup, migration,
  backend, authentication, billing, tracking or customer-data logic.
- Never stage files from outside this repository.
- Keep `origin` pointed only to
  `https://github.com/At0mFlow/At0mFlow-PSAnalyzer.git` or its equivalent
  GitHub SSH URL.
- Use synthetic examples and fixtures only.
- Keep the README's `Other public At0mFlow tools` section current. It must link
  every other public At0mFlow tool and must not link this repository to itself.
- Before every commit and push, run `./scripts/Test-PublicBoundary.ps1` and
  `./tests/Run-Tests.ps1`.
- Stop if the boundary check fails. Do not bypass or weaken it to make a commit
  pass without reviewing the flagged content.
