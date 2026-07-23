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

## Where standard uncertainties should come from

The toolbox never invents uncertainty values. Each standard uncertainty must represent the measurement process used for the specimen.

### Initial gauge length

`initialLengthStd` is not the tolerance of the ASTM specimen drawing by itself. It should describe uncertainty in the actual reference length used to convert displacement into strain.

Use one of the following, in order of preference:

1. a calibration certificate or uncertainty statement for the extensometer, crosshead reference, fixture spacing, or gauge-length measurement;
2. repeated measurements of the gauge length or fixture spacing;
3. instrument resolution combined with setup repeatability;
4. a documented manufacturing tolerance only when the analysis truly assumes the molded geometry rather than a measured reference length.

If the same rigid mold defines a nominal 25 mm gauge length but the actual reference length is not measured for every specimen, 25 mm remains the nominal value. A nonzero `initialLengthStd` should still be used when mold tolerance, placement, clamping, or measurement repeatability can change the effective gauge length. If these effects are negligible or no defensible estimate exists, leave the value as `NaN` and report that gauge-length uncertainty was not propagated.

### Initial area

`initialAreaStd` should be derived from the measured specimen dimensions, not from the nominal mold dimensions alone. For a rectangular section with width `b` and thickness `h`:

```text
A0 = b h
```

For independent standard uncertainties `u_b` and `u_h`:

```text
u_A = sqrt((h u_b)^2 + (b u_h)^2)
```

If the workbook contains repeated width and thickness measurements in a statistics sheet, their standard deviations or standard uncertainties can be used to estimate `u_b` and `u_h`. The current extractor reads nominal geometry fields used by the workflow but does not yet infer `initialAreaStd` automatically from a statistics table; this value must be supplied explicitly after confirming the workbook layout and meaning of those statistics.

### Force

`forceStd` is not the configured preload. Preload defines the mechanical zero or contact condition. Force uncertainty should come from the load-cell calibration certificate, accuracy specification, resolution, repeatability, or a verified combination of these terms.

A manufacturer accuracy stated as a maximum error is not automatically a standard deviation. It must be converted according to the assumed distribution before being entered as `forceStd`.

### Displacement

`displacementStd` is not the commanded displacement or test setting. It should describe uncertainty in the measured extension used by the analysis. Sources may include extensometer calibration, crosshead encoder accuracy, machine compliance correction, resolution, and setup repeatability.

When strain is computed from crosshead displacement, machine and grip compliance may dominate the uncertainty even if encoder resolution is small.

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
