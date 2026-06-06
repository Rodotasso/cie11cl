# Construye una base SQLite temporal de prueba (no se versiona; solo en tempdir).
.cie11_tmp_db <- function() {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  tmp <- tempfile(fileext = ".db")
  con <- DBI::dbConnect(RSQLite::SQLite(), tmp)
  DBI::dbWriteTable(con, "cie11", data.frame(
    code = c("1A00", "1A01"),
    title = c("Colera", "Otra infeccion"),
    stringsAsFactors = FALSE
  ))
  DBI::dbDisconnect(con)
  tmp
}

test_that("cie11_connect + cie11_sql consultan la base", {
  tmp <- .cie11_tmp_db()
  on.exit({ cie11_disconnect(); unlink(tmp) }, add = TRUE)
  cie11_connect(tmp)
  res <- cie11_sql("SELECT code, title FROM cie11 WHERE code = '1A00'")
  expect_equal(nrow(res), 1L)
  expect_equal(res$title, "Colera")
})

test_that("cie11_sql bloquea consultas que no son SELECT", {
  tmp <- .cie11_tmp_db()
  on.exit({ cie11_disconnect(); unlink(tmp) }, add = TRUE)
  cie11_connect(tmp)
  expect_error(cie11_sql("DROP TABLE cie11"), "SELECT")
  expect_error(cie11_sql("SELECT 1; DELETE FROM cie11"))
})

test_that("cie11_sql exige una conexion activa", {
  cie11_disconnect()
  skip_if_not_installed("DBI")
  expect_error(cie11_sql("SELECT 1"), "No active database connection")
})

test_that("cie11_connect falla si el archivo no existe", {
  skip_if_not_installed("DBI")
  expect_error(cie11_connect("no_existe_xyz.db"), "File not found")
})

test_that("cie11_connect falla si falta la tabla", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  tmp <- tempfile(fileext = ".db")
  con <- DBI::dbConnect(RSQLite::SQLite(), tmp)
  DBI::dbWriteTable(con, "otra", data.frame(x = 1))
  DBI::dbDisconnect(con)
  on.exit({ cie11_disconnect(); unlink(tmp) }, add = TRUE)
  expect_error(cie11_connect(tmp, table = "cie11"), "Table not found")
})
