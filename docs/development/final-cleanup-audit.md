# Final repository cleanup audit

> Historical snapshot: this document records the repository state after the tensile-study comparison migration. Its former “Remaining work” section reflected the state at that time and is not the current roadmap. Current priorities are maintained only in `docs/development/context-handoff.md`.

## Maintained tensile workflows

`mechanics.workflow.runTensileStudy` is the maintained end-to-end entrypoint for one tensile study. It accepts workbook, file-list, manifest, and pre-extracted dataset inputs and normalizes them before common downstream analysis.

`mechanics.workflow.compareTensileStudies` is the maintained entrypoint for comparing completed tensile studies. It consumes study results, validates compatibility, preserves the original studies, namespaces specimen identifiers to avoid collisions, and reuses the maintained population and group-comparison workflows.

## Legacy batch pipeline removed

The row-oriented manifest batch pipeline was removed after the replacement comparison workflow passed focused tests.

Removed files:

```text
src/+mechanics/+workflow/processBatchManifest.m
src/+mechanics/+workflow/summarizeBatchResults.m
src/+mechanics/+config/batchProcessingConfig.m
src/+mechanics/+io/exportBatchSummary.m
tests/test_batch_processing.m
```

The removed pipeline mixed specimen ingestion, processing, optional fitting, export, row-level status tracking, and batch summarization. That abstraction did not match the maintained experimental pattern of one workbook per material or condition with several specimens per workbook.

## Manifest support retained

Manifest input remains supported by `runTensileStudy`. The following contracts remain maintained:

```text
src/+mechanics/+workflow/validateBatchManifest.m
src/+mechanics/+io/readBatchManifest.m
examples/templates/specimen_manifest_template.csv
```

Validation tests for manifest defaults, text-valued include flags, required columns, normalization, and downstream equivalence were moved into `test_tensile_study_input_contracts.m`.

## Study comparison contract

A representative use is:

```matlab
study0020 = mechanics.workflow.runTensileStudy( ...
    ecoflex0020Workbook, config0020);
study0050 = mechanics.workflow.runTensileStudy( ...
    ecoflex0050Workbook, config0050);

comparison = mechanics.workflow.compareTensileStudies( ...
    [study0020, study0050], ...
    ["ECOFLEX 00-20", "ECOFLEX 00-50"], ...
    mechanics.config.tensileStudyComparisonConfig());
```

The workflow does not re-import files or rerun specimen processing.

## Test audit

Permanent tests protect:

- study-result validation;
- label count and uniqueness;
- stress- and strain-measure compatibility;
- processed-unit compatibility;
- duplicate specimen identifiers across studies;
- preservation of original identifiers;
- reuse of group curve and metric comparison;
- manifest validation and input equivalence through `runTensileStudy`.

No transitional validation script is retained.

## Historical deferred items

At the time of this audit, the following were still deferred:

- selected constitutive parameter comparison;
- initial shear-modulus comparison;
- consensus-model comparison;
- dedicated study-comparison export and reporting;
- representative validation with two real material workbooks.

Several of these capabilities were implemented later. This list is preserved only as historical context and must not be used to infer current repository gaps.

## Validation recorded at the time

- `tests/test_tensile_study_comparison.m`;
- `tests/test_tensile_study_input_contracts.m`;
- `tests/test_group_comparison.m`;
- `run_all_tests()`;
- `git diff --check` and repository status review.
