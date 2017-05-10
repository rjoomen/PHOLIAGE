# PHOLIAGE
Photosynthesis and Light Absorption Model

## Details

PHOLIAGE is a 3D model that calculates light absorption and photosynthesis for trees in opened canopies (e.g. for enrichment planting). For a full description, see the [model description](doc/PHOLIAGE_Model-Report_20070305.pdf) and the [program manual](doc/PHOLIAGE_Model-Program_Manual.pdf).

![PHOLIAGE schematic](doc/PHOLIAGE_schematic.png)
*Figure 1: Schematic representation of a tree in a canopy as modelled in PHOLIAGE.*

A related model for closed canopies is [StratiPHOLIAGE](https://github.com/rjoomen/StratiPHOLIAGE).

### Literature

Studies that have used the model:

[Van Kuijk _et al._, 2014.](https://www.researchgate.net/publication/264199801_Stimulating_seedling_growth_in_early_stages_of_secondary_forest_succession_A_modeling_approach_to_guide_tree_liberation) Stimulating seedling growth in early stages of secondary forest succession: A modeling approach to guide tree liberation

[Van Kuijk _et al._, 2008.](https://www.researchgate.net/publication/5264252_The_limited_importance_of_size-asymmetric_light_competition_and_growth_of_pioneer_species_in_early_secondary_forest_succession_in_Vietnam) The limited importance of size-asymmetric light competition and growth of pioneer species in early secondary forest succession in Vietnam

## Implementation details

### Lazarus / Delphi

The original version was written in Delphi. This is the version ported to Lazarus / FPC.

Main functional changes
- Supports multiple platforms (Linux, Windows, and macOS).
- Reads *.xls, *.xlsx, and *.ods files natively (previous version used Windows-only Excel OLE automation).
- Removed Windows/Delphi-specific multithreading code (too much work to port).
- Removed some initial code for a planned extension for lane-based simulations.

For further details, see the [changelog](doc/changelog.txt).

### Numerical differences between versions

Between versions 0.3 and 0.5 exist small differences in the results, for which the changelog does not give an explanation. Correlation (R²) between results from both versions is still almost 1, as tested with the example data.

Between versions 0.5 and 1.0.0 exist negligible differences (~1e-13), and the differences between the Win64 and Linux/Win32 versions are even smaller.

Model results can differ slightly between Linux/Win32 builds and Win64 builds, because on Win64 the 80-bit floating point `Extended` datatype is not supported. The Math unit therefore internally uses Double (64 bit) instead of Extended, leading to minute differences. This is not a problem, the loss in precision is negligible, and the PHOLIAGE model itself uses Double for all calculations anyway. For details see for example [this forum post](http://forum.lazarus.freepascal.org/index.php?topic=29678.0), and the source code of the Math unit.

## Running

Binary releases are available under the [releases tab](https://github.com/rjoomen/PHOLIAGE/releases).

For usage details see the [program manual](doc/PHOLIAGE_Model-Program_Manual.pdf).

## Compiling/Modifying

1. Install [Lazarus](https://www.lazarus-ide.org/)
2. Install [FPSpreadSheet](http://wiki.freepascal.org/FPSpreadsheet)
3. Check out the sources ('Clone or download' button above)
4. Open project file `PHOLIAGE.lpi` in Lazarus and press F9 to run.
