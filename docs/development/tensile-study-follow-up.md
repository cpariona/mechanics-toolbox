# Tensile-study follow-up scope

This document records the next bounded development scope after the executable tensile study driver is established.

## Viability audit

The current architecture can support the planned additions without replacing the core tensile workflow:

- the existing population analysis already defines a common strain grid, interpolation, central statistics, and bootstrap intervals for stress-strain curves;
- every processed specimen already stores its complete tangent-modulus curve;
- batch model comparison already preserves successful model fits for each specimen;
- selected-parameter population analysis already separates parameters by model family and parameter name;
- group inference and integrated constitutive reporting already consume selected-parameter population results.

The remaining work is therefore additive, except for batch-manifest contract unification.

## Population tangent modulus

Add a population tangent-modulus result analogous to the current population stress-strain result:

```text
study.population.tangentModulus.strain
study.population.tangentModulus.modulusMatrix
study.population.tangentModulus.centralModulus
study.population.tangentModulus.confidenceLower
study.population.tangentModulus.confidenceUpper
study.population.tangentModulus.centralStatistic
```

Implementation should:

1. use a common strain interval supported by the required number of specimens;
2. interpolate `tangentModulusForPlot`, not recompute derivatives during plotting;
3. reuse the configured population central statistic and bootstrap settings;
4. preserve individual interpolated curves for diagnostics;
5. export `population_tangent_modulus` through the tensile-study report.

This is a moderate, self-contained extension of population analysis.

## Selected-parameter figures

The existing `summarizeSelectedParameters` workflow requires a batch model-comparison result because it extracts the model selected for each specimen. It is not produced directly by `runTensileStudy`, which is why it was not previously part of the core study driver. The driver now contains an optional block that constructs the required comparison input from processed tensile specimens.

Add two maintained figures:

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
neo-hookean:   mu0 = mu
mooney-rivlin: mu0 = 2 * (C10 + C01)
yeoh:          mu0 = 2 * C10
```

Plot specimen values plus central and interval summaries. Preserve model identity because the derived value does not make the complete constitutive models interchangeable.

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

## Batch-manifest contract unification

`processBatchManifest` currently returns a batch-processing result, while `runTensileStudy` returns a tensile-study result with peak analysis, population analysis, provenance, and study reporting.

A future migration should normalize workbook, manifest, pre-extracted dataset, and file-list inputs to one extracted-dataset contract before the common tensile analysis stages. Until that migration is complete, the study driver must keep batch-manifest execution disabled and explicit.

## Validation required

The follow-up work should include:

- focused tests for interpolation bounds and missing tangent-modulus support;
- deterministic bootstrap tests;
- parameter-family separation tests;
- analytical tests for derived initial shear modulus;
- consensus-model tests covering ties, insufficient eligibility, and parsimony;
- regression tests proving workbook and future manifest inputs produce the same downstream study contract.
