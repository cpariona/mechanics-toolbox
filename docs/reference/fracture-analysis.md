# Curve segmentation and tensile fracture analysis

## Pre-fracture segmentation

Constitutive analysis should use the loading response before fracture or machine return. The segmentation workflow identifies peak force, selects the configured analysis endpoint, and preserves the complete raw acquisition separately.

```matlab
config = mechanics.config.curveSegmentationConfig();
segmentation = mechanics.segmentation.segmentTensileCurve(raw, config);
```

The original vectors remain in `specimen.raw`; the selected constitutive interval is stored in `specimen.analysisRaw`.

## Fracture metrics

```matlab
config = mechanics.config.fractureAnalysisConfig();
metrics = mechanics.analysis.computeFractureMetrics(specimen, config);
```

Reported quantities include peak force and displacement, peak stress and strain, minimum post-peak force, final force, post-peak drop fraction, residual force fraction, fracture flags, energy to peak, total recorded work, and energy density to peak.

Fracture detection uses:

```matlab
config.fractureDetectionDropFraction = 0.20;
```

Complete fracture additionally requires the configured post-peak drop and residual-force thresholds.

Fracture analysis does not require segmentation metadata. Setting `config.enabled = false` leaves specimen records unchanged and returns an empty fracture summary.

## Energy convention

With force in newtons and displacement in millimetres:

```text
N mm = mJ
```

Dividing by initial volume in cubic millimetres gives:

```text
N mm / mm^3 = N/mm^2 = MPa = mJ/mm^3
```

`totalRecordedEnergy` is signed force-displacement work when `integrateAbsoluteDisplacement` is false. Machine return or unloading can reduce it, so it must not automatically be interpreted as absorbed fracture energy.

## Workflow and export

```matlab
analysis = mechanics.workflow.addFractureMetrics(analysis, config);
files = mechanics.io.exportFractureAnalysis(analysis, outputFolder);
```

Classification is descriptive and does not alter specimen-quality status.
