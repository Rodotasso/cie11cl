#' Validar codigos CIE-11 / Validate ICD-11 codes
#'
#' Verifica si uno o mas codigos existen en la fuente de datos CIE-11 cargada y
#' reporta su `classKind` y condicion de hoja. Determinista.
#'
#' Checks whether one or more codes exist in the loaded ICD-11 data source and
#' reports their class kind and leaf status. Deterministic.
#'
#' @param code Vector de caracteres con codigos CIE-11. /
#'   Character vector of ICD-11 codes.
#' @return Un data frame con columnas `code`, `valid` (logico), `classKind` e
#'   `is_leaf` (logico), una fila por codigo. /
#'   A data frame with columns `code`, `valid`, `classKind` and `is_leaf`.
#' @examples
#' cie11_load()
#' cie11_validate(c("AA00", "ZZ99"))
#' @export
cie11_validate <- function(code) {
  if (!is.character(code)) code <- as.character(code)
  mms <- .cie11_mms()
  idx <- match(code, mms$code)
  data.frame(
    code = code,
    valid = !is.na(idx),
    classKind = mms$classKind[idx],
    is_leaf = as.logical(mms$isLeaf[idx]),
    stringsAsFactors = FALSE
  )
}
