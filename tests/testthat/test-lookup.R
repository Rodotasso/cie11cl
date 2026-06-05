test_that("cie11_lookup() encuentra un codigo existente", {
  cie11_load()
  res <- cie11_lookup("AA00")
  expect_equal(nrow(res), 1L)
  expect_equal(res$title, "Afeccion de ejemplo alfa")
})

test_that("cie11_lookup() es deterministico", {
  cie11_load()
  expect_identical(cie11_lookup("AA00"), cie11_lookup("AA00"))
})

test_that("cie11_lookup() preserva el orden y marca inexistentes como NA", {
  cie11_load()
  res <- cie11_lookup(c("AA00", "ZZ99", "AC00"))
  expect_equal(res$code, c("AA00", "ZZ99", "AC00"))
  expect_true(is.na(res$title[2]))
  expect_equal(res$title[3], "Afeccion de ejemplo gamma")
})
