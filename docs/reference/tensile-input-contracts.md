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

`processingHistory` is optional for pre-extracted datasets. The uniaxial workflow initializes it when absent.

The downstream stages remain unchanged:

```text
analyzeExtractedDataset
addPeakMetrics
analyzeSpecimenPopulation
exportTensileStudy
```

## Automatic input detection

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

The former row-oriented `processBatchManifest` pipeline was removed. Manifest input is now maintained only through the common `runTensileStudy` result contract.

The manifest is an ingestion description. It is not a statistical design or a request to compare experimental groups.

## Comparing completed studies

A campaign with one workbook per material or condition should process each workbook independently and then compare the completed studies:

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

The comparison workflow:

1. validates completed study contracts;
2. validates compatible stress and strain measures;
3. validates processed units;
4. preserves the original studies unchanged;
5. creates namespaced comparison identifiers to prevent collisions;
6. preserves original specimen identifiers separately;
7. reuses `assignSpecimenGroups` and `analyzeGroupComparison`;
8. does not re-import or reprocess raw data.

The initial comparison result includes:

```text
comparison.groupLabels
comparison.studySummaries
comparison.compatibility
comparison.groupComparison
comparison.config
comparison.createdAt
```

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

Provenance supports both historical single-source fields and multi-source fields:

```text
study.provenance.sourceFile
study.provenance.sourceFileName
study.provenance.sourceFiles
study.provenance.sourceFileNames
study.provenance.inputType
```

For a dataset without physical source files, source fields are empty while analysis provenance remains available.

## Downstream equivalence

Input type affects extraction and provenance only. Equivalent raw data and geometry must produce the same:

```text
study.analysis.summary
processed strain curves
processed stress curves
peak metrics
population result contract
```

Automated regression tests compare workbook, manifest, and pre-extracted dataset paths to ensure equivalent downstream results.
