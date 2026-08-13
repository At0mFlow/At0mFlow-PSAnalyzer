# Public repository boundary

At0mFlow PSAnalyzer is intentionally separate from the At0mFlow product. This
repository may contain only:

- the open PSScriptAnalyzer wrapper in `src`;
- synthetic examples and tests;
- public documentation and repository configuration;
- approved At0mFlow and Orbit brand assets.

It must not contain product code, prompts, scoring rules, cleanup or migration
logic, backend or API code, application configuration, credentials, customer
data, database files or production assets.

## Automated controls

`scripts/Test-PublicBoundary.ps1` checks the repository for:

- unexpected top-level paths;
- source types that do not belong in this PowerShell-only tool;
- common At0mFlow product paths and private configuration files;
- private keys and recognisable credential patterns;
- symbolic links that could point outside the repository;
- an `origin` remote other than `At0mFlow/At0mFlow-PSAnalyzer`.

The check runs in GitHub Actions and through the repository's pre-commit and
pre-push hooks after they are enabled:

```powershell
git config core.hooksPath .githooks
```

These controls reduce accidental disclosure risk, but they do not replace a
careful review of every staged change.
