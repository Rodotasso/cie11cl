#' Crosswalk CIE-10 a CIE-11 con niveles de certeza / ICD-10 to ICD-11 crosswalk
#'
#' Mapeo determinista CIE-10 -> CIE-11 contra la tabla de mapeo cargada (ver
#' [cie11_load()]). Cada mapeo lleva un nivel de certeza de 1 (menor) a 5
#' (exacto), derivado por una regla fija y trazable a partir del `match_type` y
#' el `score` de similitud:
#'
#' Deterministic ICD-10 to ICD-11 mapping. Each mapping carries a certainty
#' level from 1 (lowest) to 5 (exact), derived by a fixed, traceable rule from
#' the mapping `match_type` and similarity `score`:
#'
#' \itemize{
#'   \item `EXACT_TITLE` -> 5
#'   \item `FUZZY_JW`, `score >= 0.95` -> 4
#'   \item `FUZZY_JW`, `0.88 <= score < 0.95` -> 3
#'   \item `FUZZY_JW`, `0.80 <= score < 0.88` -> 2
#'   \item resto / otherwise -> 1
#' }
#'
#' @param code Vector de caracteres con codigos CIE-10 (p. ej. `"A000"`). /
#'   Character vector of ICD-10 codes.
#' @return Un data frame con columnas `cie10_code`, `cie11_code`, `cie11_title`,
#'   `match_type`, `score` y `certainty`, ordenado por orden de entrada y luego
#'   por certeza descendente. Los codigos sin mapeo devuelven cero filas. /
#'   A data frame with `cie10_code`, `cie11_code`, `cie11_title`, `match_type`,
#'   `score` and `certainty`; unmapped codes yield zero rows.
#' @examples
#' cie11_load()
#' cie11_map_from_icd10("A000")
#' @export
cie11_map_from_icd10 <- function(code) {
  if (!is.character(code)) code <- as.character(code)
  map <- .cie11_map()
  out <- map[map$cie10_code %in% code, , drop = FALSE]
  cols <- c(
    "cie10_code", "cie11_code", "cie11_title",
    "match_type", "score", "certainty"
  )
  if (!nrow(out)) {
    out$certainty <- integer(0)
    return(out[, intersect(cols, names(out)), drop = FALSE])
  }
  out$certainty <- .cie11_certainty(out$match_type, out$score)
  out <- out[order(match(out$cie10_code, code), -out$certainty), , drop = FALSE]
  rownames(out) <- NULL
  out[, intersect(cols, names(out)), drop = FALSE]
}

# Regla de certeza determinista y trazable (ver cie11_map_from_icd10).
.cie11_certainty <- function(match_type, score) {
  score <- as.numeric(score)
  out <- integer(length(match_type))
  exacto <- match_type == "EXACT_TITLE"
  out[exacto] <- 5L
  difuso <- !exacto
  out[difuso & score >= 0.95] <- 4L
  out[difuso & score >= 0.88 & score < 0.95] <- 3L
  out[difuso & score >= 0.80 & score < 0.88] <- 2L
  out[difuso & score < 0.80] <- 1L
  out
}
