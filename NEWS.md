# cie11cl 0.1.0 (2026-06-10)

*English summary below*

## Primera version publica

Primer lanzamiento de `cie11cl`: acceso determinista a la Clasificacion Internacional
de Enfermedades 11.a revision (CIE-11, linealizacion MMS) en espanol, con validacion
de codigos, busqueda lexical, navegacion jerarquica y crosswalks CIE-10 -> CIE-11
con niveles de certeza trazables.

### Funciones exportadas

* **`cie11_load()`**: carga las fuentes CIE-11 en memoria (CSV o data frame). Incluye
  un fixture sintetico que permite usar el paquete sin datos externos.
* **`cie11_lookup()`**: busqueda exacta por codigo; codigos desconocidos devuelven
  una fila de `NA` en vez de error.
* **`cie11_search()`**: busqueda lexical tolerante a errores (Jaro-Winkler),
  completamente determinista.
* **`cie11_validate()`**: valida existencia, `classKind` y estado de hoja.
* **`cie11_map_from_icd10()`**: crosswalk CIE-10 -> CIE-11 con nivel de certeza 1-5
  segun regla fija y trazable.
* **`cie11_validate_cluster()`**: valida codificacion en cluster / post-coordinacion
  (`&`, `/`) sin dependencia del servidor OMS.
* **`cie11_sql()`**: consultas SELECT sobre la cache SQLite derivada (indices + FTS5).
* **`cie11_clear_cache()`**: elimina la cache SQLite para forzar reconstruccion.
* **`cie11_disconnect()`**: cierra la conexion pooled sin eliminar la cache.
* **`cie11_ancestors()`**, **`cie11_children()`**, **`cie11_subtree()`**: navegacion
  jerarquica (ancestros, hijos directos, subarbol completo).

### Diseno

* Backend SQL: cache SQLite derivada de los datos cargados (atomica, versionada,
  con indices y FTS5). El paquete **no incluye ningun archivo `.db`**; la cache se
  construye en `tools::R_user_dir("cie11cl", "data")` al primer uso.
* Sin datos clasificacion en el repositorio: el dataset CIE-11 MMS 2026 fue
  construido y esta disponible localmente, pero **no se incluye en esta version
  del paquete** (licencia OMS). Los usuarios deben aportar sus propias fuentes
  al llamar a `cie11_load()`. El fixture sintetico permite probar todas las
  funciones sin datos externos.
* El mismo input mas los mismos datos de referencia versionados siempre produce
  el mismo output, con regla trazable para cada transformacion.

### Infraestructura

* CI/CD: R-CMD-check multi-plataforma (macOS, Windows, Ubuntu), cobertura,
  lint (lintr), pkgcheck rOpenSci, pkgdown.
* Tests: suite testthat edicion 3.
* Archivos de comunidad: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`.
* Metadatos: `codemeta.json`, `.zenodo.json`.

---

## First public release

First release of `cie11cl`: deterministic access to the World Health Organization
International Classification of Diseases, 11th Revision (ICD-11, MMS linearization)
in Spanish, with code lookup, lexical search, hierarchical navigation, and
ICD-10 -> ICD-11 crosswalks with traceable certainty levels.

### Key notes on data

The WHO ICD-11 MMS 2026 dataset has been built and is available locally, but is
**not included in this version of the package** (WHO licence). Users must supply
their own sources via `cie11_load()`. A built-in synthetic fixture allows all
functions to be exercised without any external data.
