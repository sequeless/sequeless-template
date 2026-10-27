# sequeless-template

The starting point for a new Sequeless repo. It is a GitHub template repository: copy it with
"Use this template", then run the init script once in the new repo:

```bash
make init name=<repo-name>            # or: scripts/init-repo.sh <repo-name> [--github]
```

The init script renames the placeholders (`template-core`, `org.sequeless.template`,
`sequeless-template`), resets PROVENANCE.md and removes itself.

## What the template gives a repo

- Maven wrapper, Makefile (`make verify`, `make fmt`, `make new-adr`), devcontainer on JDK 25.
- A parent POM from `sequeless-build` and reusable CI, CodeQL, Sonar and release workflows.
- release-please in manifest mode, with per-module versions and 0.1.0 as the first version.
- A canonical `BoundaryRulesTest` for the module layers (api, spi, internal).
- A commitlint PR-title check and the agent docs under `docs/agents/`.

Until `sequeless-build` makes its first release, the parent, workflows and Renovate preset
cannot resolve, so CI stays red. That is expected (see docs/extraction in the prototype repo).
