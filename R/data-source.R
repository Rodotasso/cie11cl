# Cache interno de la conexion SQLite pooled derivada del dataset embebido
# (o de datos de usuario, si se cargaron con cie11_load()).
.cie11_env <- new.env(parent = emptyenv())
.cie11_env$con          <- NULL
.cie11_env$db_path      <- NULL
.cie11_env$mms          <- NULL   # NULL => usar cie11_mms embebido
.cie11_env$mms_embedded <- NULL   # cache del dataset embebido (cargado lazy)
.cie11_env$map          <- NULL   # NULL => sin crosswalk (tabla vacia en SQLite)

# Columnas requeridas cuando el usuario aporta sus propios datos con cie11_load().
# El dataset embebido cie11_mms ya garantiza estas columnas.
.cie11_mms_cols <- c(
  "uri_id", "code", "title", "definition", "classKind",
  "isLeaf", "parent_id", "chapter", "level",
  "indexTerms", "postcoordinationScale"
)
.cie11_map_cols <- c(
  "cie10_code", "cie10_desc", "cie11_code",
  "cie11_title", "match_type", "score"
)

#' Cargar fuentes de datos CIE-11 personalizadas / Load custom ICD-11 data
#'
#' Por defecto el paquete usa el dataset embebido `cie11_mms` (WHO MMS 2026,
#' 37.212 entidades en espanol). Llama a esta funcion solo si necesitas usar
#' una release diferente o un crosswalk CIE-10->CIE-11 propio.
#'
#' By default the package uses the bundled `cie11_mms` dataset (WHO MMS 2026,
#' 37,212 entities in Spanish). Call this function only to override with a
#' different release or your own ICD-10->ICD-11 crosswalk.
#'
#' @param mms Data frame o ruta CSV con la linealizacion MMS de CIE-11.
#'   Columnas requeridas: `uri_id`, `code`, `title`, `definition`,
#'   `classKind`, `isLeaf`, `parent_id`, `chapter`, `level`,
#'   `indexTerms`, `postcoordinationScale`. Pasa `NULL` para volver al
#'   dataset embebido. /
#'   Data frame or CSV path with ICD-11 MMS linearization. Pass `NULL`
#'   to revert to the bundled dataset.
#' @param map Data frame o ruta CSV con el mapeo CIE-10->CIE-11.
#'   Columnas requeridas: `cie10_code`, `cie10_desc`, `cie11_code`,
#'   `cie11_title`, `match_type`, `score`. /
#'   Data frame or CSV path with ICD-10 to ICD-11 mapping.
#' @return Invisiblemente `TRUE`. / Invisibly `TRUE`.
#' @examples
#' # Volver al dataset embebido / revert to bundled dataset:
#' cie11_load()
#'
#' \dontrun{
#' # Release personalizada exportada a CSV / custom release exported to CSV:
#' cie11_load(mms = "mi_release_cie11.csv")
#' }
#' @export
cie11_load <- function(mms = NULL, map = NULL) {
  if (!is.null(.cie11_env$con)) cie11_disconnect()
  if (is.null(mms) && is.null(map)) {
    .cie11_env$mms <- NULL
    .cie11_env$map <- NULL
    return(invisible(TRUE))
  }
  if (!is.null(mms)) .cie11_env$mms <- .cie11_read(mms, .cie11_mms_cols)
  if (!is.null(map)) .cie11_env$map <- .cie11_read(map, .cie11_map_cols)
  invisible(TRUE)
}

# Lee un data frame o CSV validando columnas requeridas.
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
    stop("`mms`/`map` must be a data frame or a CSV file path.", call. = FALSE)
  }
  faltantes <- setdiff(required, names(x))
  if (length(faltantes)) {
    stop("Missing required columns: ", paste(faltantes, collapse = ", "),
      call. = FALSE
    )
  }
  x
}

# Retorna la tabla MMS activa: dataset embebido (cargado una vez) o datos del usuario.
.cie11_mms <- function() {
  if (!is.null(.cie11_env$mms)) return(.cie11_env$mms)
  if (!is.null(.cie11_env$mms_embedded)) return(.cie11_env$mms_embedded)
  e <- new.env(parent = emptyenv())
  utils::data("cie11_mms", envir = e, package = "cie11cl")
  .cie11_env$mms_embedded <- e$cie11_mms
  .cie11_env$mms_embedded
}

# Retorna la tabla de mapeo activa (data frame vacio si no se cargo ninguna).
.cie11_map <- function() {
  if (is.null(.cie11_env$map)) {
    return(data.frame(
      cie10_code = character(), cie10_desc = character(),
      cie11_code = character(), cie11_title = character(),
      match_type = character(), score = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  .cie11_env$map
}
