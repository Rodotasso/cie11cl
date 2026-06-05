# Fixtures SINTETICOS, usados solo para ejemplos y tests.
# NO son contenido real CIE-11 de la OMS: todos los codigos y titulos son
# inventados y existen unicamente para que el paquete sea ejecutable sin una
# release de datos externa. Ningun dato de la clasificacion se versiona aqui.
#
# Estructura imitada (no contenido): stems (codigos raiz) con prefijo de letra,
# codigos de extension con prefijo X (Capitulo X), y un eje de post-coordinacion
# declarado en `postcoordinationScale` para los stems que lo admiten.

.cie11_fixture_mms <- function() {
  data.frame(
    code = c("AA00", "AB00", "AB00.0", "AC00", "XA01", "XB02"),
    title = c(
      "Afeccion de ejemplo alfa",
      "Afeccion de ejemplo beta",
      "Afeccion de ejemplo beta especificada",
      "Afeccion de ejemplo gamma",
      "Eje de ejemplo: severidad leve",
      "Eje de ejemplo: agente alfa"
    ),
    definition = c(
      "Definicion sintetica alfa.",
      "Definicion sintetica beta.",
      "Definicion sintetica beta especificada.",
      "Definicion sintetica gamma.",
      "", ""
    ),
    classKind = c("category", "category", "category", "category",
                  "category", "category"),
    isLeaf = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
    parent = c("AA", "AB", "AB00", "AC", "X", "X"),
    indexTerms = c(
      "ejemplo alfa; afeccion alfa",
      "ejemplo beta",
      "ejemplo beta especificada",
      "ejemplo gamma",
      "severidad leve",
      "agente alfa"
    ),
    # Solo AB00 y AB00.0 admiten post-coordinacion (eje declarado).
    postcoordinationScale = c(
      "",
      "[{\"axisName\":\"ejemplo/hasSeverity\"}]",
      "[{\"axisName\":\"ejemplo/hasSeverity\"}]",
      "", "", ""
    ),
    stringsAsFactors = FALSE
  )
}

.cie11_fixture_map <- function() {
  data.frame(
    cie10_code = c("A000", "A001", "B100"),
    cie10_desc = c(
      "Afeccion ejemplo alfa",
      "Afeccion ejemplo beta variante",
      "Afeccion ejemplo gamma"
    ),
    cie11_code = c("AA00", "AB00", "AC00"),
    cie11_title = c(
      "Afeccion de ejemplo alfa",
      "Afeccion de ejemplo beta",
      "Afeccion de ejemplo gamma"
    ),
    match_type = c("EXACT_TITLE", "FUZZY_JW", "FUZZY_JW"),
    score = c(1.0, 0.86, 0.78),
    stringsAsFactors = FALSE
  )
}
