# Tensile fracture analysis

Phase 12 adds descriptive fracture metrics after pre-fracture segmentation.
Phase 26 removes the previous configuration dependency between segmentation and fracture detection.

## Metrics

Per specimen:

- peak force;
- displacement at peak force;
- peak nominal stress;
- strain at peak;
- post-peak force drop;
- residual force fraction;
- energy to peak;
- total recorded force-displacement work;
- energy density to peak;
- complete-fracture classification.

## Fracture detection and complete fracture

Fracture detection uses its own threshold:

```matlab
config.fractureDetectionDropFraction = 0.20;
```

A specimen is classified as a complete fracture when:

```text
fractureDetected == true
postPeakDropFraction >= completeFractureDropFraction
residualForceFraction <= residualForceFraction threshold
```

Defaults:

```matlab
config.fractureDetectionDropFraction = 0.20;
config.completeFractureDropFraction = 0.90;
config.residualForceFraction = 0.10;
```

Fracture analysis no longer requires `specimen.segmentation` to exist. Classification is descriptive and does not alter specimen quality.

When:

```matlab
config.enabled = false;
```

`addFractureMetrics` leaves specimen records unchanged and returns an empty `fractureSummary`.

## Energy and work convention

Energy to peak is calculated as:

```text
trapz(displacement(1:peakIndex), force(1:peakIndex))
```

With force in newtons and displacement in millimetres:

```text
N * mm = N mm = mJ
```

Energy density divides energy to peak by initial specimen volume. With volume in cubic millimetres:

```text
N mm / mm^3 = N/mm^2 = MPa = mJ/mm^3
```

`totalRecordedEnergy` is the signed force-displacement work over the recorded acquisition when `integrateAbsoluteDisplacement` is false. It can decrease during machine return or unloading and should not automatically be interpreted as absorbed fracture energy.

When `integrateAbsoluteDisplacement` is true, displacement coordinates are made nonnegative before numerical integration. This changes the integration convention and still does not constitute a dedicated dissipated-energy estimate.

## Workflow

```matlab
analysis = mechanics.workflow.addFractureMetrics(analysis, config);
```

Results are stored in:

```text
analysis.records(i).specimen.fracture
analysis.fractureSummary
```
