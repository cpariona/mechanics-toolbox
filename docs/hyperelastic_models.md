# Hyperelastic models

Phase 2 introduces constitutive equations only. Numerical fitting remains outside this layer.

## Common interface

```matlab
stress = mechanics.models.evaluateModel(modelName, deformation, parameters, context);
```

`context.inputMeasure` accepts:

- `"engineering-strain"` (default), with `lambda = 1 + strain`;
- `"true-strain"`, with `lambda = exp(strain)`;
- `"stretch"`.

`context.outputStressMeasure` accepts:

- `"nominal"` (default), equivalent to uniaxial first Piola-Kirchhoff stress;
- `"cauchy"`.

All initial models assume incompressible, isotropic, uniaxial deformation.

## Neo-Hookean

Parameters: `mu`.

Nominal stress:

```text
P = mu (lambda - lambda^(-2))
```

## Mooney-Rivlin

Parameters: `C10`, `C01`.

Nominal stress:

```text
P = 2 C10 (lambda - lambda^(-2)) + 2 C01 (1 - lambda^(-3))
```

## Yeoh

Parameters: `C10`, `C20`, `C30`.

With:

```text
q = I1 - 3 = lambda^2 + 2 lambda^(-1) - 3
```

Nominal stress:

```text
P = 2 (C10 + 2 C20 q + 3 C30 q^2) (lambda - lambda^(-2))
```

## Design rule

Model functions do not read files, preprocess curves, plot figures, choose parameters, or call optimizers. They only evaluate constitutive equations.
