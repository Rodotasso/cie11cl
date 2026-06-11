test_that("cie11_validate_cluster() acepta post-coordinacion valida", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate_cluster("AB00.0&XA01")
  expect_true(res$valid)
  expect_equal(res$n_components, 2L)
})

test_that("cie11_validate_cluster() acepta varios stems con '/'", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  expect_true(cie11_validate_cluster("AB00/AC00")$valid)
})

test_that("cie11_validate_cluster() rechaza stem que no admite post-coordinacion", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate_cluster("AA00&XA01")
  expect_false(res$valid)
  expect_match(res$reason, "post-coordinacion")
})

test_that("cie11_validate_cluster() rechaza extension usada como stem", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate_cluster("XA01")
  expect_false(res$valid)
  expect_match(res$reason, "extension")
})

test_that("cie11_validate_cluster() rechaza codigos inexistentes", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate_cluster("AB00.0&ZZ99")
  expect_false(res$valid)
  expect_match(res$reason, "inexistente")
})

test_that("cie11_validate_cluster() es vectorizado y deterministico", {
  cie11_load(mms = .cie11_fixture_mms(), map = .cie11_fixture_map())
  res <- cie11_validate_cluster(c("AB00.0&XA01", "XA01"))
  expect_equal(nrow(res), 2L)
  expect_equal(res$valid, c(TRUE, FALSE))
  expect_identical(
    cie11_validate_cluster("AB00/AC00"),
    cie11_validate_cluster("AB00/AC00")
  )
})
