# Tensile-study follow-up scope

This document records the bounded development scope after the executable tensile study driver was established and validated.

## Baseline status

The preceding study-driver scope is complete. The user reported that:

- the complete MATLAB test suite passes;
- the complete real tensile experiment driver runs successfully;
- no active assignments remain for the removed fitting-context fields.

The phase-2 work began from updated `main` on:

```text
feature/tensile-population-tangent-modulus
```

## Viability audit

The current architecture can support the planned additions without replacing the core tensile workflow:

- population analysis defines a common strain grid, interpolation, central statistics, and bootstrap intervals;
- every processed tensile specimen stores its complete tangent-modulus curve and a plot-oriented version with leading unstable values suppressed;
- batch model comparison preserves successful model fits for each specimen;
- selected-parameter population analysis separates parameters by model family and parameter name;
- group inference and integrated constitutive reporting consume selected-parameter population results.

The remaining work is additive, except for input-contract unification.

## Implementation order

Use separate, bounded commits and split the work into more than one branch when necessary:

1. population tangent-modulus analysis and reporting;
2. selected-parameter and derived shear-modulus figures;
3. study-level consensus model;
4. input-contract unification for workbook, file-list, pre-extracted dataset, and manifest inputs;
5. final repository cleanup after all functional work is validated.

The input-contract migration is architectural and should remain separate if it expands beyond a small adapter layer.

## Population tangent modulus

Implementation status: functionally complete and validated on `feature/tensile-population-tangent-modulus`.

The result contract is:

```text
study.population.tangentModulus.strain
study.population.tangentModulus.modulusMatrix
study.population.tangentModulus.centralModulus
study.population.tangentModulus.confidenceLower
study.population.tangentModulus.confidenceUpper
study.population.tangentModulus.specimenCountByPoint
study.population.tangentModulus.centralStatistic
study.population.tangentModulusStatus
```

Implemented behavior:

1. uses a continuous strain interval supported by at least the configured `minimumSpecimens`;
2. interpolates `tangentModulusForPlot` and does not recompute derivatives;
3. reuses the population central statistic and bootstrap settings;
4. preserves individual interpolated curves for diagnostics;
5. exports `population_tangent_modulus.csv`;
6. exports a population tangent-modulus figure through the maintained tensile-study figure exporter;
7. leaves stress population and group-comparison workflows operational when tangent-modulus data are unavailable.

The strict statistics entrypoint still rejects malformed or insufficient tangent-modulus inputs when called directly. Optional availability is handled by `analyzeSpecimenPopulation`, not by weakening `aggregateTangentModulus`.

Representative real-data validation completed on 24 July 2026 using `studies/tension/run_tensile_experiment.m`:

- four specimens were processed after one configured exclusion;
- population analysis completed without quality or processing failures;
- the tangent-modulus population used 201 strain-grid points;
- the valid strain interval was approximately 0.06699 to 6.67366 engineering strain;
- pointwise support ranged from two to four specimens;
- the central modulus and both bootstrap limits were finite at every grid point;
- the complete MATLAB test suite passed after regression repair for group comparison.

## Selected-parameter figures

The existing `summarizeSelectedParameters` workflow requires a batch model-comparison result because it extracts the model selected for each specimen. It is not produced directly by `runTensileStudy`. The study driver contains an optional block that constructs the required comparison input from processed tensile specimens.

Add two maintained figures.

### Native parameters by selected model

Plot individual values and summary statistics separately for every model and parameter combination. Do not pool parameters across model families.

Examples:

```text
neo-hookean / mu
mooney-rivlin / C10
mooney-rivlin / C01
yeoh / C10
yeoh / C20
yeoh / C30
```

### Initial shear modulus by specimen

Derive a common small-strain shear modulus:

```text
neo-hookean:    mu0 = mu
mooney-rivlin: mu0 = 2 * (C10 + C01)
yeoh:          mu0 = 2 * C10
```

Plot specimen values plus central and interval summaries. Preserve model identity because the derived value does not make the complete constitutive models interchangeable.

Before adding new plotting entrypoints, audit the existing selected-parameter plotting and constitutive-report exporters. Extend maintained entrypoints instead of creating parallel figures with overlapping responsibilities.

## Study-level consensus model

Determine one consensus model for the experiment using specimen-level evidence rather than majority vote or only the population curve.

For every candidate model:

1. fit the same model to every processed specimen;
2. calculate successful-fit and eligible-fit fractions;
3. summarize normalized RMSE, BIC, and parameter stability across specimens;
4. require a configurable minimum eligible fraction;
5. select the lowest median BIC among accepted models;
6. treat practically equivalent models as ties and prefer the model with fewer parameters;
7. summarize the selected model parameters across specimens using median and bootstrap intervals.

Proposed result contract:

```text
study.consensusModel.modelName
study.consensusModel.eligibleFraction
study.consensusModel.metricSummary
study.consensusModel.parameterTable
study.consensusModel.parameterSummary
study.consensusModel.reason
```

A fit to the population central curve may be exported as a complementary visualization, but it should not replace specimen-level consensus selection.

Before implementation, define the tie tolerance, minimum eligible fraction, missing-specimen behavior, and whether the consensus analysis belongs inside `runTensileStudy` or in a composable downstream workflow.

## Input-contract unification

`processBatchManifest` currently returns a batch-processing result, while `runTensileStudy` returns a tensile-study result with peak analysis, population analysis, provenance, and study reporting.

A future migration should normalize these input forms before the common tensile analysis stages:

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

All should converge to one extracted-dataset contract and one downstream tensile-study result contract.

Until that migration is complete, the study driver must keep batch-manifest execution disabled and explicit. Do not add a superficial switch that returns incompatible result shapes under the same variable name.

## Validation status

Population tangent-modulus validation completed:

- interpolation and minimum-support tests;
- deterministic mean and median bootstrap tests;
- missing tangent-modulus compatibility with group comparison;
- population export tests;
- tensile-study figure and Markdown report tests;
- complete MATLAB suite execution;
- representative real-data execution through `studies/tension/run_tensile_experiment.m`;
- inspection of the populated tangent-modulus result and generated study artifacts.

Repository diff and whitespace checks remain part of branch-closing review before pull-request preparation.

Future blocks still require:

- parameter-family separation tests;
- analytical tests for derived initial shear modulus;
- consensus-model tests covering ties, insufficient eligibility, and parsimony;
- regression tests proving each supported input form produces the same downstream study contract.

## Cleanup after functional completion

Perform cleanup only after the phase-2 functionality is stable. Audit:

- duplicate model-comparison and population paths;
- plotting/export overlap;
- configuration fields without effective consumers;
- public APIs with no maintained use case;
- duplicated code in the study driver;
- obsolete documentation and examples;
- naming and result-contract consistency.

Consumer counts are screening evidence, not sufficient justification for deletion.
