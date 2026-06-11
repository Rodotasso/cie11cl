#' Hijos directos de un codigo CIE-11 / Direct children of an ICD-11 code
#'
#' Devuelve todas las entidades cuyo padre inmediato en la jerarquia MMS es
#' `code`. Usa el indice `parent_id` del cache SQLite.
#'
#' Returns all entities whose immediate parent in the MMS hierarchy is `code`.
#' Uses the `parent_id` index of the SQLite cache.
#'
#' @param code Un unico codigo CIE-11 (p. ej. `"1D00"`). /
#'   A single ICD-11 code.
#' @return Data frame con columnas `code`, `title`, `classKind`, `isLeaf`,
#'   `level`, ordenado por `code`. /
#'   Data frame with columns `code`, `title`, `classKind`, `isLeaf`, `level`,
#'   ordered by `code`.
#' @family navigation
#' @seealso [cie11_ancestors()], [cie11_subtree()]
#' @examples
#' \dontrun{
#' cie11_children("01")   # hijos del capitulo 01
#' }
#' @export
cie11_children <- function(code) {
  stopifnot(is.character(code), length(code) == 1L)
  con <- .cie11_get_db()
  DBI::dbGetQuery(con, "
    SELECT c.code, c.title, c.classKind, c.isLeaf, c.level
    FROM cie11 c
    WHERE c.parent_id = (SELECT uri_id FROM cie11 WHERE code = ? LIMIT 1)
    ORDER BY c.code
  ", params = list(code))
}

#' Ancestros de un codigo CIE-11 / Ancestors of an ICD-11 code
#'
#' Devuelve la cadena de ancestros desde el padre inmediato hasta el capitulo
#' raiz, usando una CTE recursiva en SQLite.
#'
#' Returns the ancestor chain from the immediate parent up to the root chapter,
#' using a recursive CTE in SQLite.
#'
#' @param code Un unico codigo CIE-11. / A single ICD-11 code.
#' @return Data frame con columnas `code`, `title`, `classKind`, `level`,
#'   ordenado de mayor a menor nivel (raiz primero). /
#'   Data frame with `code`, `title`, `classKind`, `level`, ordered from
#'   root down (highest level first).
#' @family navigation
#' @seealso [cie11_children()], [cie11_subtree()]
#' @examples
#' \dontrun{
#' cie11_ancestors("1D00.Z")
#' }
#' @export
cie11_ancestors <- function(code) {
  stopifnot(is.character(code), length(code) == 1L)
  con <- .cie11_get_db()
  DBI::dbGetQuery(con, "
    WITH RECURSIVE ancs(uri_id, code, title, classKind, level, parent_id) AS (
      SELECT uri_id, code, title, classKind, level, parent_id
        FROM cie11 WHERE code = ? LIMIT 1
      UNION ALL
      SELECT p.uri_id, p.code, p.title, p.classKind, p.level, p.parent_id
        FROM cie11 p
        INNER JOIN ancs a ON p.uri_id = a.parent_id
    )
    SELECT code, title, classKind, level
      FROM ancs
     WHERE code != ?
     ORDER BY level ASC
  ", params = list(code, code))
}

#' Subárbol de un codigo CIE-11 / Subtree of an ICD-11 code
#'
#' Devuelve todos los descendientes (a cualquier profundidad) de `code` usando
#' una CTE recursiva en SQLite. Util para obtener todos los codigos de un
#' capitulo o bloque completo.
#'
#' Returns all descendants (at any depth) of `code` using a recursive CTE in
#' SQLite. Useful to retrieve all codes within a chapter or block.
#'
#' @param code Un unico codigo CIE-11. / A single ICD-11 code.
#' @return Data frame con columnas `code`, `title`, `classKind`, `isLeaf`,
#'   `level`, ordenado por `level` y `code`. /
#'   Data frame with `code`, `title`, `classKind`, `isLeaf`, `level`,
#'   ordered by `level` then `code`.
#' @family navigation
#' @seealso [cie11_children()], [cie11_ancestors()]
#' @examples
#' \dontrun{
#' # Todos los codigos del bloque 1A00
#' nrow(cie11_subtree("1A00"))
#' }
#' @export
cie11_subtree <- function(code) {
  stopifnot(is.character(code), length(code) == 1L)
  con <- .cie11_get_db()
  DBI::dbGetQuery(con, "
    WITH RECURSIVE sub(uri_id, code, title, classKind, isLeaf, level, parent_id) AS (
      SELECT uri_id, code, title, classKind, isLeaf, level, parent_id
        FROM cie11 WHERE code = ? LIMIT 1
      UNION ALL
      SELECT c.uri_id, c.code, c.title, c.classKind, c.isLeaf, c.level, c.parent_id
        FROM cie11 c
        INNER JOIN sub s ON c.parent_id = s.uri_id
    )
    SELECT code, title, classKind, isLeaf, level
      FROM sub
     WHERE code != ?
     ORDER BY level ASC, code ASC
  ", params = list(code, code))
}
