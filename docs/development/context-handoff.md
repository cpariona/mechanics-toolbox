# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Current merged baseline

PR #46 is merged on `main`:

```text
4c30cc81283383f2f2789e627b40f741bd9c9a08
```

It includes D1 input/range contracts and D2 shared fitting for tensile application-range characterization.

## Active branch

```text
feature/tensile-application-range-selection
```

Purpose:

```text
D3 — parsimonious model selection and registry-derived reference properties
```

Do not continue D4 work on this branch after its PR is merged. Create a new branch from updated `main`.

## Maintained D1-D2 pipeline

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);
```

D1 consumes a completed tensile study, uses processed records only, preserves full curves and source indices, restricts observations without mutation, validates physical and metadata contracts, and records actual fitted ranges and exclusions.

D2 estimates one shared parameter vector per candidate model. The objective is the arithmetic mean of normalized specimen losses, giving every specimen equal influence regardless of sampling density. It retains multistart diagnostics, convergence state, parameters, per-specimen predictions, residuals, normalization scales, and physical fit summaries.

## D3 implementation status

Implemented:

```text
src/+mechanics/+workflow/selectTensileApplicationRangeModel.m
src/+mechanics/+models/modelRegistry.m
src/+mechanics/+config/tensileApplicationRangeCharacterizationConfig.m
tests/test_tensile_application_range_selection.m
```

Selection configuration:

```matlab
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
```

Selector:

```matlab
selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
```

The selector consumes D2 candidates and does not refit models.

Selection sequence:

1. exclude failed candidates;
2. exclude nonfinite objectives;
3. exclude nonconverged candidates when required;
4. determine the best eligible objective;
5. form the practical-equivalence set;
6. prefer fewer parameters;
7. use objective and configured order as deterministic tie-breaks.

Candidate names and tie-break names are canonicalized through `modelRegistry`. Registered aliases cannot be supplied as distinct candidates.

## Registry-derived reference properties

The selected result exposes reference properties generically through model metadata:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

Neo-Hookean registry metadata now defines:

```text
derivedQuantityNames = "mu0"
evaluateDerivedQuantities(parameters) = parameters(1)
```

No model-name conditional was added to the tensile selection workflow.

## D3 result contract

```text
candidates
candidateSummary
selectedModelName
selectedFit
referenceProperties
selection
config
createdAt
```

The candidate summary records:

```text
ModelName
Status
Converged
Eligible
PracticallyEquivalent
ParameterCount
Objective
ConfiguredOrder
```

## Reuse decision

D3 follows the maintained practical-equivalence and parsimonious ranking policy already used by joint characterization.

`selectJointModel` is not reused as a wrapper because it performs joint fitting and owns mode-specific summaries. The tensile selector operates on already fitted D2 candidate records.

No compatibility wrapper, bridge file, alias layer, or one-caller helper was introduced.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
run_all_tests()
```

Covered D3 behavior includes:

- best-objective selection outside practical equivalence;
- simpler-model preference inside practical equivalence;
- failed and nonconverged candidate exclusion;
- optional disabling of convergence requirements;
- rejection when no candidate is eligible;
- validation of configured tie-break order;
- canonical duplicate-alias rejection;
- generic `mu0` evaluation for all three maintained models.

Do not claim additional validation beyond this reported evidence.

## Next phase: D4

D4 is not yet implemented.

Objective:

> Audit sensitivity to the upper tensile application-range boundary and optionally evaluate compression predictions using the fixed tensile-selected model and parameters.

Required behavior:

- vary only the upper `fitRange` limit initially;
- reuse D1 normalization, D2 fitting, and D3 selection unchanged;
- record scenario ranges, selected models, objectives, parameters, and reference properties;
- preserve deterministic scenario ordering;
- allow optional compression prediction only after tensile calibration;
- do not refit on compression;
- do not allow compression data to influence tensile fitting or selection.

Do not begin D5 automatically.

## Later phase: D5

D5 should add the maintained public orchestration entrypoint, real-study driver, limited nonredundant outputs, documentation, and real validation.

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

After D3 is merged, create a new D4 branch from updated `main`, for example:

```bash
git switch -c feature/tensile-application-range-audit
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
