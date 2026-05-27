# =============================================================================
# 04_visualizations.R
# Gráficos temáticos para portfólio
# Requer: 00_config.R + indicadores em data/processed/
# =============================================================================

source(here::here("00_config.R"))
library(dplyr)
library(ggplot2)
library(forcats)
library(scales)
#install.packages("patchwork")
library(patchwork)

message("=== Gerando visualizações ===")

# --- Carrega indicadores ---
ind <- list(
  brasil       = readRDS(file.path(PATH$processed, "ind_brasil.rds")),
  regiao       = readRDS(file.path(PATH$processed, "ind_regiao.rds")),
  uf           = readRDS(file.path(PATH$processed, "ind_uf.rds")),
  sexo         = readRDS(file.path(PATH$processed, "ind_sexo.rds")),
  raca         = readRDS(file.path(PATH$processed, "ind_raca.rds")),
  escolaridade = readRDS(file.path(PATH$processed, "ind_escolaridade.rds")),
  sexo_raca    = readRDS(file.path(PATH$processed, "ind_sexo_raca.rds")),
  sexo_escol   = readRDS(file.path(PATH$processed, "ind_sexo_escol.rds")),
  uf_sexo      = readRDS(file.path(PATH$processed, "ind_uf_sexo.rds")),
  regiao_raca  = readRDS(file.path(PATH$processed, "ind_regiao_raca.rds"))
)

# =============================================================================
# FIG 01 — Evolução da taxa de desocupação no Brasil
# =============================================================================
message("  >> fig 01")

p01 <- ind$brasil |>
  ggplot(aes(x = tri_data, y = taxa_desocupacao)) +
  geom_ribbon(
    aes(ymin = taxa_desocupacao * 0.97, ymax = taxa_desocupacao * 1.03),
    fill = CORES$sudeste, alpha = 0.10
  ) +
  geom_line(color = CORES$sudeste, linewidth = 1.1) +
  geom_point(
    shape = 21, size = 3.2, stroke = 1.4,
    color = "white", fill = CORES$sudeste
  ) +
  geom_text(
    aes(label = number(taxa_desocupacao, accuracy = 0.1, suffix = "%")),
    vjust = -1.4, size = 3.2, family = FONTE_CORPO, color = CORES$subtexto
  ) +
  scale_x_date(
    breaks = ind$brasil$tri_data,
    labels = TRIMESTRES$label[match(ind$brasil$tri_data, TRIMESTRES$data)]
  ) +
  scale_y_continuous(
    labels = label_percent(scale = 1, accuracy = 1),
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.2))
  ) +
  labs(
    title   = "Taxa de desocupação — Brasil",
    subtitle = "Percentual da força de trabalho sem ocupação, 2025–2026",
    x = NULL, y = "Taxa de desocupação (%)",
    caption = caption_pnad()
  )

salvar_figura("01_desocupacao_brasil", largura = 10, altura = 5.5)

# =============================================================================
# FIG 02 — Evolução por sexo
# =============================================================================
message("  >> fig 02")

p02 <- ind$sexo |>
  dplyr::filter(!is.na(sexo)) |>
  ggplot(aes(x = tri_data, y = taxa_desocupacao, color = sexo, group = sexo)) +
  geom_line(linewidth = 1.0) +
  geom_point(aes(fill = sexo), shape = 21, size = 2.8, stroke = 1.2, color = "white") +
  scale_color_manual(values = PALETA_SEXO, name = NULL) +
  scale_fill_manual(values = PALETA_SEXO,  name = NULL) +
  scale_x_date(
    breaks = ind$sexo$tri_data |> unique(),
    labels = TRIMESTRES$label[match(unique(ind$sexo$tri_data), TRIMESTRES$data)]
  ) +
  scale_y_continuous(
    labels = label_percent(scale = 1, accuracy = 1),
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title    = "Taxa de desocupação por sexo",
    subtitle = "Desigualdade de gênero no mercado de trabalho brasileiro",
    x = NULL, y = "Taxa de desocupação (%)",
    caption = caption_pnad()
  ) +
  tema_pnad(legenda_pos = "top")

salvar_figura("02_desocupacao_sexo", largura = 10, altura = 5.5)

# =============================================================================
# FIG 03 — Evolução por raça/cor
# =============================================================================
message("  >> fig 03")

