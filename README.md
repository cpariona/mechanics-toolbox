# mechanics-toolbox

MATLAB toolbox for reproducible processing, constitutive fitting, statistical
analysis, and fracture characterization of uniaxial mechanical-test data.

## Current scope

- workbook and delimited-file import;
- vendor-specific Zwick D412 extraction;
- preservation of raw experimental data;
- preprocessing and stress-strain conversion;
- tangent-modulus estimation;
- Neo-Hookean, Mooney-Rivlin, and Yeoh models;
- bounded nonlinear parameter fitting;
- deformation-window model selection;
- dataset quality assessment;
- pre-fracture curve segmentation;
- replicate population statistics and bootstrap intervals;
- two-group comparisons;
- tensile fracture metrics;
- end-to-end study execution and export.

## Setup and validation

```matlab
startup
results = run_all_tests();
```

## Complete tensile study

```matlab
config = mechanics.config.tensileStudyConfig();

config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";

study = mechanics.workflow.runTensileStudy( ...
    "data/raw/test.xlsx", config);
```

Outputs:

```text
study.dataset
study.analysis
study.population
study.provenance
study.config
study.outputFiles
```

## Constitutive models

Registered models:

- `neo-hookean`;
- `mooney-rivlin`;
- `yeoh`.

## Architecture

Input/output, extraction, preprocessing, mechanics, constitutive models,
fitting, quality assessment, segmentation, statistics, plotting, and workflow
orchestration remain separate.

Model functions only evaluate constitutive equations. They do not read files,
modify experimental data, plot, or invoke optimizers.
