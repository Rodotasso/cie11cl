# Cierre de la conexion SQLite pooled al descargar el paquete (ver sql.R).
# El cache en disco no se borra: solo se libera el lock del archivo.
.onUnload <- function(libpath) {
  if (!is.null(.cie11_env$con)) {
    if (requireNamespace("DBI", quietly = TRUE)) {
      try(suppressWarnings(DBI::dbDisconnect(.cie11_env$con)), silent = TRUE)
    }
    .cie11_env$con <- NULL
    .cie11_env$db_path <- NULL
  }
}
