# Final repository cleanup audit

This audit follows completion and validation of the tensile-study phase-2 functionality.

## Decisions completed

### Preferred tensile entrypoint

`mechanics.workflow.runTensileStudy` is the maintained end-to-end tensile entrypoint. Workbook, file-list, manifest, and pre-extracted dataset inputs converge to one downstream study contract.

### Legacy manifest processor scheduled for removal

`mechanics.workflow.processBatchManifest` remains temporarily available, but it is no longer part of the intended long-term architecture.

Its current row-oriented behavior includes:

- explicit skipped rows;
- independent failure capture per manifest row;
- optional per-specimen fitting and export;
- mixed tension and compression processing through `TestType`.

The user's maintained experimental pattern is normally one workbook per material or experimental condition, with several specimens inside each workbook. For that pattern, row-oriented manifest processing is not the desired abstraction. Each material or condition should be processed independently with `runTensileStudy`, and comparison should consume completed study results.

The required migration is:

1. introduce `mechanics.workflow.compareTensileStudies` for completed `runTensileStudy` results;
2. validate compatible stress measure, strain measure, units, and required result fields;
3. preserve each input study unchanged;
4. reuse maintained population and group-comparison functions;
5. support explicit labels such as `"ECOFLEX 00-20"` and `"ECOFLEX 00-50"`;
6. optionally compose selected-parameter and consensus-model comparisons without refitting when compatible results are already present;
7. migrate any remaining maintained use cases from `processBatchManifest`;
8. remove `processBatchManifest`, `batchProcessingConfig`, `exportBatchSummary`, and tests that exist only for that legacy contract.

A candidate API is:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [study0020, study0050], ...
    ["ECOFLEX 00-20", "ECOFLEX 00-50"], ...
    config);
```

Do not rename `processBatchManifest` into the comparison workflow. Processing manifest rows and comparing completed studies are different responsibilities.

The legacy API must not be removed in this cleanup-only branch because the replacement does not yet exist. Its removal belongs in the future functional branch that implements and validates `compareTensileStudies`.

### Documentation status

The phase-2 follow-up document now records completed functionality rather than future plans. The tensile input contract is indexed from `docs/README.md`, and group comparison is documented as a downstream analysis responsibility.

The transitional real-data input-equivalence script was removed after merge. Automated equivalence tests remain because they protect the canonical workbook, manifest, and dataset contracts.

## Test audit

No behavioral test was removed from `test_batch_processing.m` in this branch because the public legacy entrypoint still exists. Its tests establish behavior that must remain stable until the migration branch removes the API:

- manifest defaults and validation;
- text conversion for `Include`;
- processing multiple rows;
- recording row-level failures;
- preserving skipped rows;
- exporting the batch summary.

When `processBatchManifest` is removed, delete or migrate these tests in the same change. Tests for `validateBatchManifest` should remain only if manifests continue to be supported by `runTensileStudy`.

The input-contract equivalence tests also remain. They are not migration-only tests; they are regressions for supported public input forms.

Tests should be removed only together with the corresponding public contract or when a strictly stronger test covers the same behavior without preserving obsolete semantics.

## Duplication findings

### Manifest import configuration

`processBatchManifest` and `normalizeTensileStudyInput` both translate manifest columns into specimen import configuration. Do not consolidate this duplication before the legacy API is removed. The preferred endpoint is deletion of the duplicate path, not a shared helper that prolongs both contracts.

### Plotting and export

Exporters remain responsible for file creation and may call maintained plotting functions. No plotting API was removed because figure generation is used by report and export tests. Future consolidation should target repeated formatting or file-writing code only after identifying exact duplication.

### Study driver

`studies/tension/run_tensile_experiment.m` intentionally contains experiment-specific configuration and optional downstream analyses. It should not absorb reusable implementation. Cleanup should remove only obsolete switches or comments that no longer match supported contracts.

## Configuration audit boundary

No configuration field is removed in this cleanup without all of the following:

1. no implementation consumer;
2. no maintained study or example consumer;
3. no behavioral test establishing the contract;
4. no dynamic or nested configuration use.

Consumer counts alone are insufficient evidence for removal.

## Public API removal boundary

Do not remove an entrypoint solely because a newer workflow overlaps with it. Removal requires a validated replacement and migration of maintained consumers and tests.

For `processBatchManifest`, that replacement is explicitly planned as `compareTensileStudies`; deletion should occur in the same functional sequence once the new workflow passes focused tests, the complete suite, and representative two-study validation.

## Validation required before merge

- focused tests for any changed implementation file;
- `run_all_tests()`;
- `studies/tension/run_tensile_experiment.m` when executable behavior changes;
- `git diff --check` and repository status review.
