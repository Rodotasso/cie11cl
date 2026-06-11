# Capa SQL: cache SQLite pooled, DERIVADO de los datos cargados en el paquete.
#
# Mismo patron que ciecl: la base SQLite no la aporta el usuario, sino que se
# construye automaticamente (lazy, atomica, versionada) a partir de las fuentes
# CIE-11 cargadas con cie11_load() (o del fixture sintetico). El usuario nunca
# entrega un archivo .db: entrega los datos via cie11_load() y este modulo
# materializa el cache. Las dependencias DBI/RSQLite son opcionales (Suggests):
# se verifican en tiempo de ejecucion.
#
# SQL backend: a pooled SQLite cache DERIVED from the data loaded in the
# package, mirroring ciecl. The SQLite database is not user-supplied; it is
# built automatically (lazy, atomic, versioned) from the ICD-11 sources loaded
# with cie11_load() (or the synthetic fixture). DBI/RSQLite are optional.

# Verifica que DBI y RSQLite esten disponibles.
.cie11_need_dbi <- function() {
  if (!requireNamespace("DBI", quietly = TRUE) ||
      !requireNamespace("RSQLite", quietly = TRUE)) {
    stop(
      "The SQL backend requires the 'DBI' and 'RSQLite' packages. ",
      "Install them with install.packages(c(\"DBI\", \"RSQLite\")).",
      call. = FALSE
    )
  }
}

# Firma deterministica de las fuentes cargadas. Cambia si cambian los datos,
# de modo que recargar otra release de CIE-11 invalida el cache anterior.
.cie11_data_signature <- function() {
  mms <- .cie11_mms()
  map <- .cie11_map()
  paste(
    nrow(mms), ncol(mms),
    nrow(map),
    as.integer(sum(nchar(mms$code))),
    as.integer(sum(nchar(mms$uri_id))),
    sep = "|"
  )
}

# Construye la tabla FTS5 sobre una conexion existente.
.cie11_build_fts <- function(con) {
  DBI::dbExecute(con, "
    CREATE VIRTUAL TABLE IF NOT EXISTS cie11_fts USING fts5(
      code, title, definition, indexTerms,
      content='cie11', content_rowid='rowid'
    )
  ")
  DBI::dbExecute(con, "INSERT INTO cie11_fts(cie11_fts) VALUES('rebuild')")
  invisible(TRUE)
}

# Construye las tablas de post-coordinacion desde el JSON embebido.
# Requiere jsonlite (Suggests). Si no esta disponible, omite silenciosamente.
.cie11_build_postcoord <- function(con, mms) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    if (interactive()) {
      message("Instalar jsonlite para validacion completa de clusters: ",
              "install.packages('jsonlite')")
    }
    return(invisible(FALSE))
  }

  pc_rows <- which(nzchar(mms$postcoordinationScale))
  if (length(pc_rows) == 0L) return(invisible(FALSE))

  axes_list  <- vector("list", length(pc_rows))
  scale_list <- vector("list", length(pc_rows))

  for (k in seq_along(pc_rows)) {
    i      <- pc_rows[k]
    code_i <- mms$code[i]
    json_i <- mms$postcoordinationScale[i]

    axes <- tryCatch(
      jsonlite::fromJSON(json_i, simplifyVector = FALSE),
      error = function(e) NULL
    )
    if (is.null(axes)) next

    a_rows <- vector("list", length(axes))
    s_rows <- vector("list", length(axes))

    for (j in seq_along(axes)) {
      ax      <- axes[[j]]
      ax_name <- basename(ax$axisName)
      req     <- identical(ax$required, "true")
      allow   <- if (is.null(ax$allowMultiple)) NA_character_ else ax$allowMultiple

      a_rows[[j]] <- data.frame(
        code         = code_i,
        axis_name    = ax_name,
        required     = as.integer(req),
        allow_multiple = allow,
        stringsAsFactors = FALSE
      )

      entities <- ax$scaleEntity
      if (length(entities) > 0L) {
        entity_ids <- vapply(entities, function(e) {
          m <- regmatches(e, regexpr("(?<=mms/)(.+)$", e, perl = TRUE))
          if (length(m) == 0L) NA_character_ else m[[1]]
        }, character(1))
        entity_ids <- entity_ids[!is.na(entity_ids)]
        if (length(entity_ids) > 0L) {
          s_rows[[j]] <- data.frame(
            code       = code_i,
            axis_name  = ax_name,
            entity_id  = entity_ids,
            stringsAsFactors = FALSE
          )
        }
      }
    }
    axes_list[[k]]  <- do.call(rbind, a_rows)
    scale_list[[k]] <- do.call(rbind, s_rows)
  }

  axes_df  <- do.call(rbind, axes_list)
  scale_df <- do.call(rbind, scale_list)

  if (!is.null(axes_df) && nrow(axes_df) > 0L) {
    DBI::dbWriteTable(con, "cie11_postcoord_axes", axes_df, overwrite = TRUE)
    DBI::dbExecute(con,
      "CREATE INDEX IF NOT EXISTS idx_pc_axes_code ON cie11_postcoord_axes(code)")
  }
  if (!is.null(scale_df) && nrow(scale_df) > 0L) {
    DBI::dbWriteTable(con, "cie11_postcoord_scale", scale_df, overwrite = TRUE)
    DBI::dbExecute(con,
      "CREATE INDEX IF NOT EXISTS idx_pc_scale ON cie11_postcoord_scale(code, axis_name)")
  }
  invisible(TRUE)
}

