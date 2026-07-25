# Tensile-study input contracts

`mechanics.workflow.runTensileStudy` accepts several input forms, but all are normalized before analysis to one extracted-dataset contract.

## Supported inputs

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

The normalization entrypoint is:

```matlab
[dataset, inputInfo] = mechanics.workflow.normalizeTensileStudyInput( ...
    inputValue, config);
```

Every supported input converges to:

```text
dataset.specimens
```

Each specimen must satisfy the maintained extraction contract:

```text
specimen.id
specimen.raw.force
specimen.raw.displacement
specimen.geometry.initialLength
specimen.geometry.initialArea
specimen.source
```

The downstream stages remain unchanged:

```text
analyzeExtractedDataset
addPeakMetrics
analyzeSpecimenPopulation
exportTensileStudy
```

## Automatic input detection

Default configuration:

```matlab
config = mechanics.config.tensileStudyConfig();
config.input.type = "auto";
```

Automatic rules:

```text
scalar struct with specimens -> dataset
table                        -> manifest
scalar text                  -> workbook
text vector                  -> file-list
```

A manifest stored in a CSV or workbook should be explicit because scalar text otherwise represents a specimen workbook:

```matlab
config.input.type = "manifest";
study = mechanics.workflow.runTensileStudy(manifestFile, config);
```

## Workbook

```matlab
config = mechanics.config.tensileStudyConfig();
study = mechanics.workflow.runTensileStudy(workbookFile, config);
```

The historical workbook behavior and `mechanics:workflow:StudyFileNotFound` error contract are preserved.

## File list

```matlab
files = ["specimen-1.xlsx"; "specimen-2.xlsx"];
config = mechanics.config.tensileStudyConfig();
study = mechanics.workflow.runTensileStudy(files, config);
```

Every workbook is extracted with the same extraction configuration. The resulting specimens are concatenated before exclusions and downstream analysis.

## Batch manifest

The manifest must satisfy `mechanics.workflow.validateBatchManifest`. Required columns are:

```text
File
SpecimenId
InitialLength
InitialArea
```

Optional maintained columns include:

```text
Include
Sheet
ForceScale
DisplacementScale
TimeScale
CurrentAreaScale
ForceColumn
DisplacementColumn
TimeColumn
CurrentAreaColumn
TestType
```

Example:

```matlab
config = mechanics.config.tensileStudyConfig();
config.input.type = "manifest";
study = mechanics.workflow.runTensileStudy(manifestTable, config);
```

A maintained executable example is available at:

```text
studies/tension/run_tensile_manifest_example.m
```

The older `processBatchManifest` entrypoint remains available for its original batch-processing result contract. New end-to-end tensile studies should use `runTensileStudy` when peak metrics, population analysis, study provenance, and standard reporting are required.

## Pre-extracted dataset

```matlab
config = mechanics.config.tensileStudyConfig();
study = mechanics.workflow.runTensileStudy(dataset, config);
```

The dataset is validated but not re-extracted. This path is intended for programmatic ingestion, testing, or custom extraction performed before the maintained study workflow.

## Normalized input metadata

The study result records:

```text
study.input.type
study.input.sourceFiles
study.input.primarySource
study.input.specimenCount
study.sourceFiles
```

Provenance supports both historical single-source fields and new mult-source fields:

```text
study.provenance.sourceFile
study.provenance.sourceFileName
study.provenance.sourceFiles
study.provenance.sourceFileNames
study.provenance.inputType
```

For a dataset without physical source files, the source fields are empty strings or empty arrays while analysis provenance remains available.

## Downstream equivalence

Input type affects extraction and provenance only. Equivalent raw data and geometry must produce the same:

```text
study.analysis.summary
processed strain curves
processed stress curves
peak metrics
population result contract
```

Regression tests compare workbook, manifest, and pre-extracted dataset paths to ensure they converge to equivalent downstream results.
