# Processing pipeline

1. Import raw force and displacement without modification.
2. Validate required fields and vector lengths.
3. Remove invalid points, select a sample window, zero signals, and optionally smooth.
4. Compute engineering or true uniaxial measures.
5. Compute tangent modulus from the processed stress-strain curve.
6. Plot or export results without recalculating them.

Each stage returns data and configuration explicitly. No function depends on global variables or hard-coded experiment paths.
