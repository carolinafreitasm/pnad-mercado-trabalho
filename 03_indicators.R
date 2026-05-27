# =============================================================================
# 03_indicators.R
# Calcula indicadores ponderados por corte temático
# Salva um .rds por corte em data/processed/
# =============================================================================

source(here::here("00_config.R"))
library(dplyr)
library(purrr)
library(rlang)

message("=== Calculando indicadores ===")

pnad <- readRDS(file.path(PATH$processed, "pnad_reduzida.rds"))

# -----------------------------------------------------------------------------
# Função central
# -----------------------------------------------------------------------------
calcular_indicadores <- function(dados, ...) {
  grupos <- rlang::enquos(...)
  
  dados |>
    dplyr::group_by(trimestre, ano, tri, tri_data, !!!grupos) |>
    dplyr::summarise(
      n_pit      = sum(peso[pit],            na.rm = TRUE),
      n_forca    = sum(peso[forca_trabalho], na.rm = TRUE),
      n_ocupado  = sum(peso[ocupado],        na.rm = TRUE),
      n_desocup  = sum(peso[desocupado],     na.rm = TRUE),
      n_fora     = sum(peso[fora_forca],     na.rm = TRUE),
      
      taxa_desocupacao  = 100 * n_desocup / n_forca,
      taxa_participacao = 100 * n_forca   / n_pit,
      taxa_ocupacao     = 100 * n_ocupado / n_pit,
      
      rend_medio  = weighted.mean(rendimento,      w = peso, na.rm = TRUE),
      rend_hora   = weighted.mean(rendimento_hora, w = peso, na.rm = TRUE),
      horas_medio = weighted.mean(horas_semana,    w = peso, na.rm = TRUE),
      
      .groups = "drop"
    )
}

# -----------------------------------------------------------------------------
# Cortes temáticos
# -----------------------------------------------------------------------------
cortes <- list(
  brasil       = calcular_indicadores(pnad),
  uf           = calcular_indicadores(pnad, uf),
  regiao       = calcular_indicadores(pnad, regiao),
  sexo         = calcular_indicadores(pnad, sexo),
  raca         = calcular_indicadores(pnad, raca),
  escolaridade = calcular_indicadores(pnad, escolaridade),
  urbano       = calcular_indicadores(pnad, urbano),
  sexo_raca    = calcular_indicadores(pnad, sexo, raca),
  sexo_escol   = calcular_indicadores(pnad, sexo, escolaridade),
  uf_sexo      = calcular_indicadores(pnad, uf, sexo),
  regiao_raca  = calcular_indicadores(pnad, regiao, raca)
)

# Salva cada corte e registra no console
purrr::iwalk(cortes, \(df, nome) {
  path_out <- file.path(PATH$processed, paste0("ind_", nome, ".rds"))
  saveRDS(df, path_out)
  message(glue::glue("  >> salvo: ind_{nome}.rds  ({nrow(df)} linhas)"))
})

message("=== Indicadores concluídos ===")