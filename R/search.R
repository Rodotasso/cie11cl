#' Busqueda lexica en titulos y terminos de CIE-11 / Lexical search over ICD-11
#'
#' Busqueda difusa determinista. La similitud se calcula con la metrica
#' Jaro-Winkler entre la consulta (en minusculas) y cada titulo; una coincidencia
#' exacta de subcadena en el titulo o en los terminos de indice se promueve a una
#' similitud alta para que los terminos contenidos queden siempre arriba. Con la
#' misma consulta y la misma fuente, el resultado es identico en cada corrida.
#'
#' Deterministic fuzzy search using Jaro-Winkler similarity between the query and
#' each entity title; an exact substring match in the title or index terms is
#' promoted to high similarity. Same query plus same source yields identical
#' results every run.
#'
#' @param query Una unica cadena de busqueda. / A single search string.
#' @param n Numero maximo de resultados (por defecto 10). /
#'   Maximum number of results (default 10).
#' @param min_sim Similitud minima en `[0, 1]` para conservar un resultado
#'   (por defecto 0). / Minimum similarity in `[0, 1]` to keep a result.
#' @return Un data frame de hasta `n` coincidencias ordenadas por `similarity`
#'   descendente, con columnas `code`, `title` y `similarity`. /
#'   A data frame of up to `n` matches ordered by descending similarity.
#' @examples
#' cie11_load()
#' cie11_search("ejemplo alfa")
#' @export
cie11_search <- function(query, n = 10, min_sim = 0) {
  stopifnot(is.character(query), length(query) == 1L)
  mms <- .cie11_mms()
  q <- tolower(query)
  title_l <- tolower(mms$title)
  index_l <- tolower(mms$indexTerms)
  # Similitud Jaro-Winkler contra el titulo.
  sim <- stringdist::stringsim(q, title_l, method = "jw", p = 0.1)
  # Promover coincidencia exacta de subcadena (titulo o terminos de indice).
  contenido <- grepl(q, title_l, fixed = TRUE) | grepl(q, index_l, fixed = TRUE)
  sim[contenido] <- pmax(sim[contenido], 0.95)
  ord <- order(sim, decreasing = TRUE)
  ord <- ord[sim[ord] >= min_sim]
  ord <- utils::head(ord, n)
  data.frame(
    code = mms$code[ord],
    title = mms$title[ord],
    similarity = round(sim[ord], 4),
    stringsAsFactors = FALSE
  )
}
