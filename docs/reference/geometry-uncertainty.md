# Measurement uncertainty propagation

The uniaxial workflow supports two complementary uncertainty calculations.

## Pointwise geometry uncertainty

Standard uncertainty in initial gauge length and initial cross-sectional area can be propagated to each reported strain and stress value.

```matlab
config = mechanics.config.tensionConfig();
config.uncertainty.geometry.enabled = true;
config.uncertainty.geometry.initialLengthStd = 0.10; % mm
config.uncertainty.geometry.initialAreaStd = 0.20;   % mm^2
```

The implementation uses first-order propagation with numerical central differences. Results are stored under:

```text
specimen.analysis.geometryUncertainty
```

and are added to specimen-level CSV exports.

## Monte Carlo uncertainty of fitted parameters

Measurement uncertainty can also be propagated through constitutive refitting. Each realization perturbs the configured inputs, recomputes stress and strain, and refits the selected model.

Supported standard uncertainties are:

```text
initialLengthStd
initialAreaStd
forceStd
displacementStd
```

For tensile dataset analysis:

```matlab
config = mechanics.config.tensileStudyConfig();
config.datasetAnalysis.fitting.enabled = true;
mc = config.datasetAnalysis.fitting.measurementMonteCarlo;
mc.enabled = true;
mc.sampleCount = 500;
mc.initialLengthStd = 0.10;
mc.initialAreaStd = 0.20;
mc.forceStd = 0.01;
mc.displacementStd = 0.005;
config.datasetAnalysis.fitting.measurementMonteCarlo = mc;
```

For compression:

```matlab
config = mechanics.config.compressionStudyConfig();
config.fitting.enabled = true;
config.fitting.geometryMonteCarlo.enabled = true;
config.fitting.geometryMonteCarlo.sampleCount = 500;
config.fitting.geometryMonteCarlo.initialLengthStd = 0.10;
config.fitting.geometryMonteCarlo.initialAreaStd = 0.20;
config.fitting.geometryMonteCarlo.forceStd = 0.01;
config.fitting.geometryMonteCarlo.displacementStd = 0.005;
```

Results include parameter samples, percentile limits, median estimates, and the successful refit fraction.

## Interpretation

Pointwise standard uncertainties are not confidence intervals. Monte Carlo percentile intervals depend on the supplied measurement model and standard uncertainties. They should remain distinct from residual bootstrap intervals and between-specimen population variability.

The default calibrated gauge length for the compression population workflow is 25 mm when the manifest does not provide `InitialLength`. Its uncertainty is never invented automatically; `initialLengthStd` must be supplied from calibration or measurement information.
