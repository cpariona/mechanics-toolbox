# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Current merged baseline

PR #44 is merged on `main`:

```text
50fffe271a2ca2f0f5aad632fcfde9288405552d
```

It includes the previously validated joint-characterization plotting improvements. The old statement that `fix/fitting-plot-clarity` remained unmerged is obsolete.

The merged repository includes maintained tension and compression workflows, individual and population model selection, reporting and comparison utilities, C1-C5 joint material characterization, robustness auditing, scale-aware sign validation, and the improved joint fit figures.

## Active branch

```text
feature/tensile-application-range-contracts
```

Purpose:

```text
D1 — tensile application-range input and range contracts
```

Do not continue D2 work on this branch after its PR is merged. Create a new branch from the updated `main` baseline.

## D1 implementation status

Implemented:

```text
src/+mechanics/+config/tensileApplicationRangeCharacterizationConfig.m
src/+mechanics/+workflow/normalizeTensileApplicationRangeStudy.m
tests/test_tensile_application_range_input_contract.m
```

Canonical workflow documentation:

```text
docs/workflows/tensile-application-range-characterization.md
```

Configuration contract:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
```

A two-element vector is the repository convention for a closed interval. Separate minimum and maximum fields are not used.

D1 normalizer:

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
```

The normalizer consumes one completed tensile study and:

- uses only processed specimen records;
- does not require population analysis or individual fitting outputs;
- reads existing processed strain, stress, units, and mechanics metadata;
- validates finite observations, tensile signs, units, measures, and registered candidates;
- restricts observations to the configured interval without changing source data;
- preserves full curves and original observation indices;
- records available, requested, and actual fitted ranges;
- records specimen exclusions and observation counts;
- rejects the analysis when too few valid specimens remain.

No fitting, selection, audit, validation, plotting, export, report, or study driver is implemented in D1.

## D1 reuse decision

Direct reuse:

```text
mechanics.models.modelRegistry
existing mechanics metadata conventions
existing scale-aware sign-validation principle
existing unit and finite-observation contracts
```

Not reused directly:

```text
mechanics.workflow.normalizeJointCharacterizationStudies
```

Reason: the joint normalizer requires modes, mode weights, and multi-mode normalization. Adding those concepts to a tensile-only add-on would create unnecessary coupling.

No shared helper was extracted. Extract lower-level code only when at least two maintained callers share the same physical and data contract.

## D1 validation evidence

The user reported that both passed on the active branch:

```text
tests/test_tensile_application_range_input_contract.m
run_all_tests()
```

Two implementation issues were corrected before the successful run:

1. summary tables now force every variable to column orientation;
2. range tests no longer assume an experimental grid contains the requested boundary exactly.

Do not claim additional MATLAB validation beyond this reported evidence.

## Next phase: D2

D2 is not yet implemented.

Objective:

> Fit one shared parameter vector per candidate hyperelastic model across all retained tensile specimens inside the D1 application range, with equal specimen influence.

Required D2 behavior:

- consume the D1 normalized contract;
- reuse model evaluation, fitting configuration, bounds, parameter transforms, multistart, and diagnostics where contracts match;
- preserve equal specimen influence regardless of sampling density;
- retain per-specimen predictions and fit metrics;
- add synthetic parameter-recovery tests;
- add sampling-density invariance tests;
- avoid pooled pointwise SSE;
- avoid artificial mode fields or weights.

Before implementing D2, audit the existing individual and joint fitting internals. Extract a shared solver-only function only when at least two maintained callers genuinely share that contract.

Do not begin D3 automatically.

## Later phases

### D3 — Selection and reference properties

- practical-equivalence and parsimonious model selection;
- registry-derived `mu0` and other reference quantities;
- model-agnostic behavior for Neo-Hookean, Mooney-Rivlin, and Yeoh.

The current Neo-Hookean registry metadata does not yet expose `mu0 = mu`; resolve that in D3 rather than adding workflow conditionals.

### D4 — Range sensitivity and optional validation

- one-factor sensitivity to the upper fitted deformation;
- optional compression prediction using fixed tensile-calibrated parameters;
- no compression refitting and no influence on tensile selection.

### D5 — Driver, outputs, and real validation

Planned driver:

```text
studies/tension/run_tensile_application_range_characterization.m
```

Primary local input:

```text
results/real-tensile-study/tensile_study.mat
```

Optional validation input:

```text
results/real-compression-study/compression_study.mat
```

Local data and generated outputs remain ignored.

## Validation protocol

For each phase:

1. run focused behavioral tests;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. run `git diff --check`;
6. verify no generated files are tracked;
7. do not merge a pull request unless explicitly requested.

## Repository verification

At the start of the next session:

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
```

If D1 has been merged, create the D2 branch from updated `main`, for example:

```bash
git switch -c feature/tensile-application-range-fitting
```

## Maintenance rules

- Favor simplicity, structure, order, and explicit contracts.
- Represent intervals as two-element vectors where appropriate.
- Share code only for genuinely shared physical and data contracts.
- Keep reusable implementation under `src/+mechanics` and real drivers under `studies`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Do not add bridge files or one-caller helpers for superficial symmetry.
- Use the model registry instead of model-name conditionals where contracts match.
- Keep individual, joint, and tensile application-range workflows distinct.
- Do not merge a pull request unless explicitly requested.
