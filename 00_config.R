# ============================================
# 00_config.R
# Configuração global do projeto PNAD Contínua
# ============================================
#install.packages("here")
library(here)
library(ggplot2)
#install.packages("showtext")
library(showtext)
library(glue)

# --------
# Caminhos
# --------
PATH <- list(
  raw       = here("data", "raw"),
  processed = here("data", "processed"),
  figures   = here("outputs", "figures"),
  maps      = here("outputs", "maps"),
  tables    = here("outputs", "tables")
)

purrr::walk(PATH, \(p) dir.create(p, showWarnings = FALSE, recursive = TRUE))

# ---------------------
# Trimestres do projeto
# ---------------------
TRIMESTRES <- tibble::tibble(
  ano    = c(2025, 2025, 2025, 2025, 2026),
  tri    = c(1,    2,    3,    4,    1),
  label  = c("1T25","2T25","3T25","4T25","1T26"),
  data   = as.Date(c(
    "2025-01-01","2025-04-01","2025-07-01","2025-10-01","2026-01-01"
  ))
)

# ----------------
# Paleta semântica
# ----------------
CORES <- list(
  homem      = "#1B5E9B",
  mulher     = "#B03A2E",
  
  branca     = "#2C6E9B",
  preta      = "#A63A2F",
  amarela    = "#C8970F",
  parda      = "#4A7A35",
  indigena   = "#7B4F9E",
  
  escol_1    = "#D9E8F5",
  escol_2    = "#7EB4D9",
  escol_3    = "#2672B0",
  escol_4    = "#0D3B5C",
  
  norte      = "#2E9FC6",
  nordeste   = "#D4450C",
  centro     = "#8B6914",
  sudeste    = "#1B6CA8",
  sul        = "#2E7D32",
  
  destaque   = "#F4A623",
  cinza1     = "#F7F7F5",
  cinza2     = "#E0E0DC",
  cinza3     = "#9E9E9A",
  texto      = "#1A1A1A",
  subtexto   = "#555550"
)

PALETA_RACA <- c(
  "Branca"   = CORES$branca,
  "Preta"    = CORES$preta,
  "Amarela"  = CORES$amarela,
  "Parda"    = CORES$parda,
  "Indígena" = CORES$indigena
)

PALETA_SEXO <- c(
  "Homem"  = CORES$homem,
  "Mulher" = CORES$mulher
)

PALETA_ESCOL <- c(
  "Até fund. incompleto"         = CORES$escol_1,
  "Fund. completo / médio inc."  = CORES$escol_2,
  "Médio completo / sup. inc."   = CORES$escol_3,
  "Superior completo"            = CORES$escol_4
)

PALETA_REGIAO <- c(
  "Norte"        = CORES$norte,
  "Nordeste"     = CORES$nordeste,
  "Centro-Oeste" = CORES$centro,
  "Sudeste"      = CORES$sudeste,
  "Sul"          = CORES$sul
)

# ----------
# Tipografia
# ----------
font_add_google("IBM Plex Sans",  family = "ibm")
font_add_google("IBM Plex Serif", family = "ibm_serif")
showtext_auto()
showtext_opts(dpi = 300)

FONTE_TITULO <- "ibm_serif"
FONTE_CORPO  <- "ibm"

# ------------
# Tema ggplot2
# ------------
tema_pnad <- function(
    grid_h       = TRUE,
    grid_v       = FALSE,
    legenda_pos  = "bottom",
    base_size    = 11
) {
  ggplot2::theme_minimal(base_size = base_size, base_family = FONTE_CORPO) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        family = FONTE_TITULO, size = base_size + 6,
        color = CORES$texto, margin = ggplot2::margin(b = 5)
      ),
      plot.subtitle = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size + 1,
        color = CORES$subtexto, margin = ggplot2::margin(b = 14)
      ),
      plot.caption = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size - 2,
        color = CORES$cinza3, hjust = 0,
        margin = ggplot2::margin(t = 10)
      ),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      
      axis.title = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size - 1, color = CORES$subtexto
      ),
      axis.text = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size - 1, color = CORES$subtexto
      ),
      axis.ticks = ggplot2::element_blank(),
      axis.line  = ggplot2::element_blank(),
      
      panel.grid.major.y = if (grid_h) ggplot2::element_line(
        color = CORES$cinza2, linewidth = 0.3
      ) else ggplot2::element_blank(),
      panel.grid.major.x = if (grid_v) ggplot2::element_line(
        color = CORES$cinza2, linewidth = 0.3
      ) else ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      
      legend.position  = legenda_pos,
      legend.title     = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size - 1, color = CORES$subtexto
      ),
      legend.text = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size - 1, color = CORES$texto
      ),
      legend.key.size = ggplot2::unit(0.85, "lines"),
      
      strip.text = ggplot2::element_text(
        family = FONTE_CORPO, size = base_size, color = CORES$texto
      ),
      strip.background = ggplot2::element_rect(fill = CORES$cinza1, color = NA),
      
      plot.margin = ggplot2::margin(16, 20, 12, 16)
    )
}

ggplot2::theme_set(tema_pnad())

# -------
# Helpers
# -------
caption_pnad <- function(periodo = "1T2025–1T2026") {
  glue::glue(
    "Fonte: PNAD Contínua / IBGE ({periodo}). ",
    "Estimativas com pesos amostrais (V1028)."
  )
}

salvar_figura <- function(nome, largura = 10, altura = 6.5, dpi = 300, subdir = NULL) {
  destino <- if (!is.null(subdir)) file.path(PATH$figures, subdir) else PATH$figures
  dir.create(destino, showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(
    filename = file.path(destino, paste0(nome, ".png")),
    width = largura, height = altura, dpi = dpi, bg = "white"
  )
  message(glue::glue("  >> salvo: {nome}.png"))
}

salvar_mapa <- function(nome, largura = 8, altura = 9, dpi = 300) {
  ggplot2::ggsave(
    filename = file.path(PATH$maps, paste0(nome, ".png")),
    width = largura, height = altura, dpi = dpi, bg = "white"
  )
  message(glue::glue("  >> mapa salvo: {nome}.png"))
}

# ---------------------------------
# Lookup: UF código → nome + região
# ---------------------------------
UF_META <- tibble::tibble(
  codigo = c("11","12","13","14","15","16","17",
             "21","22","23","24","25","26","27","28","29",
             "31","32","33","35",
             "41","42","43",
             "50","51","52","53"),
  sigla  = c("RO","AC","AM","RR","PA","AP","TO",
             "MA","PI","CE","RN","PB","PE","AL","SE","BA",
             "MG","ES","RJ","SP",
             "PR","SC","RS",
             "MS","MT","GO","DF"),
  regiao = c(rep("Norte", 7), rep("Nordeste", 9),
             rep("Sudeste", 4), rep("Sul", 3), rep("Centro-Oeste", 4))
)