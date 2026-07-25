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

The older `processBatchManifest` entrypoint remains available for its original row-oriented batch-processing result contract. New end-to-end tensile studies should use `runTensileStudy` when peak metrics, population analysis, study provenance, and standard reporting are required.

`processBatchManifest` does not compare experimental groups. It processes each manifest row independently and returns row-level records and a processing summary.

## Experimental groups are downstream metadata

Input normalization does not infer or compare material groups. A campaign containing, for example, five ECOFLEX 00-20 specimens and five ECOFLEX 00-50 specimens should first be processed into one study or compatible downstream batch result. Group labels are then assigned explicitly to the specimen identifiers and passed to the maintained group-analysis workflows.

Conceptually:

```matlab
study = mechanics.workflow.runTensileStudy(manifestTable, config);

% Assign one label per processed specimen using the maintained group API.
grouped = mechanics.workflow.assignGroups( ...
    study.analysis, groupAssignments);

comparison = mechanics.workflow.compareGroups( ...
    grouped, groupComparisonConfig);
```

The exact downstream function depends on the quantity being compared:

- population stress-strain response;
- peak or tangent-modulus metrics;
- selected constitutive parameters;
- derived initial shear modulus.

The manifest is therefore an ingestion description, not a statistical design or comparison request.

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

Provenance supports both historical single-source fields and new multi-source fields:

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

A maintained real-data validation is available at:

```text
studies/tension/validate_tensile_input_equivalence.m
```

It extracts the maintained ECOFLEX workbook, runs the workbook and normalized-dataset paths with the same configuration, and checks specimen statuses, summary metrics, processed curves, and population response.
