# Curve segmentation and tensile peak analysis

## Loading-curve segmentation

Constitutive analysis uses the loading response up to peak force or a configured fraction of peak force. The complete raw acquisition remains preserved separately.

```matlab
config = mechanics.config.curveSegmentationConfig();
segmentation = mechanics.segmentation.segmentTensileCurve(raw, config);
```

The original vectors remain in `specimen.raw`; the selected constitutive interval is stored in `specimen.analysisRaw`. The segmentation result reports peak location, analysis endpoint, and post-peak drop fraction, but it does not classify fracture.

## Peak and post-peak metrics

```matlab
config = mechanics.config.fractureAnalysisConfig();
metrics = mechanics.analysis.computeFractureMetrics(specimen, config);
```

Despite the retained function name, the maintained output is a peak-metric description rather than a fracture classifier. Reported quantities include:

- peak force and displacement;
- peak stress and the strain at the peak-stress index;
- minimum post-peak force and final force;
- post-peak drop fraction and residual-force fraction;
- energy to peak;
- total recorded force-displacement work;
- energy density to peak.

No `fractureDetected` or `completeFracture` field is produced.

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

Setting `config.enabled = false` leaves specimen records unchanged and returns an empty peak-metric summary.