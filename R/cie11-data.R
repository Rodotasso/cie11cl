#' Dataset CIE-11 MMS 2026 (WHO, espanol)
#'
#' Linealizacion completa de mortalidad y morbilidad (MMS) de la CIE-11,
#' release 2026-01, en espanol. Generado a partir del CSV oficial de la OMS.
#'
#' Complete ICD-11 Mortality and Morbidity Statistics (MMS) linearization,
#' release 2026-01, in Spanish. Generated from the WHO official CSV.
#'
#' @format Tibble con 37.212 filas y 11 columnas / Tibble with 37,212 rows
#'   and 11 columns:
#' \describe{
#'   \item{uri_id}{Identificador unico: segmento tras `mms/` en el URI WHO
#'     (p. ej. `"1435254666"`, `"62637936/other"`). /
#'     Unique identifier: segment after `mms/` in the WHO URI.}
#'   \item{code}{Codigo CIE-11 alfanumerico (p. ej. `"1D00.Z"`, `"01"`). /
#'     ICD-11 alphanumeric code.}
#'   \item{title}{Titulo en espanol. / Title in Spanish.}
#'   \item{definition}{Definicion clinica en espanol (`NA` si no disponible). /
#'     Clinical definition in Spanish (`NA` if unavailable).}
#'   \item{classKind}{Tipo de entidad: `"chapter"`, `"block"` o `"category"`. /
#'     Entity type: `"chapter"`, `"block"` or `"category"`.}
#'   \item{isLeaf}{`TRUE` si el nodo es una hoja (sin hijos). /
#'     `TRUE` if the node is a leaf (no children).}
#'   \item{parent_id}{`uri_id` del padre inmediato (`NA` para capitulos raiz). /
#'     `uri_id` of the immediate parent (`NA` for root chapters).}
#'   \item{chapter}{Codigo del capitulo al que pertenece (p. ej. `"01"`). /
#'     Code of the containing chapter.}
#'   \item{level}{Nivel jerarquico (1 = capitulo, 2 = bloque, 3+ = categoria). /
#'     Hierarchical level (1 = chapter, 2 = block, 3+ = category).}
#'   \item{indexTerms}{Terminos de indice y sinonimos, separados por `" | "`. /
#'     Index terms and synonyms, separated by `" | "`.}
#'   \item{postcoordinationScale}{JSON con los ejes de post-coordinacion
#'     permitidos; cadena vacia si el codigo no admite post-coordinacion. /
#'     JSON with allowed post-coordination axes; empty string if the code
#'     does not allow post-coordination.}
#' }
#' @source \url{https://icd.who.int/browse/2026-01/mms/es}
#' @examples
#' data(cie11_mms)
#' head(cie11_mms[, c("code", "title", "classKind", "chapter", "level")])
#'
#' # Codigos de un capitulo:
#' subset(cie11_mms, chapter == "01" & classKind == "category")[1:5, "code"]
#'
#' # Codigos con post-coordinacion:
#' sum(nzchar(cie11_mms$postcoordinationScale))
"cie11_mms"
