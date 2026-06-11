# El backend SQL construye un cache SQLite DERIVADO de los datos cargados.
# No se aporta ningun archivo .db externo.

test_that("cie11_sql consulta el cache derivado del fixture", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  on.exit(cie11_clear_cache(), add = TRUE)
  res <- cie11_sql("SELECT code, title FROM cie11 WHERE code = 'AA00'")
  expect_equal(nrow(res), 1L)
  expect_equal(res$title, "Afeccion de ejemplo alfa")
})

test_that("cie11_sql expone la tabla de mapeo cie11_map", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  on.exit(cie11_clear_cache(), add = TRUE)
  res <- cie11_sql(
    "SELECT cie10_code, cie11_code FROM cie11_map WHERE cie10_code = 'A000'"
  )
  expect_equal(nrow(res), 1L)
  expect_equal(res$cie11_code, "AA00")
})

test_that("cie11_sql expone busqueda de texto completo FTS5", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  on.exit(cie11_clear_cache(), add = TRUE)
  res <- cie11_sql(
    "SELECT code FROM cie11_fts WHERE cie11_fts MATCH 'alfa'"
  )
  expect_true("AA00" %in% res$code)
})

test_that("cie11_sql bloquea consultas que no son SELECT", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  on.exit(cie11_clear_cache(), add = TRUE)
  expect_error(cie11_sql("DROP TABLE cie11"), "SELECT")
  expect_error(cie11_sql("SELECT 1; DELETE FROM cie11"))
  expect_error(cie11_sql("SELECT 1 /* x */; INSERT INTO cie11 VALUES(1)"))
})

test_that("recargar otras fuentes reconstruye el cache", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  on.exit(cie11_clear_cache(), add = TRUE)
  n_fixture <- nrow(cie11_sql("SELECT code FROM cie11"))

  # Cargar un MMS de usuario mas pequeno debe invalidar el cache anterior.
  mms2 <- data.frame(
    uri_id = "9999", code = "ZZ00", title = "Entidad de prueba",
    definition = NA_character_, classKind = "category", isLeaf = TRUE,
    parent_id = NA_character_, chapter = "ZZ", level = 1L,
    indexTerms = "prueba", postcoordinationScale = "",
    stringsAsFactors = FALSE
  )
  cie11_load(mms = mms2)
  res <- cie11_sql("SELECT code FROM cie11")
  expect_equal(nrow(res), 1L)
  expect_equal(res$code, "ZZ00")
  expect_false(nrow(res) == n_fixture)
})

test_that("cie11_disconnect y cie11_clear_cache son seguros sin estado", {
  skip_if_not_installed("DBI")
  expect_silent(cie11_disconnect())
  cie11_clear_cache()
  expect_null(.cie11_env$con)
})
