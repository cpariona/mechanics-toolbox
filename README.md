# mechanics-toolbox

MATLAB toolbox for reproducible processing, constitutive fitting, statistical
analysis, and peak/post-peak characterization of uniaxial mechanical-test data.

## Maintained scope

- workbook and delimited-file import;
- vendor-specific Zwick D412 extraction;
- preservation of raw experimental data;
- preprocessing and stress-strain conversion;
- tangent-modulus estimation;
- Neo-Hookean, Mooney-Rivlin, and Yeoh models;
- bounded nonlinear parameter fitting;
- fit uncertainty, identifiability, residual, and stability diagnostics;
- reliability-aware model comparison and selection;
- dataset quality assessment;
- pre-peak curve segmentation;
- peak, post-peak, and energy descriptors without rupture classification;
- replicate population statistics and bootstrap intervals;
- group comparison and selected-parameter inference;
- tensile and compression study workflows;
- measurement-aware Monte Carlo refitting;
- end-to-end study execution, figures, and reporting.

## Repository layout

```text
src/+mechanics/   Maintained package implementation
examples/         Runnable user workflows
tests/            Automated regression tests
docs/             User, reference, and development documentation
startup.m         Adds maintained folders to the MATLAB path
run_all_tests.m   Runs the complete repository test suite
```

Root-level processing functions are not maintained. Public code should use the
package API under `src/+mechanics`.

Local experimental workbooks belong under `data/raw/` and generated outputs
under `results/`. Both locations are ignored by Git and must not be committed.

## Setup

```matlab
startup
```

## Validation

```matlab
results = run_all_tests();
```

See [`docs/development/testing.md`](docs/development/testing.md) for focused test
execution and release validation.

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

## Complete compression population study

```matlab
config = mechanics.config.compressionPopulationConfig();
config.defaultInitialLength = 25;
config.studyConfig.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/compression-population";

study = mechanics.workflow.runCompressionPopulationStudy( ...
    "compression_manifest.csv", config);
```

## Constitutive study workflow

The maintained workflow supports specimen-level diagnostics, model comparison,
batch selection, selected-parameter summaries, group inference, and integrated
reporting. These operations are exposed through `mechanics.workflow` and
`mechanics.io`.

## Constitutive models

Registered models:

- `neo-hookean`;
- `mooney-rivlin`;
- `yeoh`.

## Documentation

Start at [`docs/README.md`](docs/README.md). Documentation is organized into
workflows, data handling, technical reference, and repository development.

## Architecture

Input/output, extraction, preprocessing, mechanics, constitutive models,
fitting, quality assessment, segmentation, statistics, plotting, and workflow
orchestration remain separate.

Model functions only evaluate constitutive equations. They do not read files,
modify experimental data, plot, or invoke optimizers.
