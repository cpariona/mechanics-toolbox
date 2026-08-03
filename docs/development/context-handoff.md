# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Current merged baseline

PR #45 is merged on `main`:

```text
459faa5de3768442eb77d1ae45735e87821ba7d3
```

It includes D1 input and range contracts for tensile application-range characterization. The repository also includes maintained tension and compression workflows, individual and population model selection, reporting and comparison utilities, C1-C5 joint material characterization, robustness auditing, scale-aware sign validation, and validated joint fitting figures.

## Active branch

```text
feature/tensile-application-range-fitting
```

Purpose:

```text
D2 — range-limited shared tensile fitting
```

Do not continue D3 work on this branch after its PR is merged. Create a new branch from updated `main`.

## D1 maintained contract

Configuration:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
```

Normalizer:

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
```

It consumes a completed tensile study, uses processed records only, preserves full curves and observation indices, restricts observations without mutation, validates physical and metadata contracts, records actual fitted ranges and exclusions, and does not require population or individual fitting outputs.

D1 validation reported passing:

```text
tests/test_tensile_application_range_input_contract.m
run_all_tests()
```

## D2 implementation status

Implemented:

```text
src/+mechanics/+fitting/fitTensileApplicationRangeModel.m
src/+mechanics/+workflow/fitTensileApplicationRangeModels.m
tests/test_tensile_application_range_fitting.m
```

D2 configuration additions:

```matlab
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.normalization.minimumScale = sqrt(eps);
config.fitting = mechanics.config.fittingConfig();
```

Fit one model:

```matlab
fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, modelName, config);
```

Fit all candidates:

```matlab
candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);
```

D2 estimates one shared parameter vector per candidate model across all retained specimens. The objective is the mean of the normalized specimen losses, so every specimen has equal influence regardless of sampling density. It does not use pooled pointwise SSE.

Each fit retains multistart diagnostics, convergence state, parameters, objective, per-specimen predictions, residuals, normalization scales, and physical error summaries. Candidate failures are recorded independently. No model is selected in D2.

## D2 reuse decision

Directly reused:

```text
mechanics.models.modelRegistry
mechanics.models.evaluateModel
mechanics.fitting.resolveFitConfig
mechanics.fitting.generateInitialGuesses
mechanics.fitting.parametersToUnconstrained
mechanics.fitting.unconstrainedToParameters
```

Not reused as a wrapper:

```text
mechanics.fitting.fitJointModel
```

Reason: its public and internal contract includes modes, mode weights, and multi-mode summaries that do not belong in a tensile-only add-on.

No generic multistart helper was extracted. Refactor solver-only code only after two maintained callers are proven to share the same contract and tests can protect both paths.

## D2 validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
run_all_tests()
```

Covered D2 behavior includes:

- Neo-Hookean synthetic recovery;
- Yeoh synthetic recovery;
- one shared parameter vector across specimens;
- retained predictions and residuals;
- invariance to duplicated sampling points in one specimen;
- one result per candidate model;
- rejection of unsupported weighting and normalization.

Do not claim additional validation beyond this reported evidence.

## Next phase: D3

D3 is not yet implemented.

Objective:

> Select a reliable and parsimonious candidate model and expose model-registry-derived reference properties without workflow model-name conditionals.

Required behavior:

- reject failed or nonfinite candidates;
- use convergence and maintained reliability evidence;
- apply practical-equivalence tolerance;
- prefer fewer parameters among practically equivalent candidates;
- use configured candidate order only as final tie-break;
- preserve all candidate evidence and the selection rationale;
- expose reference quantities through `modelRegistry`.

Before generic `mu0` reporting, update Neo-Hookean metadata to define:

```text
mu0 = mu
```

Do not begin D4 automatically.

## Later phases

### D4 — Range sensitivity and optional validation

- one-factor sensitivity to the upper fitted deformation;
- optional compression prediction with fixed tensile-calibrated parameters;
- no compression refitting or influence on tensile selection.

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

After D2 is merged, create a new D3 branch from updated `main`, for example:

```bash
git switch -c feature/tensile-application-range-selection
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
