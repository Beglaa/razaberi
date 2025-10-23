## Library module for cross-module export testing
## Uses variantExport to create exported variants for cross-module usage

import ../../variant_dsl

# Variant types explicitly exported using variantExport macro
variantExport Result:
  Success(value: string)
  Error(message: string)

# Another variant with multiple constructors
variantExport Status:
  Ready()
  Running(progress: int)
  Completed(output: string)
  Failed(error: string)

# Variant with multi-param constructors
variantExport Point:
  Cartesian(x: int, y: int)
  Polar(r: float, theta: float)
