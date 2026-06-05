#' Buscar entidades CIE-11 por codigo / Look up ICD-11 entities by code
#'
#' Busqueda exacta y determinista de uno o mas codigos CIE-11 contra la fuente
#' de datos cargada (ver [cie11_load()]).
#'
#' Deterministic exact lookup of one or more ICD-11 MMS codes against the
#' currently loaded data source.
#'
#' @param code Vector de caracteres con codigos CIE-11 (p. ej. `"1A00"`). /
#'   Character vector of ICD-11 codes.
#' @return Un data frame con una fila por codigo consultado, en el orden de
#'   `code`; los codigos no encontrados devuelven una fila de `NA`. /
#'   A data frame with one row per queried code, preserving input order; codes
#'   not found yield a row of `NA`s.
#' @examples
#' cie11_load()
#' cie11_lookup("AA00")
#' cie11_lookup(c("AA00", "ZZ99"))
#' @export
cie11_lookup <- function(code) {
  if (!is.character(code)) code <- as.character(code)
  mms <- .cie11_mms()
  idx <- match(code, mms$code)
  out <- mms[idx, , drop = FALSE]
  out$code <- code
  rownames(out) <- NULL
  out
}
