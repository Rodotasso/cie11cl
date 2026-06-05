#' Validar clusters CIE-11 (post-coordinacion) / Validate ICD-11 clusters
#'
#' Valida de forma determinista expresiones de **codificacion en cluster** de
#' CIE-11: combinaciones de codigos unidas por los conectores `&` (un stem con
#' sus ejes de post-coordinacion) y `/` (varios stems que juntos describen un
#' evento). La validacion es estructural y no depende del servidor de la OMS:
#'
#' Deterministically validates ICD-11 **cluster coding** expressions:
#' combinations of codes joined by `&` (a stem plus its post-coordination axes)
#' and `/` (several stems describing one event). Structural validation, with no
#' dependency on the WHO server:
#'
#' \enumerate{
#'   \item Todos los componentes deben existir en la fuente cargada. /
#'     Every component must exist in the loaded source.
#'   \item Un codigo de extension (Capitulo X, prefijo `X`) no puede actuar como
#'     stem (no puede ir solo ni liderar un grupo separado por `/`). /
#'     An extension code (Chapter X, prefix `X`) cannot act as a stem.
#'   \item Un stem con ejes unidos por `&` debe admitir post-coordinacion
#'     (`postcoordinationScale` no vacio). /
#'     A stem joined by `&` must declare post-coordination.
#' }
#'
#' @param cluster Vector de caracteres; cada elemento es una expresion CIE-11,
#'   posiblemente post-coordinada (p. ej. `"AB00.0&XA01"`). /
#'   Character vector; each element is a possibly post-coordinated ICD-11
#'   expression.
#' @return Un data frame con una fila por expresion: `cluster`, `valid`
#'   (logico), `n_components` (entero) y `reason` (motivo cuando no es valido). /
#'   A data frame with one row per expression: `cluster`, `valid`,
#'   `n_components` and `reason`.
#' @examples
#' cie11_load()
#' cie11_validate_cluster(c("AB00.0&XA01", "AA00&XA01", "AB00/AC00", "XA01"))
#' @export
cie11_validate_cluster <- function(cluster) {
  if (!is.character(cluster)) cluster <- as.character(cluster)
  mms <- .cie11_mms()
  filas <- lapply(cluster, function(cl) .cie11_validar_cluster_uno(cl, mms))
  do.call(rbind, filas)
}

# Valida una sola expresion de cluster y devuelve una fila de resultado.
.cie11_validar_cluster_uno <- function(cl, mms) {
  cl_orig <- cl
  cl <- trimws(cl)
  # Grupos separados por "/" (varios stems); componentes por "&" dentro de cada grupo.
  grupos <- trimws(strsplit(cl, "/", fixed = TRUE)[[1]])
  comps <- trimws(strsplit(cl, "[&/]")[[1]])
  comps <- comps[nzchar(comps)]

  if (!length(comps)) {
    return(.cie11_cluster_row(cl_orig, FALSE, 0L, "expresion vacia"))
  }
  # 1) existencia de todos los componentes
  existe <- comps %in% mms$code
  if (!all(existe)) {
    return(.cie11_cluster_row(
      cl_orig, FALSE, length(comps),
      paste0("codigo(s) inexistente(s): ",
        paste(comps[!existe], collapse = ", "))
    ))
  }
  # 2) ningun lider de grupo puede ser codigo de extension (prefijo X)
  lideres <- vapply(
    strsplit(grupos, "&", fixed = TRUE),
    function(g) trimws(g[1]), character(1)
  )
  if (any(grepl("^X", lideres))) {
    return(.cie11_cluster_row(
      cl_orig, FALSE, length(comps),
      "codigo de extension usado como stem (no puede ir solo)"
    ))
  }
  # 3) un stem con ejes "&" debe admitir post-coordinacion
  for (g in grupos) {
    partes <- trimws(strsplit(g, "&", fixed = TRUE)[[1]])
    if (length(partes) > 1L) {
      stem <- partes[1]
      pc <- mms$postcoordinationScale[match(stem, mms$code)]
      if (is.na(pc) || !nzchar(pc)) {
        return(.cie11_cluster_row(
          cl_orig, FALSE, length(comps),
          paste0("el stem ", stem, " no admite post-coordinacion")
        ))
      }
    }
  }
  .cie11_cluster_row(cl_orig, TRUE, length(comps), NA_character_)
}

# Construye una fila de resultado de validacion de cluster.
.cie11_cluster_row <- function(cluster, valid, n_components, reason) {
  data.frame(
    cluster = cluster,
    valid = valid,
    n_components = as.integer(n_components),
    reason = reason,
    stringsAsFactors = FALSE
  )
}
