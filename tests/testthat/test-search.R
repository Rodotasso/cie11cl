test_that("cie11_search() ordena por similitud descendente", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_search("ejemplo alfa", n = 5)
  expect_true(nrow(res) >= 1L)
  expect_false(is.unsorted(rev(res$similarity)))
  expect_true("AA00" %in% res$code)
})

test_that("cie11_search() respeta el limite n", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  expect_lte(nrow(cie11_search("ejemplo", n = 2)), 2L)
})

test_that("cie11_search() es deterministico", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  expect_identical(cie11_search("gamma"), cie11_search("gamma"))
})

test_that("cie11_search() exige una unica cadena", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  expect_error(cie11_search(c("a", "b")))
})
