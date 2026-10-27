# Spec 2 — Stage 0: `sequeless-template`

> Source issue: [#30](https://github.com/sequeless/sequeless-prototype/issues/30). Part of
> [Decompose the prototype into a CQRS repo layout](https://github.com/sequeless/sequeless-prototype/issues/11),
> spec 2 of 19. Decisions read: [Build baseline across repos (#17)](https://github.com/sequeless/sequeless-prototype/issues/17),
> [Order of the extraction plan and how git history is kept (#23)](https://github.com/sequeless/sequeless-prototype/issues/23),
> [Where to publish artifacts (#18)](https://github.com/sequeless/sequeless-prototype/issues/18) and its superseding note,
> and the human tasks #48, #49, #51, #54 (all closed).
>
> Moved here from the prototype's `docs/extraction/` when this repo was created ([#49](https://github.com/sequeless/sequeless-prototype/issues/49): specs move into their repos on creation).

## Scope

Create `sequeless-template`, the GitHub template repo that every new Sequeless repo starts from.
It holds the files each repo keeps its own copy of (#17 §2): Makefile, Maven wrapper,
commitlint, devcontainer, the canonical `BoundaryRulesTest`, plus everything else a repo needs
on day one. That includes release-please wired for per-module versions and the
GitHub Packages read and deploy config. A new repo made with "Use this template" plus one init
script must pass `make verify` and CI with no further edits.

The template holds **per-repo files only**. Shared build logic (plugin management, enforcer
rules, the job bodies of the workflows, the Renovate rules) lives in `sequeless-build` (spec 1)
and is referenced, never copied.

## 1. Identity, stage and dependencies

| | |
|---|---|
| Repo | `sequeless/sequeless-template`, **public** (#49), marked as a GitHub template repository |
| Stage | 0 (with `sequeless-build`) |
| Waits for | nothing to start. Its CI can only go green after spec 1's first release (see below). |
| Published artifacts | none. The template is never released. New repos copy it from `main`. |
| Consumers | specs 5 (kernel), 8 (expression), 14 (query), 15 (automation), 19 (knowledge) create their repos from it. Specs 6 (filter) and 11 (ontology) copy its files when they migrate to release-please. |
| Not a consumer | the prototype. Spec 3 adopts the `sequeless-build` parent, not the template. |

**Soft dependency on spec 1.** The template's POMs reference the `sequeless-build` parent and
its workflows call `sequeless-build`'s reusable workflows. So the work can start in parallel
with spec 1, but the PR that pins released versions of those can merge only after spec 1's first
release. Until then the template's CI stays red, and that is expected.

### Contract with spec 1

These are the names the template assumes from `sequeless-build`. Spec 1 owns them. If spec 1
picks different names, use spec 1's names and update this table. Don't diverge.

| Item | Assumed here |
|---|---|
| Parent POM | `org.sequeless:sequeless-build-parent` (spec-01:42-48: not `sequeless-parent`, which is the prototype root's name), released version pinned (no SNAPSHOT on `main`) |
| Read repository id / URL | `github` → `https://maven.pkg.github.com/sequeless/*`, credentials from `PACKAGES_READ_TOKEN` (org secret, #54) |
| Deploy | The parent's `distributionManagement` (spec-01:218-227) deploys to `https://maven.pkg.github.com/sequeless/${sequeless.github.repository}`, with `GITHUB_TOKEN` (`packages: write`) from `maven-release.yml`. The template sets no `distributionManagement` of its own. |
| Reusable workflows | `sequeless/sequeless-build/.github/workflows/maven-{ci,codeql,sonar,release}.yml` (spec-01:114-117), called with `secrets: inherit` and pinned to `@workflows-vX.Y.Z` (spec-01:313-314; Renovate's `github-actions` manager bumps the ref) |
| Renovate preset | `github>sequeless/sequeless-build` (`default.json` at the repo root, spec-01:107-108; the preset is not versioned, spec-01:313-316) |
| Core-module marker | whatever spec 1's parent uses to switch on the enforcer `bannedDependencies` (no Spring, Jena, Lombok) for a core module. `template-core` opts in. |
| Library vs app | libraries get `--release 21` from the parent by default. An app module overrides it to 25 (#17 §1). |

Two server ids, because the read PAT from #54 has `read:packages` only, while deploys use the
workflow's own `GITHUB_TOKEN`. The read URL needs a check against GitHub's docs: is the
wildcard form accepted, or must it name a real repo in the org? (Any repo in the org can serve
reads of org packages.) Record which form works in spec 1.

## 2. Moves

No code moves. Convention files are copied from filter and ontology and then edited. Neither
source loses anything here. filter and ontology replace their copies with the template's when
they migrate (specs 6 and 11).

### PROVENANCE.md (the template's own, first commit)

```markdown
# Provenance

- Source repos: sequeless/sequeless-filter, sequeless/sequeless-ontology, sequeless/sequeless-prototype
- Source SHAs: filter@b5f69021807434981b7809cda78bb545801cba54 (re-cloned; the earlier 14c7a5d is stale),
  ontology@ace531320c135b40ece72336382078aacc882ba5,
  prototype@<SHA of prototype main at extraction>
- Source paths: listed in the table below
- The move: copied and adapted into a GitHub template repo. Sources unchanged.
- Date: <date of the first commit>
- Decisions: sequeless-prototype#17, #23 (extraction plan, spec 2 = #30)
```

The SHAs above are the current `main` tips. Re-read them when the first commit is made.

### Files

| Template path | Source | How |
|---|---|---|
| `Makefile` | filter `Makefile` (same as ontology's) | Edit: drop `release-dry-run` (semantic-release). Add `init` (runs `scripts/init-repo.sh`). |
| `mvnw`, `mvnw.cmd`, `.mvn/wrapper/maven-wrapper.properties` | filter | Copy. Renovate bumps the Maven version later. |
| `commitlint.config.mjs` | filter (ontology has none) | Copy |
| `.devcontainer/devcontainer.json` | filter | Edit: JDK **25** (Temurin), `name` is a placeholder |
| `.editorconfig`, `.gitattributes`, `LICENSE` (Apache-2.0) | filter (same as ontology's) | Copy |
| `.gitignore` | filter ∪ ontology | Union: keep filter's `!.mvn/wrapper/maven-wrapper.jar` and ontology's AI-agent lines |
| `CODEOWNERS` | ontology (no `/src/` line) | Copy. A multi-module repo has no root `src/`. |
| `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/*` | filter (same as ontology's) | Copy |
| `CONTRIBUTING.md` | filter | Edit: JDK 25, release-please replaces semantic-release, PR titles are linted by `pr-title.yml` (filter's text claims a pr-title job that doesn't exist), squash-merge only, local `PACKAGES_READ_TOKEN` setup. The JaCoCo opt-in section stays. |
| `sonar-project.properties` | ontology (passes `sonar.organization`) | Edit: `projectKey` is a placeholder |
| `scripts/new-adr.sh`, `docs/adr/_template.md`, `docs/adr/0000-record-architecture-decisions.md` | filter | Copy |
| `<module>/src/test/.../BoundaryRulesTest.java` | ontology `facet-core` (the only one with all four rules) | Edit: generalise to the four canonical rules (§5) |
| `CLAUDE.md`, `docs/agents/issue-tracker.md`, `docs/agents/domain.md` | prototype | Copy. The issue-tracker repo name is a placeholder. |
| `docs/agents/design-preferences.md` | prototype | Edit: drop the prototype module names (`sequeless-core`, `sequeless-spi`…) and keep the hexagon rules |
| `GLOSSARY.md` | new | Empty, single-context layout (`docs/agents/domain.md`) |
| `renovate.json` | filter | Rewrite: only `extends` the `sequeless-build` preset. The rules move into the preset (spec 1). |
| `.github/workflows/ci.yml`, `codeql.yml`, `release.yml` | filter | Rewrite as thin callers of the reusable workflows (§7) |

**Not carried over:** `.releaserc.json`, `CHANGELOG.md` (release-please generates it per
module), `lombok.config` (the parent bans Lombok in core modules, so the template shouldn't
invite it), and the repo-specific `docs/specs/*`.

## 3. Prerequisite refactors

None. Nothing moves out of the prototype, so there's no behaviour change to land first.

## 4. Package renames

None in existing code. The template ships the placeholder package `org.sequeless.template`.
`scripts/init-repo.sh` renames it per repo (§5).

## 5. Modules and their dependencies

```
sequeless-template/
├── pom.xml               aggregator only: <packaging>pom</packaging>, <modules>, never released
└── template-core/        placeholder library module
    ├── pom.xml           <parent> = org.sequeless:sequeless-build-parent, pinned 0.1.0, <relativePath/>; module version 0.1.0-SNAPSHOT
    └── src/
        ├── main/java/org/sequeless/template/{api,spi,internal}/package-info.java
        └── test/java/org/sequeless/template/BoundaryRulesTest.java
```

- **Modules inherit from the published parent, not from the root.** The root is never
  deployed (#17 §4), so a module whose `<parent>` was the root couldn't be resolved by consumers.
  The root has no `<parent>` and sets `maven.deploy.skip=true`.
- **`template-core` dependencies:** test scope only (JUnit, ArchUnit, AssertJ). The parent
  manages their versions. No runtime dependencies. It opts in as a core module (contract table).
- **Canonical `BoundaryRulesTest`** (#17 §5) has four rules:
  1. no `org.springframework..`;
  2. top-level types in `api..`/`spi..` are public;
  3. `api..`/`spi..` don't depend on `internal..`;
  4. only `java..` and the module's own package. A comment says to widen this rule to each
     declared Sequeless dependency (for example `org.sequeless.kernel..`), and that an adapter
     module drops it in favour of Maven dependency declarations.

  Rule 2 has nothing to check until real types exist, so it carries
  `allowEmptyShould(true)` with a `TODO: drop once real types land`, as ontology-core does.
  `package-info` classes give rules 1, 3 and 4 something to import.
- **Repository entry (spec 1's mechanism, not `.mvn/settings.xml`).** Maven resolves a `<parent>`
  before it reads the parent's `<repositories>`, so each consumer's root POM repeats the `github`
  repository entry, and the template ships it (spec-01:236-239). `template-core/pom.xml` repeats
  it too, because it declares its parent and the root aggregator is not its parent. `template-core`
  also imports `junit-bom` (spec-01:167) for the same reason. Credentials stay in `~/.m2/settings.xml`
  (`server-id: github`) locally and in CI (`PACKAGES_READ_TOKEN`), per spec-01:230-235. The template
  commits no `.mvn/settings.xml`.

### `scripts/init-repo.sh <name>`

This is what makes "Use this template" repeatable for the five new repos. Run once, right after
creating the repo:

1. Replace the placeholders: `template` → `<name>` in the module dir and artifactId, the
   `org.sequeless.template` package, the devcontainer name, the Sonar `projectKey`
   (`sequeless-<name>`), the release-please config, the README title, the CONTRIBUTING title
   and the issue-tracker repo name.
2. Swap the template's `PROVENANCE.md` for a skeleton that has the five #23 fields plus
   `Created from: sequeless/sequeless-template@<template SHA>`.
3. Delete the template-only files: `docs/specs/stage-0-sequeless-template.md`,
   `.github/workflows/template-smoke.yml`, and the script itself.
4. With `--github`, apply the repo settings a template doesn't copy:
   `gh repo edit --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge`,
   then `gh api -X PATCH repos/sequeless/sequeless-<name> -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY`.
   release-please reads squash titles, so this step matters.

Repos with more than one module (kernel has two) add the rest by copying the renamed module dir.

## 6. Release config

**The template itself:** not released, no tags, no BOM entry. Its `release.yml` is guarded by
`if: github.repository != 'sequeless/sequeless-template'`.

**What generated repos inherit** (#17 §4, #23 §4):

- `release-please-config.json`: manifest mode, `"release-type": "maven"`,
  `"include-component-in-tag": true` (tags are `<module>-vX.Y.Z`), the plugin
  `{"type": "maven-workspace"}` (modules that depend on a released module get a patch release),
  and one entry per module: `"template-core": {"component": "template-core", "initial-version": "0.1.0"}`.
- `.release-please-manifest.json`: `{}`. Every module is unpublished, so the first release is
  **0.1.0** (#23 §4). Check that `initial-version` works against the current release-please
  docs. If it doesn't, use `release-as: 0.1.0` for the first run and remove it afterwards.
- Module POMs carry `0.1.0-SNAPSHOT`. The maven strategy's snapshot PR moves them to the next
  `-SNAPSHOT` after each release.
- No `bootstrap-sha`. A repo made from the template has only the generated "Initial commit"
  before the import commit, and that commit isn't a Conventional Commit, so it adds nothing to
  the changelog.
- **BOM change:** none here. Each generated repo's spec adds its modules to the BOM when it
  releases.

## 7. CI and workflows

| Workflow | Runs | Body |
|---|---|---|
| `ci.yml` | push to `main`, PRs | calls `maven-ci.yml` (JDK 25, `mvn verify`), then `maven-sonar.yml` with `sonar-organization: sequeless`, which skips without `SONAR_TOKEN`. No snapshot-deploy input: spec 1 has none, and the template publishes nothing. |
| `codeql.yml` | push, PRs, weekly | calls `maven-codeql.yml` with `languages: java-kotlin` |
| `release.yml` | push to `main` | calls `maven-release.yml` (release-please, then `-pl <released> -am deploy`). Permissions: `contents`, `pull-requests`, `packages: write`. Skipped in the template repo. |
| `pr-title.yml` | PR opened, edited or synchronised | local: `npx commitlint` on the PR title. Not on #17's list of reusable workflows. Promote it to `sequeless-build` once two repos carry it unchanged. |
| `template-smoke.yml` | template repo only | **Not built yet:** the implementation plan (2026-10-27) omits it. Spec §7 wants it: copy the tree, run `scripts/init-repo.sh smoke` on the copy, then `./mvnw -B verify`. Decide whether it is still needed. |

Secrets: `PACKAGES_READ_TOKEN` (org, #54) and `SONAR_TOKEN` (optional). Each repo needs its
SonarCloud project created by hand, and CI skips the scan until then. The org already lets
Actions create PRs (#51) and has Renovate installed (#51).

Repo settings for the template repo itself: `gh repo create sequeless/sequeless-template --public`,
then `gh repo edit --template` and the same merge settings as `init-repo.sh --github`.

## 8. ADRs

None new. #23 lists no ADR for the template, and its choices (the repository entry in the POMs, the init script, the placeholder module) are easy to reverse. The template
ships `docs/adr/0000-record-architecture-decisions.md` and `_template.md`, so each generated
repo starts its ADR log at 0001.

## Definition of done

| Item (#30) | For this spec |
|---|---|
| The new repo's CI is green | `ci.yml`, `codeql.yml`, `pr-title.yml` and `template-smoke.yml` are green on `main`, with the parent and workflows pinned to spec 1's **released** versions |
| The prototype's CI is green against released artifacts | holds trivially, since the prototype is untouched. Confirm no prototype PR is part of this spec. |
| The BOM's CI (all testkit contracts) is green | not affected: the template adds nothing to the BOM. Holds as long as spec 1's BOM CI is green. |
| The release and the BOM re-release are done | N/A: the template is never released (§6) |
| Cut-over: deletion commit with reverse pointer | N/A: not a cut-over spec, nothing is deleted from the prototype |

Plus: the repo is marked as a template; a throwaway repo created from it and initialised with
`init-repo.sh` passes CI, then gets deleted; this spec file lives at
`docs/specs/stage-0-sequeless-template.md` in the new repo.
