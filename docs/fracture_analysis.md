# Tensile fracture analysis

Phase 12 adds descriptive fracture metrics after pre-fracture segmentation.

## Metrics

Per specimen:

- peak force;
- displacement at peak force;
- peak nominal stress;
- strain at peak;
- post-peak force drop;
- residual force fraction;
- energy absorbed up to peak;
- total recorded force-displacement energy;
- energy density up to peak;
- complete-fracture classification.

## Complete fracture

A specimen is classified as a complete fracture when:

```text
postPeakDropFraction >= completeFractureDropFraction
residualForceFraction <= residualForceFraction threshold
```

Defaults:

```matlab
config.completeFractureDropFraction = 0.90;
config.residualForceFraction = 0.10;
```

Classification is descriptive and does not alter specimen quality.

## Energy

Energy to peak is calculated as:

```text
trapz(displacement(1:peakIndex), force(1:peakIndex))
```

Energy density divides this quantity by the initial specimen volume.

## Workflow

```matlab
analysis = mechanics.workflow.addFractureMetrics(analysis, config);
```

Results are stored in:

```text
analysis.records(i).specimen.fracture
analysis.fractureSummary
```
