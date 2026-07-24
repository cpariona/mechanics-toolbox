# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Current working branch:

```text
feature/mechanics-pipeline-refinement
```

Do not create a pull request, merge, or modify `main` unless explicitly requested.

## Current state

The repository contains maintained tensile and compression workflows, constitutive fitting, diagnostics, Monte Carlo measurement uncertainty, population analysis, group comparison, plotting, exports, and automated tests.

The complete MATLAB test suite passes on the current branch.

The next work phase is intentionally limited to:

1. repository organization and cleanup;
2. terminology and public-API consistency;
3. documentation review;
4. real-data validation of the tensile workflow.

Prefer simple changes. Do not add new abstractions unless they solve a demonstrated problem.

## Read first

Read only these files initially, in order:

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/development/testing.md`
6. `docs/workflows/tensile-study.md`
7. `docs/reference/geometry-uncertainty.md`

Read additional implementation files only when needed for the selected task.

## Verify the repository before proposing changes

Run:

```bash
git fetch origin
git switch feature/mechanics-pipeline-refinement
git status -sb
git rev-parse HEAD
git rev-parse origin/feature/mechanics-pipeline-refinement
git log -5 --oneline --decorate
```

Report:

- local branch and SHA;
- remote branch SHA;
- whether the branch is ahead, behind, or synchronized;
- working-tree status;
- recent relevant commits.

Do not discard local changes automatically.

## Validation commands

Focused MATLAB test:

```matlab
startup
results = runtests("tests/test_name.m", "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

Complete suite:

```matlab
clear
clc
close all
results = run_all_tests();
```

Repository checks:

```bash
git diff --check
git status -sb
git status --ignored -s
git ls-files --others --exclude-standard
```

Local experimental data and generated results are ignored under `data/` and `results/`. Do not delete them without confirming that the user has preserved anything needed.

## Current conventions

- Maintained implementation belongs under `src/+mechanics/`.
- Runnable user examples belong under `examples/`.
- Automated tests belong under `tests/`.
- Documentation belongs under `docs/`.
- Root MATLAB entrypoints are limited to `startup.m` and `run_all_tests.m`.
- Preserve raw experimental data separately from processed results.
- Prefer current descriptive names; avoid names such as `legacy`, `historical`, `old`, or similar terminology in maintained APIs and documentation.
- `processingHistory` currently means the processing trace applied to a specimen; do not rename it casually because it is part of existing contracts.
- Peak and post-peak analysis is descriptive and must not claim automatic fracture classification.

## Pending review

The next chat should verify, without broad refactoring:

- obsolete or duplicated examples;
- unused public functions or configuration options;
- stale terminology in source, tests, exports, and documentation;
- consistency between documented and actual accepted option names;
- whether test files are organized clearly without removing coverage;
- whether the tensile live workflow runs correctly with real data.

After review, summarize findings before modifying files. Apply cleanup in small commits and rerun the relevant tests after each functional change.

## Prompt for a new chat

Copy and send:

```text
Quiero continuar el trabajo técnico en el repositorio `cpariona/mechanics-toolbox`.

La rama de trabajo es `feature/mechanics-pipeline-refinement`. La implementación funcional está completa y la suite de MATLAB pasa. La siguiente fase es organización y limpieza, revisión de terminología y consistencia de la API, revisión documental y luego validación con datos reales.

Antes de proponer cambios:

1. Ejecuta `git fetch origin` y verifica el estado real de la rama local frente a la remota.
2. Reporta SHA local, SHA remota, `git status -sb` y los últimos commits relevantes.
3. Lee, en orden:
   - `README.md`
   - `docs/README.md`
   - `docs/development/context-handoff.md`
   - `docs/development/repository-structure.md`
   - `docs/development/testing.md`
   - `docs/workflows/tensile-study.md`
   - `docs/reference/geometry-uncertainty.md`
4. Revisa únicamente archivos adicionales necesarios para identificar problemas concretos.
5. Resume el estado, los asuntos pendientes y una propuesta simple de limpieza.

No abras PR, no fusiones ramas y no modifiques `main`. No hagas una refactorización amplia. Prioriza simplicidad, compatibilidad y cambios pequeños verificables.
```

## Closing a work session

Before moving to another chat:

1. ensure the working tree state is known;
2. record the latest commit SHA;
3. record which tests passed;
4. update this document only when the persistent state or next phase changes;
5. provide a short copyable prompt for the next chat.