p03 <- ind$raca |>
  dplyr::filter(!is.na(raca), raca %in% c("Branca", "Preta", "Parda")) |>
  ggplot(aes(x = tri_data, y = taxa_desocupacao, color = raca, group = raca)) +
  geom_line(linewidth = 1.0) +
  geom_point(aes(fill = raca), shape = 21, size = 2.8, stroke = 1.2, color = "white") +
  scale_color_manual(values = PALETA_RACA, name = NULL) +
  scale_fill_manual(values  = PALETA_RACA, name = NULL) +
  scale_x_date(
    breaks = unique(ind$raca$tri_data),
    labels = TRIMESTRES$label[match(unique(ind$raca$tri_data), TRIMESTRES$data)]
  ) +
  scale_y_continuous(
    labels = label_percent(scale = 1, accuracy = 1),
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title    = "Taxa de desocupação por raça/cor",
    subtitle = "Comparativo entre grupos — populações Branca, Preta e Parda",
    x = NULL, y = "Taxa de desocupação (%)",
    caption = caption_pnad()
  ) +
  tema_pnad(legenda_pos = "top")

salvar_figura("03_desocupacao_raca", largura = 10, altura = 5.5)

# =============================================================================
# FIG 04 — Rendimento médio por escolaridade
# =============================================================================
message("  >> fig 04")

p04 <- ind$escolaridade |>
  dplyr::filter(!is.na(escolaridade)) |>
  ggplot(aes(x = tri_data, y = rend_medio, color = escolaridade, group = escolaridade)) +
  geom_line(linewidth = 0.9) +
  geom_point(aes(fill = escolaridade), shape = 21, size = 2.6, stroke = 1.1, color = "white") +
  scale_color_manual(values = PALETA_ESCOL, name = NULL) +
  scale_fill_manual(values  = PALETA_ESCOL, name = NULL) +
  scale_x_date(
    breaks = unique(ind$escolaridade$tri_data),
    labels = TRIMESTRES$label[match(unique(ind$escolaridade$tri_data), TRIMESTRES$data)]
  ) +
  scale_y_continuous(
    labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ","),
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title    = "Rendimento médio por nível de escolaridade",
    subtitle = "Retorno educacional no mercado de trabalho — ocupados com rendimento positivo",
    x = NULL, y = "Rendimento médio (R$)",
    caption = caption_pnad()
  ) +
  tema_pnad(legenda_pos = "top") +
  guides(color = guide_legend(nrow = 2), fill = guide_legend(nrow = 2))

salvar_figura("04_rendimento_escolaridade", largura = 10, altura = 6)

# =============================================================================
# FIG 05 — Dotplot: rendimento por UF no último trimestre
# =============================================================================
message("  >> fig 05")

ultimo_tri <- max(ind$uf$tri_data)

p05 <- ind$uf |>
  dplyr::filter(tri_data == ultimo_tri) |>
  dplyr::left_join(UF_META, by = c("uf" = "codigo")) |>
  dplyr::mutate(sigla = forcats::fct_reorder(sigla, rend_medio)) |>
  ggplot(aes(x = rend_medio, y = sigla, color = regiao)) +
  geom_segment(
    aes(x = 0, xend = rend_medio, yend = sigla),
    color = CORES$cinza2, linewidth = 0.7
  ) +
  geom_point(size = 3.2) +
  geom_vline(
    xintercept = ind$brasil |>
      dplyr::filter(tri_data == ultimo_tri) |>
      dplyr::pull(rend_medio),
    linetype = "dashed", color = CORES$cinza3, linewidth = 0.7
  ) +
  scale_color_manual(values = PALETA_REGIAO, name = "Região") +
  scale_x_continuous(
    labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ","),
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title    = "Rendimento médio dos ocupados por Unidade da Federação",
    subtitle = glue::glue(
      "Último trimestre disponível — ",
      "linha tracejada: média nacional"
    ),
    x = "Rendimento médio (R$)", y = NULL,
    caption = caption_pnad(
      TRIMESTRES$label[TRIMESTRES$data == ultimo_tri]
    )
  ) +
  tema_pnad(grid_v = TRUE, legenda_pos = "bottom")

salvar_figura("05_rendimento_uf_dotplot", largura = 9, altura = 11)

# =============================================================================
# FIG 06 — Heatmap: rendimento por sexo × raça
# =============================================================================
message("  >> fig 06")

