## Submission cie11cl 0.1.0

First submission of `cie11cl` to CRAN.

## Summary

`cie11cl` provides deterministic access to the WHO International Classification
of Diseases, 11th Revision (ICD-11, MMS linearization) in Spanish, with code
lookup, lexical search, hierarchical navigation, cluster validation, ICD-10 to
ICD-11 crosswalks with traceable certainty levels, and a read-only SQL backend
over a derived SQLite cache (indices + FTS5).

The package ships **no classification data**. The ICD-11 database is loaded by
the user at runtime from their own local copy (subject to WHO licence). A
built-in synthetic fixture allows all functions to be exercised without external
data.

## Test results

* **Tests**: PASS, 0 FAIL (testthat edition 3).
* **R CMD check**: 0 errors | 0 warnings | 0 notes.

## Test environments

* Local: Windows 11 x64, R 4.6.0
* GitHub Actions R-CMD-check:
  - macOS-latest (release)
  - windows-latest (release)
  - ubuntu-latest (devel, release, oldrel-1)

## Downstream dependencies

This package has no reverse dependencies.
