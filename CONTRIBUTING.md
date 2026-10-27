# Contributing to sequeless-template

## Setup

Requires JDK 25. The Maven wrapper (`./mvnw`) is committed, so no local Maven install is needed.
The devcontainer (`.devcontainer/`) provides a ready JDK 25 toolchain.

Library modules build with `--release 21` through the `sequeless-build` parent. The build JDK is
always 25 (#17 §1). Maven reads the `github` package registry, so a read token is needed:

```bash
export PACKAGES_READ_TOKEN=<PAT with read:packages>   # locally; CI reads the org secret
make verify    # confirm a green baseline
```

Your `~/.m2/settings.xml` needs a `github` server entry (`server-id: github`) with the same PAT.

Until `sequeless-build` makes its first release, the parent, the reusable workflows and the
Renovate preset cannot resolve. CI is expected to be red until then.

There are no local git hooks. Conventional Commits are checked in CI, not on commit.

## Workflow

1. **Branch** off `main`.
2. **Make the change** with tests. The test is the specification. Format with `make fmt`.
3. **Verify** with `make verify`.
4. **Commit** using Conventional Commits.
5. **Open a PR** following the template. The `pr-title.yml` check lints the PR title with commitlint.
6. **Merge by squash.** The PR title becomes the commit on `main`. release-please reads it.

## Conventional Commits

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
Use `feat!:` or a `BREAKING CHANGE:` footer for majors. release-please derives versions and
changelogs from these titles. Never hand-edit a `CHANGELOG.md`.

## Recording a decision (ADR)

`make new-adr title="Short title"` scaffolds the next-numbered record under `docs/adr/`. Fill in
Context, Decision and Consequences. ADRs are immutable: supersede with a new one instead of editing.

## Quality gates

Spotless (format), Enforcer (dependency hygiene, including the parent's Spring, Jena and Lombok
ban on core modules), and ArchUnit (boundaries) all run in `make verify`. CodeQL and Sonar run in CI.

## Coverage (JaCoCo) convention

JaCoCo instrumentation runs on `verify`, but the line-coverage `check` (`jacoco-check`
execution) is **off by default** (`jacoco.check.skip=true` in `pom.xml`) — this repo has
**not yet opted in**. A project opts in once it carries settled production logic by flipping
the properties in `pom.xml`:

```xml
<properties>
  <jacoco.check.skip>false</jacoco.check.skip>
  <jacoco.line.min>0.32</jacoco.line.min> <!-- measured line coverage minus ~5pp -->
</properties>
```

Set `jacoco.line.min` from the module's actually-measured coverage (see the report under
`filter-core/target/site/jacoco/`), and ratchet it up over time rather than guessing a threshold now.
