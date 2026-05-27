# =============
# 01_download.R
# Download dos microdados da PNAD Contínua via PNADcIBGE
# Salva um .rds por trimestre em data/raw/
# ========================================

source(here::here("00_config.R"))
library(PNADcIBGE)
library(dplyr)
library(purrr)

VARIAVEIS <- c(
  "UF",
  "V1028",   # peso amostral
  "V2007",   # sexo
  "V2009",   # idade
  "V2010",   # cor/raça
  "VD3005",  # nível de instrução
  "VD4001",  # condição na força de trabalho
  "VD4002",  # condição de ocupação
  "VD4016",  # rendimento habitual do trabalho principal
  "VD4019",  # rendimento habitual de todos os trabalhos
  "VD4020",  # rendimento efetivo de todos os trabalhos
  "VD4031",  # horas habitualmente trabalhadas em todos os trabalhos
  "V4010",   # posição na ocupação
  "V1022"    # situação do domicílio (urbano/rural)
)

baixar_trimestre <- function(ano, tri) {
  nome_arquivo <- file.path(PATH$raw, glue::glue("pnad_{ano}_{tri}t.rds"))
  
  if (file.exists(nome_arquivo)) {
    message(glue::glue("  >> já existe: pnad_{ano}_{tri}t.rds — pulando"))
    return(invisible(NULL))
  }
  
  message(glue::glue("  >> baixando {tri}T{ano}..."))
  
  dados <- tryCatch(
    PNADcIBGE::get_pnadc(
      year      = ano,
      quarter   = tri,
      vars      = VARIAVEIS,
      labels    = FALSE,
      deflator  = FALSE,
      design    = FALSE
    ),
    error = function(e) {
      warning(glue::glue("Erro ao baixar {tri}T{ano}: {e$message}"))
      return(NULL)
    }
  )
  
  if (!is.null(dados)) {
    dados <- dados |>
      dplyr::mutate(
        Ano       = as.integer(ano),
        Trimestre = as.integer(tri)
      )
    saveRDS(dados, nome_arquivo)
    message(glue::glue("  >> salvo: pnad_{ano}_{tri}t.rds"))
  }
}

# Executa o download de todos os trimestres
message("=== Iniciando downloads ===")
purrr::walk2(TRIMESTRES$ano, TRIMESTRES$tri, baixar_trimestre)
message("=== Downloads concluídos ===")
