# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Current merged baseline

PR #47 is merged on `main`:

```text
754259577db38490380a97eaa364b957d346302a
```

It includes D1 input/range contracts, D2 shared fitting, and D3 parsimonious selection with registry-derived reference properties.

## Active branch

```text
feature/tensile-application-range-audit
```

Purpose:

```text
D4 — upper-range sensitivity and optional fixed-parameter compression validation
```

Do not continue D5 work on this branch after its PR is merged. Create a new branch from updated `main`.

## Maintained D1-D3 pipeline

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();

normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);

candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);

selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
```

D1 consumes a completed tensile study and restricts processed observations without mutation. D2 estimates one shared parameter vector per candidate with equal specimen influence. D3 applies convergence gating, practical equivalence, parsimonious ranking, and registry-derived `mu0` reporting.

## D4 implementation status

Implemented:

```text
src/+mechanics/+workflow/auditTensileApplicationRangeSensitivity.m
src/+mechanics/+workflow/validateTensileApplicationRangeCompression.m
src/+mechanics/+config/tensileApplicationRangeCharacterizationConfig.m
tests/test_tensile_application_range_audit.m
```

D4 configuration:

```matlab
config.rangeSensitivity.maximumDeformations = [0.20; 0.25; 0.30];
config.compressionValidation.minimumSpecimens = 1;
```

## Range-sensitivity contract

```matlab
audit = mechanics.workflow.auditTensileApplicationRangeSensitivity( ...
    tensileStudy, config);
```

For each configured maximum deformation, the audit reruns the maintained D1-D3 pipeline while changing only:

```matlab
scenarioConfig.fitRange(2)
```

Each scenario records:

```text
maximumDeformation
status
normalized
candidates
selection
errorIdentifier
errorMessage
```

The summary table records:

```text
MaximumDeformation
Status
SelectedModelName
Objective
Mu0
```

Scenario order is deterministic and follows the configured maximum-deformation vector. Invalid or repeated maxima are rejected.

## Compression-validation contract

```matlab
validation = mechanics.workflow.validateTensileApplicationRangeCompression( ...
    selection, compressionStudy, config);
```

Compression is prediction-only external validation. The selected tensile model and parameters remain fixed.

The function reuses:

```text
mechanics.workflow.normalizeJointCharacterizationStudies
mechanics.models.evaluateModel
```

The joint normalizer is called with one `compression` mode only. Joint fitting and joint selection are not called.

The result explicitly records:

```matlab
validation.refitPerformed = false;
```

Compression data cannot affect tensile normalization, fitting, eligibility, or selection.

The validation result includes model/parameter provenance, normalized compression specimens, per-specimen predictions and residuals, RMSE summaries, and mean normalized error.

## D4 reuse decision

The sensitivity audit reuses D1-D3 directly rather than duplicating range restriction, fitting, or selection logic.

Compression validation reuses the maintained compression mode normalization contract because the physical data representation and validation requirements match. It does not reuse any joint optimization behavior.

No compatibility wrapper, bridge file, alias layer, or one-caller helper was introduced.

## D4 validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
tests/test_tensile_application_range_audit.m
run_all_tests()
```

Covered D4 behavior includes:

- all configured sensitivity scenarios execute in order;
- the source tensile study remains unchanged;
- synthetic selected model and `mu0` remain stable;
- invalid and repeated sensitivity maxima are rejected;
- compression predictions use fixed tensile parameters;
- `refitPerformed` remains false;
- synthetic compression predictions recover the expected response;
- minimum validation-specimen requirements are enforced.

Do not claim additional MATLAB validation beyond this reported evidence.

## Next phase: D5

D5 is not yet implemented.

Objective:

> Add the maintained public orchestration entrypoint, a real-study driver, limited nonredundant outputs, and real-data validation.

Required work:

- add `mechanics.workflow.runTensileApplicationRangeCharacterization`;
- compose D1-D4 without duplicating their logic;
- decide how optional sensitivity and compression validation are enabled;
- add the real driver under `studies/tension`;
- add only outputs that are not duplicates of existing tensile or joint reports;
- keep generated artifacts under ignored `results/` paths;
- validate with the maintained real tensile study and optional compression study;
- inspect figures and tables manually before merge.

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

Do not begin unrelated OCE, wave, or acoustoelastic work in D5.

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

After D4 is merged, create a new D5 branch from updated `main`, for example:

```bash
git switch -c feature/tensile-application-range-workflow
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