# Construye el cache SQLite atomicamente: escribe en un .tmp y renombra al final.
# Si falla en cualquier punto no queda un cache parcial.
.cie11_build_cache_atomic <- function(cache_dir, db_path) {
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)

  mms <- .cie11_mms()
  map <- .cie11_map()
  signature <- .cie11_data_signature()

  tmp_path <- paste0(db_path, ".tmp")
  if (file.exists(tmp_path)) file.remove(tmp_path)

  con <- DBI::dbConnect(RSQLite::SQLite(), tmp_path)
  disconnected <- FALSE
  on.exit({
    if (!disconnected && DBI::dbIsValid(con)) DBI::dbDisconnect(con)
  }, add = TRUE)

  tryCatch({
    DBI::dbWriteTable(con, "cie11",     as.data.frame(mms), overwrite = TRUE)
    DBI::dbWriteTable(con, "cie11_map", as.data.frame(map), overwrite = TRUE)

    # Indices principales.
    DBI::dbExecute(con, "CREATE INDEX idx_cie11_code      ON cie11(code)")
    DBI::dbExecute(con, "CREATE INDEX idx_cie11_uri_id    ON cie11(uri_id)")
    DBI::dbExecute(con, "CREATE INDEX idx_cie11_parent_id ON cie11(parent_id)")
    DBI::dbExecute(con, "CREATE INDEX idx_cie11_chapter   ON cie11(chapter)")
    if (nrow(map) > 0L) {
      DBI::dbExecute(con, "CREATE INDEX idx_map_cie10 ON cie11_map(cie10_code)")
      DBI::dbExecute(con, "CREATE INDEX idx_map_cie11 ON cie11_map(cie11_code)")
    }

    # Tablas de post-coordinacion (para navegacion y validacion de clusters).
    .cie11_build_postcoord(con, mms)

    # Busqueda de texto completo.
    .cie11_build_fts(con)

    # Metadata: firma de los datos para invalidar el cache cuando cambian.
    DBI::dbExecute(con, "
      CREATE TABLE IF NOT EXISTS cie11_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ")
    DBI::dbExecute(
      con,
      "INSERT OR REPLACE INTO cie11_meta (key, value)
       VALUES ('data_signature', ?)",
      params = list(signature)
    )

    DBI::dbDisconnect(con); disconnected <- TRUE

    # Atomico: renombrar .tmp -> .db
    if (file.exists(db_path)) file.remove(db_path)
    file.rename(tmp_path, db_path)
    if (interactive()) message("ICD-11 SQLite cache built: ", db_path)
  }, error = function(e) {
    if (!disconnected && DBI::dbIsValid(con)) DBI::dbDisconnect(con)
    disconnected <<- TRUE
    if (file.exists(tmp_path)) file.remove(tmp_path)
    stop("Error building ICD-11 SQLite cache: ",
      conditionMessage(e), call. = FALSE)
  })
  invisible(TRUE)
}

