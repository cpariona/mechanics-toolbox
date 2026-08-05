# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

## Current merged baseline

The repository is integrated on `main` after PR #50.

Observed aligned state before this documentation update:

```text
main == origin/main
e506d61e53eb5f584f544e7916ed7b951c089459
```

Local and remote feature branches from the tensile application-range integration were removed. Only `main` remains as the maintained branch.

## Completed integration

The tensile application-range characterization capability is complete and merged. It includes:

- normalization of completed tensile-study inputs;
- shared fitting of Neo-Hookean, Mooney-Rivlin, and Yeoh candidates;
- parsimonious model selection;
- registry-derived reference properties;
- sensitivity to the upper tensile fitting limit;
- optional compression prediction with fixed tensile-calibrated parameters and no refitting;
- maintained public orchestration;
- CSV, MAT, Markdown, PNG, and FIG export;
- unit-aware figures and reports;
- focused plotting tests and repository-wide regression validation.

Public entrypoint:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);
```

Compression remains external validation only:

```matlab
result.compressionValidation.refitPerformed = false;
```

## Real-study evidence

The maintained real-study driver was executed and its generated artifacts were inspected:

```text
studies/tension/run_tensile_application_range_characterization.m
```

Observed result:

- selected model: `mooney-rivlin`;
- selected parameters approximately `C10 = 0.0231222` and `C01 = 0.0054067` in the stored stress unit;
- reference `mu0` approximately `0.0570579` in the stored stress unit;
- stable model selection from upper deformation limits `0.30`, `0.40`, and `0.50`;
- approximately 1.55% total variation in `mu0` across those limits;
- good tensile fit for the first three retained specimens and a larger, still bounded mismatch for the fourth;
- compression prediction without refitting systematically underpredicts measured compressive-stress magnitude.

These observations support the tensile characterization but limit direct quantitative transfer from tension to compression.

## Maintained units contract

Stored physical values are not rescaled for presentation.

Human-facing outputs use:

```text
dimensionless strain -> mm/mm
stress and stress-like parameters -> stored stress unit, typically MPa
normalized objective, normalized RMSE, and normalized loss -> [-]
```

Shared presentation helpers:

```text
mechanics.plotting.mechanicalDisplayUnit
mechanics.plotting.mechanicalAxisLabel
```

## Validation evidence

The user reported successful local execution after the final figure corrections:

```text
tests/test_tensile_application_range_figures.m
tests/test_tensile_application_range_workflow.m
run_all_tests()
```

The real driver was rerun and the final tensile, sensitivity, and compression figures were visually accepted.

## Next maintenance phase

The next phase is a focused source-organization and contract-consolidation audit. It is not a new scientific workflow and must not alter validated numerical behavior without explicit evidence.

Primary goals:

1. consolidate human-facing unit presentation;
2. remove or reduce overlapping plotting-unit helpers;
3. migrate older maintained figures to the shared unit-aware label contract where their inputs contain sufficient metadata;
4. extract genuinely shared Markdown table serialization used by multiple maintained exporters;
5. document naming boundaries between `tension`, `tensile`, specimen-level mechanics, and study-level workflows;
6. verify package ownership and identify misplaced functions without reorganizing packages for cosmetic symmetry;
7. update tests only to protect maintained behavior, not obsolete aliases or temporary migration states.

Initial files to inspect:

```text
src/+mechanics/+plotting/formatUnitLabel.m
src/+mechanics/+plotting/mechanicalDisplayUnit.m
src/+mechanics/+plotting/mechanicalAxisLabel.m
src/+mechanics/+plotting/resolveStudyUnits.m
src/+mechanics/+plotting/plotStressStrain.m
src/+mechanics/+plotting/plotModelFit.m
src/+mechanics/+io/exportJointMaterialCharacterization.m
src/+mechanics/+io/exportTensileApplicationRangeCharacterization.m
```

## Required architecture contracts

- Favor simplicity, structure, order, and explicit ownership.
- Keep reusable implementation under `src/+mechanics`.
- Keep real experiment drivers under `studies`.
- Keep runnable demonstrations under `examples` and regression coverage under `tests`.
- Do not add implementation at repository root; maintained root MATLAB entrypoints are `startup.m` and `run_all_tests.m`.
- Extract shared code only when at least two maintained callers use the same physical and data contract.
- Do not create wrappers, aliases, bridge files, or one-caller helpers for superficial symmetry.
- Do not reorganize packages merely because a folder has many files.
- Preserve public APIs unless a demonstrated structural defect justifies migration.
- Use the model registry rather than scattering model-name conditionals when the contracts are identical.
- Keep model evaluation in `mechanics.models`, optimization in `mechanics.fitting`, population inference in `mechanics.statistics`, deterministic mechanical calculations in `mechanics.analysis`, and orchestration in `mechanics.workflow`.
- Keep individual tensile, compression, joint-characterization, and tensile application-range workflows distinct.
- Preserve completed-study add-ons as consumers of canonical completed study results; do not re-import or reprocess raw data.
- Preserve stored physical values and signs. Presentation conventions must not silently change numerical state.
- Generated data and outputs remain under ignored `results/` paths.
- Do not merge a pull request unless explicitly requested.

## Efficiency requirements

- Inspect callers before extracting, moving, or deleting a function.
- Prefer one small shared contract over parallel near-duplicates.
- Avoid broad rewrites when a localized consolidation is sufficient.
- Keep tests focused by subsystem and avoid repeating expensive end-to-end workflows unnecessarily.
- Do not retain obsolete migration tests after canonical behavioral coverage exists.
- Update canonical documentation in the same phase as structural changes.

## Session bootstrap

Before proposing or modifying code in a new session:

1. read this file completely;
2. read `docs/development/repository-structure.md`;
3. read the relevant workflow and testing documents;
4. verify Git state:

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
```

5. create a dedicated branch for code changes unless the user explicitly requests direct work on `main`;
6. inspect current callers and tests before proposing moves or shared helpers;
7. define the smallest coherent phase and its validation gate before implementation.

## Validation gate for the next phase

At minimum:

```text
focused plotting/export tests
all directly affected workflow tests
run_all_tests()
git diff --check
git status -sb
no generated files tracked
```

Do not claim MATLAB validation unless the user reports the actual local result.
