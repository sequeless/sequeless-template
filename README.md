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

The parent POM (`sequeless-build-parent` 0.1.3) and the reusable workflows (`workflows-v0.1.2`)
come from released `sequeless-build` versions, and CI runs against them. Renovate moves both.
The extraction plan is in `docs/extraction` in the prototype repo.

## Local setup

The parent POM comes from GitHub Packages, so export a token with `read:packages` as
`GITHUB_PACKAGES_TOKEN` before any `mvn` run. The `github` server in `~/.m2/settings.xml` reads it
as `<password>${env.GITHUB_PACKAGES_TOKEN}</password>`; `sequeless-build`'s README has the full entry.

If `spotless:check` fails at `verify`, run `mvn spotless:apply`, then `mvn verify` again. The parent
rejects a POM that is valid XML but not in the formatter's layout.

SonarCloud is optional: the workflow skips with a notice when `SONAR_TOKEN` is absent.