# TRUE si el cache corresponde a la firma de los datos actualmente cargados.
.cie11_cache_is_current <- function(con) {
  if (!DBI::dbExistsTable(con, "cie11_meta")) return(FALSE)
  tryCatch({
    stored <- DBI::dbGetQuery(
      con, "SELECT value FROM cie11_meta WHERE key = 'data_signature'"
    )
    if (nrow(stored) == 0L) return(FALSE)
    identical(stored$value[1], .cie11_data_signature())
  }, error = function(e) FALSE)
}

# Devuelve una conexion SQLite pooled al cache, construyendolo o reconstruyendolo
# segun corresponda. Lazy: no se crea nada hasta la primera consulta.
.cie11_get_db <- function() {
  .cie11_need_dbi()
  cache_dir <- tools::R_user_dir("cie11cl", "data")
  db_path <- file.path(cache_dir, "cie11.db")

  # Reutilizar conexion pooled si es valida, apunta al mismo path y los datos
  # no han cambiado.
  if (!is.null(.cie11_env$con) &&
      inherits(.cie11_env$con, "SQLiteConnection") &&
      DBI::dbIsValid(.cie11_env$con) &&
      identical(.cie11_env$db_path, db_path)) {
    if (!DBI::dbExistsTable(.cie11_env$con, "cie11_fts")) {
      .cie11_build_fts(.cie11_env$con)
    }
    if (.cie11_cache_is_current(.cie11_env$con)) {
      return(.cie11_env$con)
    }
    suppressWarnings(DBI::dbDisconnect(.cie11_env$con))
    .cie11_env$con <- NULL
    .cie11_env$db_path <- NULL
    .cie11_build_cache_atomic(cache_dir, db_path)
  }

  # Cerrar conexion invalida remanente.
  if (!is.null(.cie11_env$con)) {
    suppressWarnings(try(DBI::dbDisconnect(.cie11_env$con), silent = TRUE))
    .cie11_env$con <- NULL
    .cie11_env$db_path <- NULL
  }

  if (!file.exists(db_path)) .cie11_build_cache_atomic(cache_dir, db_path)

  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)

  # Integridad: la tabla principal y la firma deben estar al dia.
  if (!DBI::dbExistsTable(con, "cie11")) {
    DBI::dbDisconnect(con)
    .cie11_build_cache_atomic(cache_dir, db_path)
    con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  }
  if (!DBI::dbExistsTable(con, "cie11_fts")) .cie11_build_fts(con)
  if (!.cie11_cache_is_current(con)) {
    DBI::dbDisconnect(con)
    .cie11_build_cache_atomic(cache_dir, db_path)
    con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  }

  .cie11_env$con <- con
  .cie11_env$db_path <- db_path
  con
}

