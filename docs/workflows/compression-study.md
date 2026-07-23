# Compression study

The compression workflow imports one tabular specimen, detects complete preparation cycles, selects the configured cycle and branch, normalizes the compression sign convention, and runs the common uniaxial processing pipeline.

```matlab
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 10;
config.geometry.initialArea = 100;

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.csv", config);
```

## Required input

The source file must contain numeric force and displacement columns recognized by `mechanics.config.excelImportConfig`. Optional time data are preserved.

## Cycle selection

Defaults:

```matlab
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
```

Use `loadingDirection = "decreasing"` when instrument displacement becomes more negative during compression. `branch` also accepts `unloading` and `full-cycle`.

The detected cycle boundaries and selected indices are stored in:

```text
study.cycle.detectedCycles
study.cycle.selectedCycleIndex
study.cycle.cycleStartIndex
study.cycle.loadingEndIndex
study.cycle.cycleEndIndex
study.cycle.selectedIndices
```

## Sign convention

The default convention is positive compression:

```matlab
config.signConvention = "positive-compression";
```

The selected force and displacement branch is reoriented so loading increments are positive. Set `instrument` to preserve imported signs.

## Mechanical processing

The selected branch is processed with `mechanics.config.compressionConfig`, including zero-reference correction, engineering or true measures, and tangent-modulus estimation. Preload or contact thresholds can be configured through:

```matlab
config.processing.preprocessing.zeroReference.method = "preload-threshold";
config.processing.preprocessing.zeroReference.preloadForce = 0.1;
```

## Cycle metrics

The complete selected cycle is retained separately from the branch used for fitting or modulus estimation. The workflow reports:

```text
study.cycleMetrics.peakForce
study.cycleMetrics.peakDisplacement
study.cycleMetrics.peakStress
study.cycleMetrics.peakStrain
study.cycleMetrics.loadingEnergy
study.cycleMetrics.recoveredEnergy
study.cycleMetrics.hysteresisEnergy
study.cycleMetrics.hysteresisFraction
study.cycleMetrics.hysteresisEnergyDensity
```

With force in N and displacement in mm, the force-displacement energies are in mJ. Hysteresis is the loading work minus the recovered unloading work.

## Export and figures

```matlab
config.export.enabled = true;
config.export.outputFolder = "results/compression-study";
config.export.report.studyTitle = "Compression test";

study = mechanics.workflow.runCompressionStudy(filename, config);
```

The export bundle contains:

```text
compression_processed.csv
compression_cycle_metrics.csv
compression_study.mat
report/report.md
report/compression_cycle.png
report/compression_response.png
report/compression_tangent_modulus.png
```

The cycle figure distinguishes loading and unloading. The response figure uses the configured selected branch. The tangent-modulus figure marks the strain range used for the summary value.

Cycle detection, contact detection, and sign normalization remain configuration-dependent and should be checked visually for a new machine format or protocol.