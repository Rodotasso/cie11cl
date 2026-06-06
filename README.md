# cie11cl

Acceso determinista a la Clasificación Internacional de Enfermedades, 11.ª
revisión (CIE-11, linealización MMS) en español, con búsqueda léxica, validación
de códigos y *crosswalks* CIE-10 → CIE-11 con **niveles de certeza trazables**,
orientado al sistema de salud chileno.

Extiende la arquitectura de [`ciecl`](https://github.com/RodoTasso/ciecl)
(capa de datos + motor de validación) al dominio CIE-11. Forma parte del
ecosistema R de estandarización clínica.

## Principio de diseño: solo código, datos en runtime

El paquete **no incluye datos de la clasificación**. La base de datos CIE-11 y la
tabla de mapeo CIE-10 → CIE-11 las carga el usuario en tiempo de ejecución desde
su propia copia local (sujeta a la licencia de la OMS). **Ningún dato de la
clasificación se versiona en este repositorio.**

Es **determinista**: el mismo input más los mismos datos de referencia versionados
producen siempre el mismo output, con una regla trazable para cada transformación.

## Instalación

```r
# install.packages("pak")
pak::pak("RodoTasso/cie11cl")
```

## Uso

```r
library(cie11cl)

# 1) Demostración sin datos externos (fixture sintético):
cie11_load()
cie11_search("ejemplo alfa")
cie11_lookup("XA00")
cie11_map_from_icd10("A000")
cie11_validate_cluster("AB00.0&XA01")  # post-coordinación (stem & eje)

# 2) Con tu propia base de datos CIE-11 (exportada a CSV, nunca al repo):
cie11_load(
  mms = "data/cie11_mms_2026_full.csv",
  map = "data/mapeo_cie10_cie11_completo.csv"
)
cie11_search("fiebre tifoidea")
cie11_map_from_icd10("A010")

# 3) Backend SQL: consulta directa sobre una base CIE-11 SQLite local
cie11_connect("data/cie11_mms_2026.db")              # tabla por defecto: cie11
cie11_sql("SELECT code, title FROM cie11 WHERE code LIKE '1A%'")
cie11_disconnect()
```

El backend SQL requiere los paquetes `DBI` y `RSQLite` (opcionales). La base de
datos la aporta el usuario; **nunca se versiona en el repo**.

## Funciones

| Función | Propósito |
|---|---|
| `cie11_load()` | Carga las fuentes CIE-11 (data frame o CSV) en runtime |
| `cie11_lookup()` | Búsqueda exacta de entidades por código |
| `cie11_search()` | Búsqueda léxica difusa (Jaro-Winkler) por título / términos |
| `cie11_validate()` | Valida existencia, `classKind` y condición de hoja |
| `cie11_map_from_icd10()` | Crosswalk CIE-10 → CIE-11 con nivel de certeza (1–5) |
| `cie11_validate_cluster()` | Valida codificación en clúster / post-coordinación (`&`, `/`) |
| `cie11_connect()` | Conecta a una base CIE-11 SQLite local (pooled) |
| `cie11_sql()` | Consulta SELECT (solo lectura) sobre la base conectada |
| `cie11_disconnect()` | Cierra la conexión |

### Regla de certeza del crosswalk (trazable)

| `match_type` / `score` | Certeza |
|---|---|
| `EXACT_TITLE` | 5 |
| `FUZZY_JW`, score ≥ 0.95 | 4 |
| `FUZZY_JW`, 0.88 ≤ score < 0.95 | 3 |
| `FUZZY_JW`, 0.80 ≤ score < 0.88 | 2 |
| resto | 1 |

## Licencia

MIT (código). Los datos CIE-11 son propiedad de la OMS y se rigen por su licencia;
no se distribuyen con este paquete.
