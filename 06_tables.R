# =============================================================================
# 06_tables.R
# Tabelas para portfólio: gt + formatação editorial
# =============================================================================

source(here::here("00_config.R"))
library(dplyr)
library(tidyr)
install.packages("gt")
library(gt)
install.packages("gtExtras")
library(gtExtras)

message("=== Gerando tabelas ===")

ind <- list(
  brasil       = readRDS(file.path(PATH$processed, "ind_brasil.rds")),
  regiao       = readRDS(file.path(PATH$processed, "ind_regiao.rds")),
  uf           = readRDS(file.path(PATH$processed, "ind_uf.rds")),
  sexo         = readRDS(file.path(PATH$processed, "ind_sexo.rds")),
  raca         = readRDS(file.path(PATH$processed, "ind_raca.rds")),
  escolaridade = readRDS(file.path(PATH$processed, "ind_escolaridade.rds")),
  sexo_raca    = readRDS(file.path(PATH$processed, "ind_sexo_raca.rds")),
  sexo_escol   = readRDS(file.path(PATH$processed, "ind_sexo_escol.rds"))
)

ultimo_tri   <- max(ind$brasil$tri_data)
ultimo_label <- TRIMESTRES$label[TRIMESTRES$data == ultimo_tri]

# -----------------------------------------------------------------------------
# Tema gt padrão do projeto
# -----------------------------------------------------------------------------
tema_gt <- function(tabela) {
  tabela |>
    gt::tab_options(
      table.font.names          = "IBM Plex Sans",
      table.font.size           = gt::px(13),
      table.border.top.style    = "none",
      table.border.bottom.style = "none",
      heading.title.font.size   = gt::px(16),
      heading.subtitle.font.size = gt::px(12),
      heading.border.bottom.style = "solid",
      heading.border.bottom.color = "#E0E0DC",
      heading.border.bottom.width = gt::px(1),
      column_labels.font.weight = "bold",
      column_labels.font.size   = gt::px(12),
      column_labels.border.top.style  = "none",
      column_labels.border.bottom.style = "solid",
      column_labels.border.bottom.color = "#E0E0DC",
      column_labels.border.bottom.width = gt::px(1),
      column_labels.background.color   = "#F7F7F5",
      row.striping.include_table_body  = TRUE,
      row.striping.background_color    = "#FAFAF8",
      data_row.padding    = gt::px(7),
      stub.border.style   = "none",
      source_notes.font.size  = gt::px(10),
      source_notes.border.lr.style = "none",
      table.width = gt::pct(100)
    ) |>
    gt::opt_horizontal_padding(scale = 2)
}

salvar_gt <- function(tabela, nome) {
  path_html <- file.path(PATH$tables, paste0(nome, ".html"))
  path_png  <- file.path(PATH$tables, paste0(nome, ".png"))
  
  gt::gtsave(tabela, path_html)
  gt::gtsave(tabela, path_png, vwidth = 900, vheight = 600, zoom = 2)
  
  message(glue::glue("  >> salvo: {nome}.html + {nome}.png"))
}

# =============================================================================
# TAB 01 — Painel de indicadores nacionais por trimestre
# =============================================================================
message("  >> tab 01")

