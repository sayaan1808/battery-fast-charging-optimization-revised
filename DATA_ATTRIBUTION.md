# Public experimental data attribution

**Title:** Experimental data for "Development of Experimental Techniques for Parameterization of Multi-scale Lithium-ion Battery Models".

**Creators:** Chang-Hui Chen, Ferran Brosa Planella, Kieran O'Regan, Dominika Gastol, W. Dhammika Widanage and Emma Kendrick.

**Source:** [Zenodo record 4032561](https://zenodo.org/records/4032561), DOI [10.5281/zenodo.4032561](https://doi.org/10.5281/zenodo.4032561). Related article: [10.1149/1945-7111/ab9050](https://doi.org/10.1149/1945-7111/ab9050).

**License:** [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/). The project MIT license does not replace this license.

The three files in `raw/` retain the downloaded contents. SHA-256 checksums and download URLs are in `source_manifest.json`. Derived files in `processed/` split the records by cycle and step, reset time to each step's start, assign positive current to charging and negative current to discharging, and rename columns with units. MATLAB native parsing and feature extraction are in `../matlab/battery_diagnostics.m`; derived measurements and diagnostics retain this attribution. No endorsement by the data creators is implied.

`REFERENCE_LICENSE.txt` additionally preserves the original BSD notice for the third-party reference source from which these public records were obtained. It is not the dataset's CC license. `DATA_ATTRIBUTION.json` retains the structured Zenodo metadata.
