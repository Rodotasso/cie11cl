
> **Language / Idioma:** **English** \| [Español](README.es.md)

<!-- README.md is generated from README.Rmd. Please edit that file. -->

# cie11cl

**Data Science for Public Health Group** \| University of Chile

<!-- badges: start -->

[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Data: code
only](https://img.shields.io/badge/data-code%20only-lightgrey.svg)](#design-principle-code-only-data-at-runtime)
<!-- badges: end -->

**Deterministic access to the WHO International Classification of
Diseases, 11th Revision (ICD-11, CIE-11)** in the MMS linearization,
with code lookup, lexical search and ICD-10 → ICD-11 crosswalks carrying
**traceable certainty levels**, oriented to the Chilean health system.

It extends the architecture of
[`ciecl`](https://github.com/RodoTasso/ciecl) (data layer + validation
engine) to the ICD-11 domain and is part of the R ecosystem for clinical
standardization.

## Purpose

`cie11cl` provides reproducible tools to work with ICD-11 in health
research and data analysis in Chile:

- Exact code lookup against a loaded ICD-11 source
- Error-tolerant lexical search (Jaro-Winkler), fully deterministic
- ICD-10 → ICD-11 crosswalks with a fixed, traceable certainty rule
  (1–5)
- Structural validation of **cluster coding** / post-coordination (`&`,
  `/`), with no dependency on the WHO server
- Read-only SQL over an auto-built SQLite cache (indices + FTS5)

## Design principle: code only, data at runtime

The package **ships no classification data**. The ICD-11 database and
the ICD-10 → ICD-11 mapping table are loaded by the user at runtime from
their own local copy (subject to the WHO licence). **No classification
data is versioned in this repository.**

It is **deterministic**: the same input plus the same versioned
reference data always yields the same output, with a traceable rule for
every transformation.

## Installation

``` r
# install.packages("pak")
pak::pak("RodoTasso/cie11cl")

# Alternative with devtools
# devtools::install_github("RodoTasso/cie11cl")

# SQL backend (optional): DBI + RSQLite
install.packages(c("DBI", "RSQLite"))
```

## Quick start

All examples below run on the bundled **synthetic fixture** (made-up
codes such as `AA00`, `AB00.0`, `XA01`), so they work without any
external data.

``` r
library(cie11cl)

# Load the synthetic fixture (no external data required)
cie11_load()

# Exact lookup by code
cie11_lookup("AA00")
cie11_lookup(c("AA00", "ZZ99"))   # unknown codes return a row of NAs

# Deterministic fuzzy search (Jaro-Winkler) over titles / index terms
cie11_search("ejemplo alfa")

# Validate existence, classKind and leaf status
cie11_validate(c("AA00", "ZZ99"))

# ICD-10 -> ICD-11 crosswalk with traceable certainty (1-5)
cie11_map_from_icd10("A000")

# Cluster coding / post-coordination (stem & axis, stems joined by /)
cie11_validate_cluster(c("AB00.0&XA01", "AA00&XA01", "AB00/AC00", "XA01"))
```

### Using your own ICD-11 release

Export your local ICD-11 database and ICD-10 → ICD-11 mapping to UTF-8
CSV (**never committed to the repo**) and load them:

``` r
cie11_load(
  mms = "data/cie11_mms_2026_full.csv",
  map = "data/mapeo_cie10_cie11_completo.csv"
)

cie11_search("fiebre tifoidea")
cie11_map_from_icd10("A010")
```

The MMS source requires columns `code`, `title`, `definition`,
`classKind`, `isLeaf`, `parent`, `indexTerms`, `postcoordinationScale`;
the mapping table requires `cie10_code`, `cie10_desc`, `cie11_code`,
`cie11_title`, `match_type`, `score`.

### SQL backend (optional)

Mirroring `ciecl`, the package **receives no `.db` file**: it lazily
builds a SQLite cache (atomic, versioned by the loaded data, with
indices and FTS5 full-text search) under
`tools::R_user_dir("cie11cl", "data")` from the sources loaded with
`cie11_load()`. Reloading another ICD-11 release invalidates and
rebuilds the cache automatically.

``` r
cie11_load()  # fixture, or your own sources via cie11_load(mms = ..., map = ...)

# Read-only SELECT over the derived cache
cie11_sql("SELECT code, title FROM cie11 WHERE code LIKE 'AB%'")

# Full-text search (FTS5)
cie11_sql("SELECT code FROM cie11_fts WHERE cie11_fts MATCH 'alfa'")

cie11_clear_cache()  # force a rebuild on the next query
```

Available tables: `cie11`, `cie11_map` and `cie11_fts`. Only `SELECT`
queries are allowed (write keywords and multiple statements are
rejected).

## Functions

| Function | Purpose |
|----|----|
| `cie11_load()` | Load the ICD-11 sources (data frame or CSV) at runtime |
| `cie11_lookup()` | Exact entity lookup by code |
| `cie11_search()` | Deterministic fuzzy lexical search (Jaro-Winkler) |
| `cie11_validate()` | Validate existence, `classKind` and leaf status |
| `cie11_map_from_icd10()` | ICD-10 → ICD-11 crosswalk with certainty level (1–5) |
| `cie11_validate_cluster()` | Validate cluster coding / post-coordination (`&`, `/`) |
| `cie11_sql()` | Read-only SELECT over the derived SQLite cache |
| `cie11_clear_cache()` | Delete the SQLite cache to force a rebuild |
| `cie11_disconnect()` | Close the pooled connection without deleting the cache |

### Crosswalk certainty rule (traceable)

| `match_type` / `score`           | Certainty |
|----------------------------------|-----------|
| `EXACT_TITLE`                    | 5         |
| `FUZZY_JW`, score ≥ 0.95         | 4         |
| `FUZZY_JW`, 0.88 ≤ score \< 0.95 | 3         |
| `FUZZY_JW`, 0.80 ≤ score \< 0.88 | 2         |
| otherwise                        | 1         |

## License

MIT (package code). ICD-11 data is property of the WHO and governed by
its licence; it is **not** distributed with this package.

## Author

**Rodolfo Tasso Suazo** \| <rtasso@uchile.cl>

**Data Science for Public Health Group**<br> School of Public Health,
Faculty of Medicine<br> University of Chile

## Links

- **Repository**: <https://github.com/RodoTasso/cie11cl>
- **Report issues**: <https://github.com/RodoTasso/cie11cl/issues>
- **Sibling package (ICD-10)**: <https://github.com/RodoTasso/ciecl>
- **WHO ICD-11**: <https://icd.who.int>
