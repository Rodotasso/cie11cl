# Capa SQL: conexion pooled a una base CIE-11 SQLite aportada por el usuario.
# Reusa el cache interno .cie11_env (definido en data-source.R). Las dependencias
# DBI/RSQLite son opcionales (Suggests): se verifican en tiempo de ejecucion.

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

# Devuelve la conexion activa o falla si no hay ninguna.
.cie11_require_con <- function() {
  if (is.null(.cie11_env$con) || !DBI::dbIsValid(.cie11_env$con)) {
    stop("No active database connection. Call cie11_connect() first.",
      call. = FALSE
    )
  }
  .cie11_env$con
}

#' Conectar a una base CIE-11 SQLite / Connect to a SQLite ICD-11 database
#'
#' Abre una conexion DBI reutilizable (pooled) a una base de datos SQLite que el
#' usuario aporta con su release CIE-11. La conexion se guarda en el cache
#' interno y se reutiliza en llamadas sucesivas al mismo archivo. El paquete no
#' incluye ninguna base de datos.
#'
#' Opens a pooled DBI connection to a user-provided SQLite ICD-11 database. The
#' connection is cached and reused for subsequent calls to the same file. No
#' database is bundled with the package.
#'
#' @param db_path Ruta al archivo SQLite. / Path to the SQLite file.
#' @param table Nombre de la tabla principal CIE-11 (por defecto `"cie11"`). /
#'   Name of the main ICD-11 table (default `"cie11"`).
#' @return Invisiblemente, la conexion DBI activa. /
#'   Invisibly, the active DBI connection.
#' @examples
#' \dontrun{
#' cie11_connect("data/cie11_mms_2026.db")
#' cie11_sql("SELECT code, title FROM cie11 WHERE code LIKE '1A%'")
#' cie11_disconnect()
#' }
#' @seealso [cie11_sql()], [cie11_disconnect()]
#' @export
cie11_connect <- function(db_path, table = "cie11") {
  .cie11_need_dbi()
  if (!file.exists(db_path)) stop("File not found: ", db_path, call. = FALSE)
  # Reutilizar si ya hay conexion valida al mismo archivo.
  if (!is.null(.cie11_env$con) &&
      inherits(.cie11_env$con, "SQLiteConnection") &&
      DBI::dbIsValid(.cie11_env$con) &&
      identical(.cie11_env$db_path, db_path)) {
    return(invisible(.cie11_env$con))
  }
  cie11_disconnect()
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  if (!DBI::dbExistsTable(con, table)) {
    DBI::dbDisconnect(con)
    stop("Table not found in database: ", table, call. = FALSE)
  }
  .cie11_env$con <- con
  .cie11_env$db_path <- db_path
  .cie11_env$table <- table
  invisible(con)
}

#' Consultar la base CIE-11 con SQL / Query the ICD-11 database with SQL
#'
#' Ejecuta una consulta **SELECT** (solo lectura) sobre la base CIE-11 conectada
#' con [cie11_connect()]. Por seguridad solo se permiten consultas SELECT: se
#' bloquean palabras clave de escritura y los statements multiples.
#'
#' Runs a read-only **SELECT** query against the ICD-11 database connected via
#' [cie11_connect()]. For safety only SELECT queries are allowed: write keywords
#' and multiple statements are rejected.
#'
#' @param query Una unica consulta SQL SELECT. / A single SELECT SQL query.
#' @return Un data frame con el resultado. / A data frame with the result.
#' @examples
#' \dontrun{
#' cie11_connect("data/cie11_mms_2026.db")
#' cie11_sql("SELECT code, title FROM cie11 WHERE code = '1A00'")
#' }
#' @seealso [cie11_connect()], [cie11_disconnect()]
#' @export
cie11_sql <- function(query) {
  stopifnot(is.character(query), length(query) == 1L)
  .cie11_need_dbi()
  q <- trimws(query)
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
  con <- .cie11_require_con()
  DBI::dbGetQuery(con, query)
}

#' Cerrar la conexion CIE-11 / Disconnect the ICD-11 database
#'
#' Cierra la conexion pooled al archivo SQLite y libera el cache. Seguro de
#' llamar aunque no haya conexion activa.
#'
#' Closes the pooled SQLite connection and clears the cache. Safe to call even
#' when no connection is active.
#'
#' @return Invisiblemente `NULL`. / Invisibly `NULL`.
#' @seealso [cie11_connect()]
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
    .cie11_env$table <- NULL
  }
  invisible(NULL)
}
