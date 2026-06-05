test_that("cie11_load() con fixture deja datos disponibles", {
  expect_true(cie11_load())
  mms <- cie11cl:::.cie11_mms()
  map <- cie11cl:::.cie11_map()
  expect_s3_class(mms, "data.frame")
  expect_s3_class(map, "data.frame")
  expect_true(all(cie11cl:::.cie11_mms_cols %in% names(mms)))
  expect_true(all(cie11cl:::.cie11_map_cols %in% names(map)))
})

test_that("cie11_load() valida columnas faltantes", {
  expect_error(cie11_load(mms = data.frame(foo = 1)), "Missing required columns")
  expect_error(cie11_load(map = data.frame(foo = 1)), "Missing required columns")
})

test_that("cie11_load() acepta data frames del usuario", {
  mms <- cie11cl:::.cie11_fixture_mms()
  map <- cie11cl:::.cie11_fixture_map()
  expect_true(cie11_load(mms = mms, map = map))
})

test_that("cie11_load() falla si el archivo no existe", {
  expect_error(cie11_load(mms = "no_existe_xyz.csv"), "File not found")
})
