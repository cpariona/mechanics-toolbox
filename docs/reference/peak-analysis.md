# Curve segmentation and peak analysis

## Pre-peak segmentation

Constitutive analysis should use the loading response before specimen rupture or machine return. The segmentation workflow identifies peak force, selects the configured analysis endpoint, and preserves the complete raw acquisition separately.

```matlab
config = mechanics.config.curveSegmentationConfig();
segmentation = mechanics.segmentation.segmentTensileCurve(raw, config);
```

The original vectors remain in `specimen.raw`; the selected constitutive interval is stored in `specimen.analysisRaw`.

## Peak and post-peak metrics

```matlab
config = mechanics.config.peakAnalysisConfig();
metrics = mechanics.analysis.computePeakMetrics(specimen, config);
```

Reported quantities include peak force and displacement, peak stress and its corresponding strain, minimum post-peak force, final force, post-peak drop fraction, residual force fraction, energy to peak, total recorded work, and energy density to peak.

These quantities describe the recorded response. They do not classify specimen rupture.

## Energy convention

With force in newtons and displacement in millimetres:

```text
N mm = mJ
```

Dividing by initial volume in cubic millimetres gives:

```text
N mm / mm^3 = N/mm^2 = MPa = mJ/mm^3
```

`totalRecordedEnergy` is signed force-displacement work when `integrateAbsoluteDisplacement` is false. Machine return or unloading can reduce it, so it must not automatically be interpreted as absorbed failure energy.

## Workflow and export

```matlab
analysis = mechanics.workflow.addPeakMetrics(analysis, config);
files = mechanics.io.exportPeakAnalysis(analysis, outputFolder);
```

Peak and post-peak metrics do not alter specimen-quality status.
