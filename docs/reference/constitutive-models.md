# Constitutive model reference

The toolbox evaluates registered incompressible, isotropic, uniaxial hyperelastic models through:

```matlab
stress = mechanics.models.evaluateModel( ...
    modelName, deformation, parameters, context);
```

## Experimental deformation and stress measures

For processed uniaxial data, `mechanics.config.tensionConfig()` controls the experimental measures:

```matlab
config.mechanics.strainMeasure = "engineering"; % or "true"
config.mechanics.stressMeasure = "engineering"; % or "true"
```

When true stress is requested, `areaEvolution` accepts:

- `"incompressible"`: current area is `A0/lambda`;
- `"poisson-power"`: current area is `A0*lambda^(-2*nu)`;
- `"measured-area"`: current area is read point by point from `raw.currentArea`.

Measured area is preferable when a synchronized optical or imaging measurement is available:

```matlab
config.mechanics.stressMeasure = "true";
config.mechanics.areaEvolution = "measured-area";
```

The current-area vector must use the same observation count as force and displacement and must contain positive finite values. The resulting Cauchy stress is calculated directly as force divided by measured current area.

## Constitutive deformation and stress measures

`context.inputMeasure` accepts:

- `"engineering-strain"`, with `lambda = 1 + strain`;
- `"true-strain"`, with `lambda = exp(strain`);
- `"stretch"`.

`context.outputStressMeasure` accepts:

- `"nominal"`, equivalent to uniaxial first Piola-Kirchhoff stress;
- `"cauchy"`.

## Neo-Hookean

Parameter: `mu`.

```text
P = mu (lambda - lambda^(-2))
```

## Mooney-Rivlin

Parameters: `C10`, `C01`.

```text
P = 2 C10 (lambda - lambda^(-2))
  + 2 C01 (1 - lambda^(-3))
```

## Yeoh

Parameters: `C10`, `C20`, `C30`.

```text
q = lambda^2 + 2 lambda^(-1) - 3
P = 2 (C10 + 2 C20 q + 3 C30 q^2)
    (lambda - lambda^(-2))
```

Model functions only evaluate constitutive equations. They do not import data, preprocess curves, select fitting windows, optimize parameters, generate figures, or modify experimental records.
