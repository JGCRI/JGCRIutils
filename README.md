# JGCRIutils
Common utilities for [JGCRI](http://www.globalchange.umd.edu) work, to save people work and assist in documentation and reproducibility. In progress.

## Installing
To install this package:

1. Make sure you have `devtools` installed from CRAN and loaded.
2. `install_github("JGCRI/JGCRIutils")`

Then:

```R
library(JGCRIutils)
help(package = 'JGCRIutils')
```

## Logging

Three functions - `openlog()`, `printlog()`, `closelog()` - provide logging of script output. Lightweight but provides priority levels, custom logfiles, capturing all output (via `sink`), etc. See documentation.
