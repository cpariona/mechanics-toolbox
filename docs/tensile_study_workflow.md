# End-to-end tensile study

Phase 13 introduces:

```matlab
study = mechanics.workflow.runTensileStudy(filename, config);
```

Workflow:

```text
workbook extraction
  -> specimen segmentation and quality
  -> stress-strain processing and fitting
  -> fracture metrics
  -> population analysis
  -> reproducible export
```

Configuration remains nested by responsibility:

```matlab
config = mechanics.config.tensileStudyConfig();

config.extraction
config.datasetAnalysis
config.fracture
config.population
config.export
```

Main outputs:

```text
study.dataset
study.analysis
study.population
study.provenance
study.config
study.outputFiles
```

Population errors may be recorded without discarding specimen-level results:

```text
study.populationStatus
study.populationErrorIdentifier
study.populationErrorMessage
```

The export bundle can contain:

```text
study_summary.csv
dataset_summary.csv
fracture_summary.csv
population_metrics.csv
provenance.csv
tensile_study.mat
study_config.mat
```
