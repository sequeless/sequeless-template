# Design Preferences

## Philosophy

Design decisions in this project should prioritise:

1. **Minimal and modular.** Implement only what's needed. Avoid over-engineering or speculative design.
2. **Maintainable.** Favour clarity, loose coupling and high cohesion.
3. **Open to evolve.** Design to support future alternatives without major rewrites. Avoid locking into a single implementation.

## Architectural pattern: hexagonal (ports and adapters)

Each module splits into three layers, enforced by `BoundaryRulesTest`:

- **`api`**: the types callers use. Public.
- **`spi`**: the ports that adapters implement. Public.
- **`internal`**: implementation detail. Not reachable from outside the module.

Api and spi never depend on internal. Core modules take no Spring, Jena or Lombok dependency.
Those belong in adapter modules. Maven dependency declarations enforce the rest.

## Adapter strategy

Each port has a default adapter, and a configuration property selects it, not code branching
or feature flags. Contract tests in a testkit module hold every adapter to the same guarantees.

## How agents should apply this

When grilling or recommending architecture:

1. **Ask about boundaries.** Does this logic belong in the core, or behind a new port in an adapter?
2. **Prefer ports to magic.** Propose a new port before baking a cross-cutting concern into core.
3. **Sketch adapters.** Suggest two or three plausible adapter implementations before settling a port.
4. **Avoid premature unification.** Don't merge similar concerns into one port until they share semantics.
5. **Configuration over code.** Recommend configurable adapter selection, not compile-time choices or constants.

## Reference

- **Decision records**: `docs/adr/`. Consult them before revisiting a design choice.
- **Glossary**: `GLOSSARY.md`, read before ADRs.
