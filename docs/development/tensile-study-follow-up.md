# Tensile-study development status

This document records the completed phase-2 tensile-study work and the remaining maintenance scope.

## Completed functionality

The maintained tensile workflow now includes:

- end-to-end workbook execution through `runTensileStudy`;
- population stress-strain aggregation and bootstrap intervals;
- population tangent-modulus aggregation;
- specimen-level constitutive model comparison;
- selected-parameter population summaries and derived initial shear modulus;
- study-level consensus constitutive model selection;
- group comparison and group parameter inference as downstream workflows;
- standard CSV, MAT, PNG, and Markdown reporting;
- normalized workbook, file-list, manifest, and pre-extracted dataset inputs.

All supported input forms converge to the extracted-dataset contract before the common analysis stages. The historical workbook result contract and error identifiers remain compatible.

## Validation completed

The completed work has been validated through:

- focused automated tests for each added workflow;
- the complete MATLAB test suite;
- the maintained real tensile experiment;
- inspection of generated tables and figures;
- real workbook versus normalized-dataset equivalence checks.

Representative real-data validation used the maintained ECOFLEX tensile workbook. Four specimens were processed after one configured exclusion. Population analysis and constitutive downstream workflows completed successfully.

## Maintained workflow boundaries

`mechanics.workflow.runTensileStudy` is the preferred end-to-end tensile entrypoint. It accepts:

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

`mechanics.workflow.processBatchManifest` remains a legacy row-oriented processor. It imports and processes each manifest row independently and can optionally fit and export each specimen. It does not perform population aggregation, experimental group comparison, consensus-model selection, or integrated tensile-study reporting.

Group comparison is not an input responsibility. Experimental group labels are assigned after specimens have been processed, and the maintained group-analysis workflows consume those labeled results.

## Remaining maintenance work

The remaining work is repository maintenance rather than missing tensile functionality:

1. remove documentation that describes merged functionality as future work;
2. clarify maintained versus legacy entrypoints;
3. audit duplicate import and export helpers before consolidation;
4. audit configuration fields against real consumers;
5. review naming and terminology across public result contracts;
6. remove only APIs or examples that have no maintained consumer and no distinct use case;
7. run the complete MATLAB suite and representative real study after cleanup.

Do not remove `processBatchManifest` solely because `runTensileStudy` accepts manifests. Its row-level failure recording, skipped-row representation, per-specimen export, and mixed tension/compression support are distinct behaviors. Deprecation or removal requires either migration of those behaviors or evidence that they are no longer needed.
