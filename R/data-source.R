# Cache interno de las fuentes de datos CIE-11 cargadas.
.cie11_env <- new.env(parent = emptyenv())

# Columnas requeridas en cada fuente.
.cie11_mms_cols <- c(
  "code", "title", "definition", "classKind",
  "isLeaf", "parent", "indexTerms", "postcoordinationScale"
)
.cie11_map_cols <- c(
  "cie10_code", "cie10_desc", "cie11_code",
  "cie11_title", "match_type", "score"
)

#' Cargar las fuentes de datos CIE-11 / Load ICD-11 data sources
#'
#' Carga la tabla MMS de CIE-11 y la tabla de mapeo CIE-10 -> CIE-11 en el cache
#' interno del paquete. El paquete distribuye **solo codigo**: el usuario aporta
#' su propia release de CIE-11 y su tabla de mapeo, ya sea como data frames en
#' memoria o como rutas a archivos CSV exportados desde su base de datos local.
#' Ningun dato de la clasificacion viene incluido en el paquete.
#'
#' Llamada sin argumentos, carga un pequeno fixture sintetico (codigos
#' inventados, no contenido real de la OMS) para que ejemplos y tests puedan
#' ejecutarse sin datos externos.
#'
#' Loads the ICD-11 MMS table and the ICD-10 to ICD-11 mapping table into the
#' package's internal cache. The package ships code only: users supply their own
#' ICD-11 release and mapping table, as data frames or as paths to CSV files. No
#' classification data is bundled. Called with no arguments, a small synthetic
#' fixture is loaded so examples and tests can run without external data.
#'
#' @param mms Data frame, o ruta a un CSV UTF-8, con la linealizacion MMS de
#'   CIE-11. Columnas requeridas: `code`, `title`, `definition`, `classKind`,
#'   `isLeaf`, `parent`, `indexTerms`, `postcoordinationScale`. /
#'   A data frame or path to a UTF-8 CSV with the ICD-11 MMS linearization.
#' @param map Data frame, o ruta a un CSV UTF-8, con el mapeo CIE-10 -> CIE-11.
#'   Columnas requeridas: `cie10_code`, `cie10_desc`, `cie11_code`,
#'   `cie11_title`, `match_type`, `score`. /
#'   A data frame or path to a UTF-8 CSV with the ICD-10 to ICD-11 mapping.
#' @return Invisiblemente `TRUE`. / Invisibly `TRUE`.
#' @examples
#' # Fixture sintetico (sin datos externos) / synthetic fixture:
#' cie11_load()
#'
#' \dontrun{
#' # Tu propia base de datos CIE-11, exportada a CSV (nunca al repo) /
#' # your own local ICD-11 database exported to CSV:
#' cie11_load(
#'   mms = "data/cie11_mms_2026_full.csv",
#'   map = "data/mapeo_cie10_cie11_completo.csv"
#' )
#' }
#' @export
cie11_load <- function(mms = NULL, map = NULL) {
  if (is.null(mms) && is.null(map)) {
    .cie11_env$mms <- .cie11_fixture_mms()
    .cie11_env$map <- .cie11_fixture_map()
    .cie11_env$source <- "fixture"
    return(invisible(TRUE))
  }
  if (!is.null(mms)) .cie11_env$mms <- .cie11_read(mms, .cie11_mms_cols)
  if (!is.null(map)) .cie11_env$map <- .cie11_read(map, .cie11_map_cols)
  .cie11_env$source <- "user"
  invisible(TRUE)
}

# Lee una fuente desde un data frame o una ruta CSV, validando columnas.
.cie11_read <- function(x, required) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop("File not found: ", x, call. = FALSE)
    x <- utils::read.csv(
      x,
      fileEncoding = "UTF-8-BOM",
      stringsAsFactors = FALSE,
      check.names = TRUE
    )
  }
  if (!is.data.frame(x)) {
    stop("`mms`/`map` must be a data frame or a path to a CSV file.",
      call. = FALSE
    )
  }
  faltantes <- setdiff(required, names(x))
  if (length(faltantes)) {
    stop("Missing required columns: ", paste(faltantes, collapse = ", "),
      call. = FALSE
    )
  }
  x
}

# Getters: cargan el fixture sintetico de forma perezosa si aun no hay datos.
.cie11_mms <- function() {
  if (is.null(.cie11_env$mms)) cie11_load()
  .cie11_env$mms
}

.cie11_map <- function() {
  if (is.null(.cie11_env$map)) cie11_load()
  .cie11_env$map
}