tab01 <- ind$brasil |>
  dplyr::select(
    trimestre,
    taxa_desocupacao,
    taxa_participacao,
    taxa_ocupacao,
    rend_medio,
    rend_hora,
    horas_medio
  ) |>
  gt::gt() |>
  gt::tab_header(
    title    = "Indicadores do mercado de trabalho — Brasil",
    subtitle = "Estimativas ponderadas por trimestre, 2025–2026"
  ) |>
  gt::cols_label(
    trimestre         = "Trimestre",
    taxa_desocupacao  = "Desocupação (%)",
    taxa_participacao = "Participação (%)",
    taxa_ocupacao     = "Ocupação (%)",
    rend_medio        = "Rendimento médio (R$)",
    rend_hora         = "Rend. por hora (R$)",
    horas_medio       = "Horas semanais"
  ) |>
  gt::fmt_number(
    columns  = c(taxa_desocupacao, taxa_participacao, taxa_ocupacao),
    decimals = 1
  ) |>
  gt::fmt_currency(
    columns  = c(rend_medio, rend_hora),
    currency = "BRL",
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  gt::fmt_number(
    columns  = horas_medio,
    decimals = 1
  ) |>
  gt::cols_align(align = "center", columns = -trimestre) |>
  gt::tab_source_note(
    source_note = caption_pnad()
  ) |>
  gtExtras::gt_highlight_rows(
    rows      = trimestre == ultimo_label,
    fill      = "#EFF5FB",
    font_weight = "bold"
  ) |>
  tema_gt()

salvar_gt(tab01, "tab_01_painel_brasil")

# =============================================================================
# TAB 02 — Desigualdade por raça: último trimestre
# =============================================================================
message("  >> tab 02")

tab02 <- ind$raca |>
  dplyr::filter(tri_data == ultimo_tri, !is.na(raca)) |>
  dplyr::select(
    raca,
    n_forca,
    taxa_desocupacao,
    taxa_participacao,
    rend_medio,
    rend_hora
  ) |>
  dplyr::arrange(dplyr::desc(rend_medio)) |>
  gt::gt() |>
  gt::tab_header(
    title    = "Indicadores por raça/cor — Brasil",
    subtitle = glue::glue("Último trimestre disponível: {ultimo_label}")
  ) |>
  gt::cols_label(
    raca              = "Raça/cor",
    n_forca           = "Força de trabalho",
    taxa_desocupacao  = "Desocupação (%)",
    taxa_participacao = "Participação (%)",
    rend_medio        = "Rendimento médio (R$)",
    rend_hora         = "Rend. por hora (R$)"
  ) |>
  gt::fmt_number(
    columns  = n_forca,
    decimals = 0,
    sep_mark = "."
  ) |>
  gt::fmt_number(
    columns  = c(taxa_desocupacao, taxa_participacao),
    decimals = 1
  ) |>
  gt::fmt_currency(
    columns  = c(rend_medio, rend_hora),
    currency = "BRL",
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  gt::cols_align(align = "center", columns = -raca) |>
  gtExtras::gt_color_rows(
    columns   = taxa_desocupacao,
    palette   = c("#EFF5FB", "#0D2F4A"),
    domain    = NULL,
    direction = 1
  ) |>
  gtExtras::gt_color_rows(
    columns   = rend_medio,
    palette   = c("#FFF3E0", "#7A2E0A"),
    domain    = NULL,
    direction = 1
  ) |>
  gt::tab_source_note(source_note = caption_pnad(ultimo_label)) |>
  tema_gt()

salvar_gt(tab02, "tab_02_indicadores_raca")

# =============================================================================
# TAB 03 — Desigualdade por sexo: série temporal
# =============================================================================
message("  >> tab 03")

tab03 <- ind$sexo |>
  dplyr::filter(!is.na(sexo)) |>
  dplyr::select(trimestre, sexo, taxa_desocupacao, taxa_participacao, rend_medio) |>
  tidyr::pivot_wider(
    names_from  = sexo,
    values_from = c(taxa_desocupacao, taxa_participacao, rend_medio)
  ) |>
  dplyr::mutate(
    gap_desocupacao  = taxa_desocupacao_Mulher  - taxa_desocupacao_Homem,
    gap_participacao = taxa_participacao_Homem  - taxa_participacao_Mulher,
    gap_rendimento   = rend_medio_Homem         - rend_medio_Mulher,
    razao_rendimento = rend_medio_Mulher / rend_medio_Homem * 100
  ) |>
  dplyr::select(
    trimestre,
    taxa_desocupacao_Homem,  taxa_desocupacao_Mulher,  gap_desocupacao,
    taxa_participacao_Homem, taxa_participacao_Mulher, gap_participacao,
    rend_medio_Homem,        rend_medio_Mulher,        razao_rendimento
  ) |>
  gt::gt() |>
  gt::tab_header(
    title    = "Desigualdade de gênero no mercado de trabalho",
    subtitle = "Comparativo entre homens e mulheres por trimestre — Brasil"
  ) |>
  gt::tab_spanner(
    label   = "Desocupação (%)",
    columns = c(taxa_desocupacao_Homem, taxa_desocupacao_Mulher, gap_desocupacao)
  ) |>
  gt::tab_spanner(
    label   = "Participação (%)",
    columns = c(taxa_participacao_Homem, taxa_participacao_Mulher, gap_participacao)
  ) |>
  gt::tab_spanner(
    label   = "Rendimento médio (R$)",
    columns = c(rend_medio_Homem, rend_medio_Mulher, razao_rendimento)
  ) |>
  gt::cols_label(
    trimestre                = "Trimestre",
    taxa_desocupacao_Homem   = "Homem",
    taxa_desocupacao_Mulher  = "Mulher",
    gap_desocupacao          = "Diferença",
    taxa_participacao_Homem  = "Homem",
    taxa_participacao_Mulher = "Mulher",
    gap_participacao         = "Diferença",
    rend_medio_Homem         = "Homem",
    rend_medio_Mulher        = "Mulher",
    razao_rendimento         = "Razão (%)"
  ) |>
  gt::fmt_number(
    columns  = c(
      taxa_desocupacao_Homem, taxa_desocupacao_Mulher, gap_desocupacao,
      taxa_participacao_Homem, taxa_participacao_Mulher, gap_participacao,
      razao_rendimento
    ),
    decimals = 1
  ) |>
  gt::fmt_currency(
    columns  = c(rend_medio_Homem, rend_medio_Mulher),
    currency = "BRL",
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  gt::tab_style(
    style = gt::cell_text(color = "#B03A2E", weight = "bold"),
    locations = gt::cells_body(
      columns = gap_desocupacao,
      rows    = gap_desocupacao > 0
    )
  ) |>
  gt::tab_style(
    style = gt::cell_text(color = "#B03A2E", weight = "bold"),
    locations = gt::cells_body(
      columns = razao_rendimento,
      rows    = razao_rendimento < 90
    )
  ) |>
  gt::cols_align(align = "center", columns = -trimestre) |>
  gt::tab_source_note(source_note = caption_pnad()) |>
  tema_gt()

salvar_gt(tab03, "tab_03_desigualdade_genero")

# =============================================================================
# TAB 04 — Ranking de UFs por rendimento médio
# =============================================================================
message("  >> tab 04")

media_brasil <- ind$brasil |>
  dplyr::filter(tri_data == ultimo_tri) |>
  dplyr::pull(rend_medio)

tab04 <- ind$uf |>
  dplyr::filter(tri_data == ultimo_tri) |>
  dplyr::left_join(UF_META, by = c("uf" = "codigo")) |>
  dplyr::arrange(dplyr::desc(rend_medio)) |>
  dplyr::mutate(
    rank         = dplyr::row_number(),
    vs_brasil    = (rend_medio / media_brasil - 1) * 100
  ) |>
  dplyr::select(
    rank, sigla, regiao,
    taxa_desocupacao, taxa_participacao,
    rend_medio, vs_brasil
  ) |>
  gt::gt() |>
  gt::tab_header(
    title    = "Ranking de Unidades da Federação por rendimento médio",
    subtitle = glue::glue(
      "{ultimo_label} — ocupados com rendimento positivo"
    )
  ) |>
  gt::cols_label(
    rank              = "#",
    sigla             = "UF",
    regiao            = "Região",
    taxa_desocupacao  = "Desocupação (%)",
    taxa_participacao = "Participação (%)",
    rend_medio        = "Rendimento médio (R$)",
    vs_brasil         = "vs. Brasil (%)"
  ) |>
  gt::fmt_number(
    columns  = c(taxa_desocupacao, taxa_participacao),
    decimals = 1
  ) |>
  gt::fmt_currency(
    columns  = rend_medio,
    currency = "BRL",
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  gt::fmt_number(
    columns  = vs_brasil,
    decimals = 1,
    force_sign = TRUE
  ) |>
  gt::tab_style(
    style = gt::cell_text(color = "#2E7D32", weight = "bold"),
    locations = gt::cells_body(
      columns = vs_brasil,
      rows    = vs_brasil > 0
    )
  ) |>
  gt::tab_style(
    style = gt::cell_text(color = "#B03A2E", weight = "bold"),
    locations = gt::cells_body(
      columns = vs_brasil,
      rows    = vs_brasil < 0
    )
  ) |>
  gtExtras::gt_color_rows(
    columns   = rend_medio,
    palette   = c("#F5F0E8", "#7A2E0A"),
    domain    = NULL,
    direction = 1
  ) |>
  gt::cols_align(align = "center", columns = c(rank, taxa_desocupacao, taxa_participacao, rend_medio, vs_brasil)) |>
  gt::tab_source_note(source_note = caption_pnad(ultimo_label)) |>
  tema_gt()

salvar_gt(tab04, "tab_04_ranking_uf_rendimento")

# =============================================================================
# TAB 05 — Retorno educacional: rendimento e desocupação por escolaridade
# =============================================================================
message("  >> tab 05")

tab05 <- ind$escolaridade |>
  dplyr::filter(!is.na(escolaridade)) |>
  dplyr::select(
    trimestre, escolaridade,
    taxa_desocupacao, taxa_participacao,
    rend_medio, rend_hora, horas_medio
  ) |>
  dplyr::arrange(trimestre, escolaridade) |>
  gt::gt(groupname_col = "trimestre") |>
  gt::tab_header(
    title    = "Mercado de trabalho por nível de escolaridade",
    subtitle = "Retorno educacional em taxas de inserção e rendimento — Brasil"
  ) |>
  gt::cols_label(
    escolaridade      = "Escolaridade",
    taxa_desocupacao  = "Desocupação (%)",
    taxa_participacao = "Participação (%)",
    rend_medio        = "Rendimento médio (R$)",
    rend_hora         = "Rend. por hora (R$)",
    horas_medio       = "Horas semanais"
  ) |>
  gt::fmt_number(
    columns  = c(taxa_desocupacao, taxa_participacao, horas_medio),
    decimals = 1
  ) |>
  gt::fmt_currency(
    columns  = c(rend_medio, rend_hora),
    currency = "BRL",
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  gt::tab_style(
    style     = gt::cell_fill(color = "#F7F7F5"),
    locations = gt::cells_row_groups()
  ) |>
  gt::tab_style(
    style     = gt::cell_text(weight = "bold", size = gt::px(12)),
    locations = gt::cells_row_groups()
  ) |>
  gtExtras::gt_color_rows(
    columns   = rend_medio,
    palette   = c("#D9E8F5", "#0D3B5C"),
    domain    = NULL,
    direction = 1
  ) |>
  gt::cols_align(align = "center", columns = -escolaridade) |>
  gt::tab_source_note(source_note = caption_pnad()) |>
  tema_gt()

salvar_gt(tab05, "tab_05_retorno_educacional")

message("=== Tabelas concluídas ===")