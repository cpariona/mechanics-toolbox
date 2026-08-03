# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Current merged baseline

PR #48 is merged on `main`:

```text
366aa54ef8b5ddbfbcb77360b84e06f4baf20276
```

It includes D1-D4 for tensile application-range characterization: input/range contracts, shared fitting, parsimonious selection, range-sensitivity auditing, and optional fixed-parameter compression validation.

## Active branch

```text
feature/tensile-application-range-workflow
```

Purpose:

```text
D5 — public workflow, export, real-study driver, and validation closure
```

## D5 implementation status

Implemented:

```text
src/+mechanics/+workflow/runTensileApplicationRangeCharacterization.m
src/+mechanics/+io/exportTensileApplicationRangeCharacterization.m
studies/tension/run_tensile_application_range_characterization.m
tests/test_tensile_application_range_workflow.m
```

Updated:

```text
src/+mechanics/+config/tensileApplicationRangeCharacterizationConfig.m
tests/test_tensile_application_range_input_contract.m
```

## Public workflow

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Optional compression validation:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);
```

The entrypoint composes D1-D4 directly and does not duplicate their logic.

## Result contract

```text
normalized
candidates
candidateSummary
selectedModelName
selectedFit
referenceProperties
selection
rangeSensitivity
compressionValidation
hasCompressionValidation
config
createdAt
outputFiles
```

Compression remains prediction-only external validation and records:

```matlab
result.compressionValidation.refitPerformed = false;
```

## Export contract

Configuration:

```matlab
config.export.enabled = false;
config.export.outputFolder = ...
    "results/tensile-application-range-characterization";
```

When enabled, export produces:

```text
candidate_model_summary.csv
selected_parameters.csv
reference_properties.csv
tensile_specimen_fit_summary.csv
range_sensitivity_summary.csv
compression_validation_summary.csv   % optional
tensile_application_range_characterization.mat
tensile_application_range_characterization.md
```

Complete curves and diagnostic evidence remain in the MAT result. D5 does not create redundant curve CSV files or new figures.

## Real-study driver

```text
studies/tension/run_tensile_application_range_characterization.m
```

Primary input:

```text
results/real-tensile-study/tensile_study.mat
```

Optional input:

```text
results/real-compression-study/compression_study.mat
```

The driver loads completed study results only. It does not re-import workbooks or repeat preprocessing.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
tests/test_tensile_application_range_audit.m
tests/test_tensile_application_range_workflow.m
run_all_tests()
```

An obsolete D1 assertion that required the absence of `config.export` was corrected after D5 introduced a maintained consumer. The current test verifies that export exists, is disabled by default, and points to the maintained output folder.

Do not claim real-study or artifact validation beyond this synthetic and repository-wide MATLAB evidence.

## Remaining work after D5 merge

The required algorithmic capability is complete. Remaining work is experimental closure:

1. execute the real-study driver locally;
2. inspect selected model, parameters, `mu0`, candidate evidence, and specimen errors;
3. inspect stability across the configured upper fitting limits;
4. inspect optional compression predictions and confirm no refitting;
5. inspect exported CSV, MAT, and Markdown files;
6. add figures only when real outputs demonstrate a specific nonredundant scientific need;
7. document scientific interpretation, sensitivity, external validity, and limitations.

No new mandatory algorithmic phase is defined. Any later code should respond to concrete evidence from real validation.

## Repository verification

Before opening or merging the D5 PR:

```bash
git fetch origin --prune
git switch feature/tensile-application-range-workflow
git pull --ff-only origin feature/tensile-application-range-workflow
git diff --check
git status -sb
git ls-files --others --exclude-standard
```

After D5 is merged:

```bash
git switch main
git fetch origin --prune
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
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
- Keep generated data and outputs under ignored `results/` paths.
- Do not merge a pull request unless explicitly requested.
