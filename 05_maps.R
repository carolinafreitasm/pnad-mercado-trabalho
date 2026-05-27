# =============================================================================
# 05_maps.R
# Mapas coropléticos com geobr + ggplot2
# Requer: 00_config.R + indicadores em data/processed/
# =============================================================================

source(here::here("00_config.R"))
library(dplyr)
library(ggplot2)
library(sf)
library(geobr)
library(classInt)
library(patchwork)

message("=== Gerando mapas ===")

# --- Geometria das UFs ---
message("  >> carregando geometria das UFs...")
uf_geo <- geobr::read_state(year = 2020, showProgress = FALSE) |>
  dplyr::mutate(uf = as.character(code_state))

# --- Indicadores ---
ind_uf <- readRDS(file.path(PATH$processed, "ind_uf.rds"))

ultimo_tri       <- max(ind_uf$tri_data)
ultimo_tri_label <- TRIMESTRES$label[TRIMESTRES$data == ultimo_tri]

ind_uf_ultimo <- ind_uf |>
  dplyr::filter(tri_data == ultimo_tri) |>
  dplyr::left_join(UF_META, by = c("uf" = "codigo"))

# Join com geometria
mapa_df <- uf_geo |>
  dplyr::left_join(ind_uf_ultimo, by = "uf")

# -----------------------------------------------------------------------------
# Função construtora de mapa coroplético
# -----------------------------------------------------------------------------
mapa_coroplético <- function(
    dados,
    variavel,
    titulo,
    subtitulo,
    legenda,
    palette_cores,
    formato_labels = scales::label_number(big.mark = ".", decimal.mark = ","),
    n_classes = 5
) {
  vals <- dplyr::pull(dados, {{ variavel }})
  breaks_jenks <- classInt::classIntervals(
    vals[!is.na(vals)], n = n_classes, style = "jenks"
  )$brks
  
  ggplot2::ggplot(dados) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = {{ variavel }}),
      color = "white", linewidth = 0.3
    ) +
    ggplot2::scale_fill_stepsn(
      colours  = palette_cores,
      breaks   = breaks_jenks,
      labels   = formato_labels,
      name     = legenda,
      guide    = ggplot2::guide_colorsteps(
        barwidth       = ggplot2::unit(14, "lines"),
        barheight      = ggplot2::unit(0.55, "lines"),
        title.position = "top",
        title.hjust    = 0.5
      ),
      na.value = CORES$cinza2
    ) +
    ggplot2::labs(
      title    = titulo,
      subtitle = subtitulo,
      caption  = caption_pnad(ultimo_tri_label)
    ) +
    ggplot2::coord_sf(xlim = c(-75, -28), ylim = c(-35, 6), expand = FALSE) +
    tema_pnad(grid_h = FALSE) +
    ggplot2::theme(
      axis.text        = ggplot2::element_blank(),
      axis.title       = ggplot2::element_blank(),
      panel.background = ggplot2::element_rect(fill = "#EDF1F5", color = NA),
      plot.background  = ggplot2::element_rect(fill = "white",   color = NA),
      legend.position  = "bottom"
    )
}

# =============================================================================
# MAPA 01 — Taxa de desocupação por UF
# =============================================================================
message("  >> mapa 01")

m01 <- mapa_coroplético(
  dados          = mapa_df,
  variavel       = taxa_desocupacao,
  titulo         = "Taxa de desocupação por Unidade da Federação",
  subtitulo      = glue::glue("{ultimo_tri_label} — classes por quebras naturais (Jenks)"),
  legenda        = "Taxa de desocupação (%)",
  palette_cores  = c("#EFF5FB","#B3D1EC","#4A9AC5","#1B5F8A","#0D2F4A"),
  formato_labels = scales::label_percent(scale = 1, accuracy = 0.1)
)

salvar_mapa("mapa_01_desocupacao_uf")

# =============================================================================
# MAPA 02 — Rendimento médio dos ocupados por UF
# =============================================================================
message("  >> mapa 02")

m02 <- mapa_coroplético(
  dados          = mapa_df,
  variavel       = rend_medio,
  titulo         = "Rendimento médio dos ocupados por Unidade da Federação",
  subtitulo      = glue::glue("{ultimo_tri_label} — classes por quebras naturais (Jenks)"),
  legenda        = "Rendimento médio (R$)",
  palette_cores  = c("#F5F0E8","#D4A04A","#B05A1E","#7A2E0A","#3D1205"),
  formato_labels = scales::label_dollar(
    prefix = "R$ ", big.mark = ".", decimal.mark = ","
  )
)

salvar_mapa("mapa_02_rendimento_uf")

# =============================================================================
# MAPA 03 — Taxa de participação feminina por UF
# =============================================================================
message("  >> mapa 03")

ind_uf_sexo <- readRDS(file.path(PATH$processed, "ind_uf_sexo.rds"))

mapa_mulher <- uf_geo |>
  dplyr::left_join(
    ind_uf_sexo |>
      dplyr::filter(tri_data == ultimo_tri, sexo == "Mulher"),
    by = "uf"
  )

m03 <- mapa_coroplético(
  dados          = mapa_mulher,
  variavel       = taxa_participacao,
  titulo         = "Taxa de participação feminina na força de trabalho",
  subtitulo      = glue::glue("{ultimo_tri_label} — proporção de mulheres na PIT inseridas na força de trabalho"),
  legenda        = "Taxa de participação — Mulheres (%)",
  palette_cores  = c("#FFF0F0","#F5A8A0","#C0392B","#8B1A10","#4A0A06"),
  formato_labels = scales::label_percent(scale = 1, accuracy = 0.1)
)

salvar_mapa("mapa_03_participacao_feminina")

# =============================================================================
# PAINEL: Desocupação + Rendimento lado a lado
# =============================================================================
message("  >> painel comparativo")

painel <- m01 + m02 +
  patchwork::plot_annotation(
    title   = "Desigualdade regional no mercado de trabalho brasileiro",
    subtitle = glue::glue(
      "Comparativo entre taxa de desocupação e rendimento médio — {ultimo_tri_label}"
    ),
    caption = caption_pnad(ultimo_tri_label),
    theme   = tema_pnad()
  )

ggplot2::ggsave(
  filename = file.path(PATH$maps, "mapa_painel_desocupacao_rendimento.png"),
  plot     = painel,
  width    = 16, height = 9, dpi = 300, bg = "white"
)
message("  >> mapa painel salvo")

message("=== Mapas concluídos ===")