# Final repository cleanup audit

This audit follows completion and validation of the tensile-study phase-2 functionality.

## Decisions completed

### Preferred tensile entrypoint

`mechanics.workflow.runTensileStudy` is the maintained end-to-end tensile entrypoint. Workbook, file-list, manifest, and pre-extracted dataset inputs converge to one downstream study contract.

### Legacy manifest processor retained

`mechanics.workflow.processBatchManifest` is retained for now because it has distinct behavior:

- row-oriented status records;
- explicit skipped rows;
- independent failure capture per manifest row;
- optional per-specimen fitting and export;
- mixed tension and compression processing through `TestType`.

It is not a group-comparison pipeline and is not the recommended entrypoint for new end-to-end tensile studies.

The preferred future migration is not to expand this function under its current name. Instead:

1. introduce a comparison workflow that accepts completed `runTensileStudy` results;
2. reuse maintained group and population functions;
3. preserve each study result unchanged;
4. return a comparison result with explicit group labels;
5. rename the old row processor only as part of a documented migration, for example to `processSpecimenManifest`;
6. deprecate the old name only after consumers and tests are migrated.

A candidate future API is:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);
```

### Documentation status

The phase-2 follow-up document now records completed functionality rather than future plans. The tensile input contract is indexed from `docs/README.md`, and group comparison is documented as a downstream analysis responsibility.

The transitional real-data input-equivalence script was removed after merge. Automated equivalence tests remain because they protect the canonical workbook, manifest, and dataset contracts.

## Test audit

No behavioral test was removed from `test_batch_processing.m` because the public legacy entrypoint remains supported. Its tests establish distinct behavior that is not fully covered elsewhere:

- manifest defaults and validation;
- text conversion for `Include`;
- processing multiple rows;
- recording row-level failures;
- preserving skipped rows;
- exporting the batch summary.

The input-contract equivalence tests also remain. They are no longer migration-only tests; they are regression tests for supported public input forms.

Tests should be removed only together with the corresponding public contract or when a strictly stronger test covers the same behavior without preserving obsolete semantics.

## Duplication findings

### Manifest import configuration

`processBatchManifest` and `normalizeTensileStudyInput` both translate manifest columns into specimen import configuration. This duplication is real, but consolidation is deferred because the two entrypoints currently have different result contracts and supported behaviors. A shared internal helper would be reasonable only if it can preserve both contracts without becoming a new public API.

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

Do not remove an entrypoint solely because a newer workflow overlaps with it. Removal requires either:

- full migration of its distinct behavior;
- a documented deprecation period; or
- evidence that the behavior is obsolete and unused.

## Validation required before merge

- focused tests for any changed implementation file;
- `run_all_tests()`;
- `studies/tension/run_tensile_experiment.m` when executable behavior changes;
- `git diff --check` and repository status review.