#' Consultar la base CIE-11 con SQL / Query the ICD-11 database with SQL
#'
#' Ejecuta una consulta **SELECT** (solo lectura) sobre un cache SQLite que el
#' paquete construye automaticamente a partir de las fuentes cargadas con
#' [cie11_load()] (o del fixture sintetico si no se ha cargado nada). El cache se
#' materializa de forma perezosa en `tools::R_user_dir("cie11cl", "data")`, se
#' versiona segun los datos cargados y se reconstruye solo si cambian. No se
#' requiere ninguna conexion manual ni se aporta archivo `.db` alguno.
#'
#' Tablas disponibles: `cie11` (linealizacion MMS), `cie11_map` (mapeo
#' CIE-10 -> CIE-11) y `cie11_fts` (busqueda de texto completo FTS5 sobre
#' `code`, `title`, `definition`, `indexTerms`).
#'
#' Runs a read-only **SELECT** query against a SQLite cache the package builds
#' automatically from the sources loaded via [cie11_load()] (or the synthetic
#' fixture). The cache is materialized lazily in
#' `tools::R_user_dir("cie11cl", "data")`, versioned by the loaded data and
#' rebuilt only when it changes. No manual connection or user-supplied `.db`
#' file is needed. For safety only SELECT queries are allowed: write keywords
#' and multiple statements are rejected.
#'
#' @param query Una unica consulta SQL SELECT. / A single SELECT SQL query.
#' @return Un data frame con el resultado. / A data frame with the result.
#' @family sql
#' @seealso [cie11_load()], [cie11_clear_cache()], [cie11_disconnect()]
#' @examples
#' \dontrun{
#' cie11_load() # fixture sintetico / synthetic fixture
#' cie11_sql("SELECT code, title FROM cie11 WHERE code LIKE 'AB%'")
#' }
#' @export
cie11_sql <- function(query) {
  stopifnot(is.character(query), length(query) == 1L)
  q <- trimws(query)

  # Validacion de seguridad: solo SELECT.
  if (!grepl("^select", q, ignore.case = TRUE)) {
    stop("Only SELECT queries are allowed (security).", call. = FALSE)
  }
  peligrosos <- c(
    "\\bDROP\\b", "\\bDELETE\\b", "\\bUPDATE\\b", "\\bINSERT\\b",
    "\\bALTER\\b", "\\bCREATE\\b", "\\bTRUNCATE\\b", "\\bEXEC\\b",
    "\\bATTACH\\b", "\\bDETACH\\b", "\\bPRAGMA\\b"
  )
  if (any(vapply(peligrosos,
    function(k) grepl(k, q, ignore.case = TRUE), logical(1)
  ))) {
    stop("Query contains a disallowed keyword (security).", call. = FALSE)
  }
  # Bloquear multiples statements: quitar strings y comentarios, buscar ';'.
  qs <- gsub("'[^']*'", "", q)
  qs <- gsub("--[^\n]*", "", qs)
  qs <- gsub("/\\*.*?\\*/", "", qs)
  if (grepl(";", qs)) {
    stop("Multiple SQL statements are not allowed (security).", call. = FALSE)
  }

  con <- .cie11_get_db()
  DBI::dbGetQuery(con, query)
}

#' Limpiar el cache SQLite CIE-11 / Clear the ICD-11 SQLite cache
#'
#' Cierra la conexion pooled y elimina el archivo de cache para forzar su
#' reconstruccion en la proxima consulta. Seguro de llamar aunque no exista.
#'
#' Closes the pooled connection and deletes the cache file so it is rebuilt on
#' the next query. Safe to call even if it does not exist.
#'
#' @return Invisiblemente `NULL`. / Invisibly `NULL`.
#' @family sql
#' @seealso [cie11_sql()], [cie11_disconnect()]
#' @examples
#' # Ubicacion del cache / cache location:
#' tools::R_user_dir("cie11cl", "data")
#' \dontrun{
#' cie11_clear_cache()
#' }
#' @export
cie11_clear_cache <- function() {
  cie11_disconnect()
  cache_dir <- tools::R_user_dir("cie11cl", "data")
  db_path <- file.path(cache_dir, "cie11.db")
  tmp_path <- paste0(db_path, ".tmp")
  if (file.exists(db_path)) file.remove(db_path)
  if (file.exists(tmp_path)) file.remove(tmp_path)
  invisible(NULL)
}

#' Cerrar la conexion CIE-11 / Disconnect the ICD-11 database
#'
#' Cierra la conexion pooled al cache SQLite y libera el lock del archivo. No
#' borra el cache. Seguro de llamar aunque no haya conexion activa.
#'
#' Closes the pooled SQLite connection and releases the file lock without
#' deleting the cache. Safe to call even when no connection is active.
#'
#' @return Invisiblemente `NULL`. / Invisibly `NULL`.
#' @family sql
#' @seealso [cie11_sql()], [cie11_clear_cache()]
#' @examples
#' cie11_disconnect()
#' @export
cie11_disconnect <- function() {
  if (!is.null(.cie11_env$con)) {
    if (requireNamespace("DBI", quietly = TRUE) &&
        inherits(.cie11_env$con, "SQLiteConnection") &&
        DBI::dbIsValid(.cie11_env$con)) {
      suppressWarnings(DBI::dbDisconnect(.cie11_env$con))
    }
    .cie11_env$con <- NULL
    .cie11_env$db_path <- NULL
  }
  invisible(NULL)
}