p06 <- ind$sexo_raca |>
  dplyr::filter(!is.na(sexo), !is.na(raca)) |>
  dplyr::mutate(raca = forcats::fct_reorder(raca, rend_medio)) |>
  ggplot(aes(x = sexo, y = raca, fill = rend_medio)) +
  geom_tile(color = "white", linewidth = 0.8) +
  geom_text(
    aes(label = label_dollar(
      prefix = "R$ ", big.mark = ".", decimal.mark = ","
    )(rend_medio)),
    size = 3.0, family = FONTE_CORPO, color = "white", fontface = "bold"
  ) +
  facet_wrap(~trimestre, nrow = 1) +
  scale_fill_gradientn(
    colours = c("#D9E8F5","#2672B0","#0D3B5C"),
    labels  = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ","),
    name    = "Rendimento médio (R$)"
  ) +
  labs(
    title    = "Rendimento médio por sexo e raça/cor",
    subtitle = "Interseção de gênero e raça no diferencial salarial — Brasil",
    x = NULL, y = NULL,
    caption = caption_pnad()
  ) +
  tema_pnad(grid_h = FALSE, legenda_pos = "right") +
  theme(
    panel.spacing  = unit(0.8, "lines"),
    axis.text.x    = element_text(size = 9),
    legend.key.width = unit(2, "lines")
  )

salvar_figura("06_rendimento_sexo_raca_heatmap", largura = 14, altura = 5.5)

# =============================================================================
# FIG 07 — Taxa de participação por escolaridade e sexo
# =============================================================================
message("  >> fig 07")

p07 <- ind$sexo_escol |>
  dplyr::filter(!is.na(sexo), !is.na(escolaridade)) |>
  dplyr::mutate(
    escolaridade = forcats::fct_rev(escolaridade)
  ) |>
  ggplot(aes(x = taxa_participacao, y = escolaridade, fill = sexo)) +
  geom_col(
    position = position_dodge(width = 0.7),
    width = 0.6
  ) +
  facet_wrap(~trimestre, nrow = 1) +
  scale_fill_manual(values = PALETA_SEXO, name = NULL) +
  scale_x_continuous(
    labels = label_percent(scale = 1, accuracy = 1),
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title    = "Taxa de participação na força de trabalho por escolaridade e sexo",
    subtitle = "Interação entre nível educacional e gênero na inserção laboral",
    x = "Taxa de participação (%)", y = NULL,
    caption = caption_pnad()
  ) +
  tema_pnad(grid_v = TRUE, grid_h = FALSE, legenda_pos = "top") +
  theme(panel.spacing = unit(0.8, "lines"))

salvar_figura("07_participacao_escol_sexo", largura = 14, altura = 6)

# =============================================================================
# FIG 08 — Desigualdade regional: boxplot de rendimento por região
# =============================================================================
message("  >> fig 08")

# Para este gráfico usamos o nível UF como unidade de variação dentro de cada região
glimpse(ind$sexo_escol)
head(ind$sexo_escol)

p08 <- ind$uf |>
  dplyr::left_join(UF_META, by = c("uf" = "codigo")) |>
  dplyr::filter(!is.na(regiao), !is.na(rend_medio)) |>
  dplyr::mutate(regiao = forcats::fct_reorder(regiao, rend_medio)) |>
  ggplot(aes(x = rend_medio, y = regiao, fill = regiao, color = regiao)) +
  geom_boxplot(
    alpha = 0.25, outlier.shape = 21, outlier.size = 2.5,
    outlier.stroke = 0.8, width = 0.5
  ) +
  geom_jitter(height = 0.15, size = 1.8, alpha = 0.6) +
  scale_fill_manual(values  = PALETA_REGIAO, guide = "none") +
  scale_color_manual(values = PALETA_REGIAO, guide = "none") +
  scale_x_continuous(
    labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ",")
  ) +
  facet_wrap(~trimestre, nrow = 1) +
  labs(
    title    = "Distribuição do rendimento médio por macrorregião",
    subtitle = "Cada ponto representa uma UF — variação intra e inter-regional",
    x = "Rendimento médio (R$)", y = NULL,
    caption = caption_pnad()
  ) +
  tema_pnad(grid_v = TRUE, grid_h = FALSE) +
  theme(panel.spacing = unit(0.8, "lines"))

salvar_figura("08_rendimento_regiao_boxplot", largura = 14, altura = 5.5)

message("=== Visualizações concluídas ===")

