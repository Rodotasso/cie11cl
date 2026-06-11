test_that("cie11_map_from_icd10() mapea y asigna certeza exacta", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_map_from_icd10("A000")
  expect_equal(res$cie11_code, "AA00")
  expect_equal(res$certainty, 5L)
})

test_that("la regla de certeza es deterministica y trazable", {
  cert <- cie11cl:::.cie11_certainty
  expect_equal(cert("EXACT_TITLE", 1.00), 5L)
  expect_equal(cert("FUZZY_JW", 0.96), 4L)
  expect_equal(cert("FUZZY_JW", 0.90), 3L)
  expect_equal(cert("FUZZY_JW", 0.82), 2L)
  expect_equal(cert("FUZZY_JW", 0.70), 1L)
})

test_that("la certeza es vectorizada", {
  cert <- cie11cl:::.cie11_certainty
  expect_equal(cert(c("EXACT_TITLE", "FUZZY_JW"), c(1.0, 0.70)), c(5L, 1L))
})

test_that("codigos sin mapeo retornan cero filas", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  expect_equal(nrow(cie11_map_from_icd10("ZZZ")), 0L)
})
