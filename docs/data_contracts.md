# Data contracts

## Raw curve

Required fields:

- `force`: numeric vector.
- `displacement`: numeric vector of equal length.

Optional field:

- `units`: structure containing explicit unit strings.

## Processed curve

`mechanics.preprocessing.prepareCurve` returns a new structure containing the untouched input in `raw`, processed force and displacement, original sample indices, units, configuration, and a processing history.

## Geometry

The Phase 1 uniaxial contract requires positive finite scalar values:

- `initialLength`
- `initialArea`

Consistent input units are the caller's responsibility. With force in N and area in mm^2, stress is numerically in MPa.
