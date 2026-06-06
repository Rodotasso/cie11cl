
> **Idioma / Language:** **Español** \| [English](README.md)

<!-- README.es.md is generated from README.es.Rmd. Please edit that file. -->

# cie11cl

**Grupo de Ciencia de Datos para la Salud Pública** \| Universidad de
Chile

<!-- badges: start -->

[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Datos: solo
código](https://img.shields.io/badge/datos-solo%20c%C3%B3digo-lightgrey.svg)](#principio-de-diseño-solo-código-datos-en-runtime)
<!-- badges: end -->

**Acceso determinista a la Clasificación Internacional de Enfermedades,
11.ª revisión (CIE-11)** en la linealización MMS, con búsqueda léxica,
validación de códigos y *crosswalks* CIE-10 → CIE-11 con **niveles de
certeza trazables**, orientado al sistema de salud chileno.

Extiende la arquitectura de
[`ciecl`](https://github.com/RodoTasso/ciecl) (capa de datos + motor de
validación) al dominio CIE-11 y forma parte del ecosistema R de
estandarización clínica.

## Propósito

`cie11cl` ofrece herramientas reproducibles para trabajar con CIE-11 en
investigación y análisis de datos de salud en Chile:

- Búsqueda exacta de códigos contra una fuente CIE-11 cargada
- Búsqueda léxica tolerante a errores (Jaro-Winkler), totalmente
  determinista
- *Crosswalks* CIE-10 → CIE-11 con una regla de certeza fija y trazable
  (1–5)
- Validación estructural de **codificación en clúster** /
  post-coordinación (`&`, `/`), sin dependencia del servidor de la OMS
- SQL de solo lectura sobre un cache SQLite autoconstruido (índices +
  FTS5)

## Principio de diseño: solo código, datos en runtime

El paquete **no incluye datos de la clasificación**. La base de datos
CIE-11 y la tabla de mapeo CIE-10 → CIE-11 las carga el usuario en
tiempo de ejecución desde su propia copia local (sujeta a la licencia de
la OMS). **Ningún dato de la clasificación se versiona en este
repositorio.**

Es **determinista**: el mismo input más los mismos datos de referencia
versionados producen siempre el mismo output, con una regla trazable
para cada transformación.

## Instalación

``` r
# install.packages("pak")
pak::pak("RodoTasso/cie11cl")

# Alternativa con devtools
# devtools::install_github("RodoTasso/cie11cl")

# Backend SQL (opcional): DBI + RSQLite
install.packages(c("DBI", "RSQLite"))
```

## Inicio rápido

Todos los ejemplos siguientes corren sobre el **fixture sintético**
incluido (códigos inventados como `AA00`, `AB00.0`, `XA01`), por lo que
funcionan sin datos externos.

``` r
library(cie11cl)

# Cargar el fixture sintético (sin datos externos)
cie11_load()

# Búsqueda exacta por código
cie11_lookup("AA00")
cie11_lookup(c("AA00", "ZZ99"))   # los códigos desconocidos devuelven NA

# Búsqueda difusa determinista (Jaro-Winkler) sobre títulos / términos
cie11_search("ejemplo alfa")

# Validar existencia, classKind y condición de hoja
cie11_validate(c("AA00", "ZZ99"))

# Crosswalk CIE-10 -> CIE-11 con certeza trazable (1-5)
cie11_map_from_icd10("A000")

# Codificación en clúster / post-coordinación (stem & eje; stems unidos por /)
cie11_validate_cluster(c("AB00.0&XA01", "AA00&XA01", "AB00/AC00", "XA01"))
```

### Con tu propia release de CIE-11

Exporta tu base de datos CIE-11 local y el mapeo CIE-10 → CIE-11 a CSV
UTF-8 (**nunca al repo**) y cárgalos:

``` r
cie11_load(
  mms = "data/cie11_mms_2026_full.csv",
  map = "data/mapeo_cie10_cie11_completo.csv"
)

cie11_search("fiebre tifoidea")
cie11_map_from_icd10("A010")
```

La fuente MMS requiere las columnas `code`, `title`, `definition`,
`classKind`, `isLeaf`, `parent`, `indexTerms`, `postcoordinationScale`;
la tabla de mapeo requiere `cie10_code`, `cie10_desc`, `cie11_code`,
`cie11_title`, `match_type`, `score`.

### Backend SQL (opcional)

Igual que en `ciecl`, el paquete **no recibe ningún archivo `.db`**:
construye de forma perezosa un cache SQLite (atómico, versionado por los
datos, con índices y búsqueda de texto completo FTS5) en
`tools::R_user_dir("cie11cl", "data")` a partir de las fuentes cargadas
con `cie11_load()`. Recargar otra release de CIE-11 invalida y
reconstruye el cache automáticamente.

``` r
cie11_load()  # fixture, o tus propias fuentes con cie11_load(mms = ..., map = ...)

# SELECT de solo lectura sobre el cache derivado
cie11_sql("SELECT code, title FROM cie11 WHERE code LIKE 'AB%'")

# Búsqueda de texto completo (FTS5)
cie11_sql("SELECT code FROM cie11_fts WHERE cie11_fts MATCH 'alfa'")

cie11_clear_cache()  # fuerza la reconstrucción en la próxima consulta
```

Tablas disponibles: `cie11`, `cie11_map` y `cie11_fts`. Solo se permiten
consultas `SELECT` (se rechazan palabras clave de escritura y statements
múltiples).

## Funciones

| Función | Propósito |
|----|----|
| `cie11_load()` | Carga las fuentes CIE-11 (data frame o CSV) en runtime |
| `cie11_lookup()` | Búsqueda exacta de entidades por código |
| `cie11_search()` | Búsqueda léxica difusa determinista (Jaro-Winkler) |
| `cie11_validate()` | Valida existencia, `classKind` y condición de hoja |
| `cie11_map_from_icd10()` | Crosswalk CIE-10 → CIE-11 con nivel de certeza (1–5) |
| `cie11_validate_cluster()` | Valida codificación en clúster / post-coordinación (`&`, `/`) |
| `cie11_sql()` | Consulta SELECT (solo lectura) sobre el cache SQLite derivado |
| `cie11_clear_cache()` | Elimina el cache SQLite para forzar su reconstrucción |
| `cie11_disconnect()` | Cierra la conexión pooled sin borrar el cache |

### Regla de certeza del crosswalk (trazable)

| `match_type` / `score`           | Certeza |
|----------------------------------|---------|
| `EXACT_TITLE`                    | 5       |
| `FUZZY_JW`, score ≥ 0.95         | 4       |
| `FUZZY_JW`, 0.88 ≤ score \< 0.95 | 3       |
| `FUZZY_JW`, 0.80 ≤ score \< 0.88 | 2       |
| resto                            | 1       |

## Licencia

MIT (código del paquete). Los datos CIE-11 son propiedad de la OMS y se
rigen por su licencia; **no** se distribuyen con este paquete.

## Autor

**Rodolfo Tasso Suazo** \| <rtasso@uchile.cl>

**Grupo de Ciencia de Datos para la Salud Pública**<br> Escuela de Salud
Pública, Facultad de Medicina<br> Universidad de Chile

## Enlaces

- **Repositorio**: <https://github.com/RodoTasso/cie11cl>
- **Reportar problemas**: <https://github.com/RodoTasso/cie11cl/issues>
- **Paquete hermano (CIE-10)**: <https://github.com/RodoTasso/ciecl>
- **OMS CIE-11**: <https://icd.who.int>
