test_that("cie11_validate() distingue validos de invalidos", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate(c("AA00", "ZZ99"))
  expect_equal(res$code, c("AA00", "ZZ99"))
  expect_equal(res$valid, c(TRUE, FALSE))
})

test_that("cie11_validate() reporta classKind e is_leaf", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate("AA00")
  expect_equal(res$classKind, "category")
  expect_true(res$is_leaf)
})
