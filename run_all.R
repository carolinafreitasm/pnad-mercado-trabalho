# =============================================================================
# run_all.R
# Executa o pipeline completo do projeto PNAD Contínua
# Ordem obrigatória — não altere a sequência
# =============================================================================
message("\n========================================")
message("  PNAD Contínua — Pipeline completo")
message("========================================\n")

inicio <- Sys.time()

scripts <- c(
  "00_config.R",
  "01_download.R",
  "02_process.R",
  "03_indicators.R",
  "04_visualizations.R",
  "05_maps.R",
  "06_tables.R",
  "07_logit.R"
)

for (script in scripts) {
  message(glue::glue("\n>>> Executando: {script}"))
  t0 <- Sys.time()
  source(here::here(script))
  t1 <- Sys.time()
  message(glue::glue("    concluído em {round(difftime(t1, t0, units='mins'), 1)} min"))
}

fim <- Sys.time()
message(glue::glue(
  "\n========================================",
  "\n  Pipeline concluído em ",
  "{round(difftime(fim, inicio, units='mins'), 1)} minutos",
  "\n========================================"
))