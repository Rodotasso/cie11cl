test_that("el paquete carga correctamente", {
  expect_true(requireNamespace("cie11cl", quietly = TRUE))
})
