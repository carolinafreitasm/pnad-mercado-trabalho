# =============================================================================
# 02_process.R
# Processa microdados brutos → pnad_reduzida.rds
# Aplica labels, cria variáveis derivadas, padroniza tipos
# =============================================================================

setwd("#caminho")
source(here::here("00_config.R"))
library(dplyr)
library(purrr)

message("=== Processando microdados ===")

# Carrega e empilha todos os trimestres
arquivos <- list.files(PATH$raw, pattern = "^pnad_\\d{4}_\\dt\\.rds$", full.names = TRUE)

if (length(arquivos) == 0) stop("Nenhum arquivo encontrado em data/raw/. Execute 01_download.R primeiro.")

pnad_raw <- purrr::map(arquivos, readRDS) |> dplyr::bind_rows()

message(glue::glue("  >> {format(nrow(pnad_raw), big.mark='.')} linhas carregadas de {length(arquivos)} trimestre(s)"))

# -----------------------------------------------------------------------------
# Processamento principal
# -----------------------------------------------------------------------------
pnad_reduzida <- pnad_raw |>
  dplyr::mutate(
    # --- Identificação temporal ---
    trimestre = paste0(Trimestre, "T", Ano),
    ano       = as.integer(Ano),
    tri       = as.integer(Trimestre),
    tri_data  = as.Date(dplyr::case_when(
      tri == 1 ~ paste0(ano, "-01-01"),
      tri == 2 ~ paste0(ano, "-04-01"),
      tri == 3 ~ paste0(ano, "-07-01"),
      tri == 4 ~ paste0(ano, "-10-01")
    )),
    
    # --- Identificação geográfica ---
    uf     = as.character(UF),
    urbano = dplyr::case_when(
      V1022 == "1" ~ TRUE,
      V1022 == "2" ~ FALSE,
      TRUE         ~ NA
    ),
    
    # --- Peso amostral ---
    peso = V1028,
    
    # --- Sociodemográficas com labels ---
    sexo = factor(V2007,
                  levels = c("1", "2"),
                  labels = c("Homem", "Mulher")
    ),
    
    raca = factor(V2010,
                  levels = c("1","2","3","4","5"),
                  labels = c("Branca","Preta","Amarela","Parda","Indígena")
    ),
    

    
    idade = as.integer(V2009),
    
    # --- Escolaridade agregada (4 grupos) ---
    escolaridade = factor(
      dplyr::case_when(
        VD3005 %in% c("01","02","03","04") ~ 1L,
        VD3005 %in% c("05","06","07")      ~ 2L,
        VD3005 %in% c("08","09")           ~ 3L,
        VD3005 %in% c("10","11","12","13","14","15","16") ~ 4L,
        TRUE ~ NA_integer_
      ),
      levels = 1:4,
      labels = c(
        "Até fund. incompleto",
        "Fund. completo / médio inc.",
        "Médio completo / sup. inc.",
        "Superior completo"
      )
    ),
    
    # --- Condição na força de trabalho ---
    pit            = idade >= 14,
    forca_trabalho = !is.na(VD4001) & VD4001 == 1,
    ocupado        = !is.na(VD4002) & VD4002 == 1,
    desocupado     = !is.na(VD4002) & VD4002 == 2 & forca_trabalho,
    fora_forca     = !is.na(VD4001) & VD4001 == 2,
    
    # --- Rendimento e horas (somente ocupados) ---
    rendimento      = dplyr::if_else(ocupado & VD4020 > 0, VD4020, NA_real_),
    horas_semana    = dplyr::if_else(ocupado & VD4031 > 0, as.numeric(VD4031), NA_real_),
    rendimento_hora = dplyr::if_else(
      !is.na(rendimento) & !is.na(horas_semana),
      rendimento / (horas_semana * 4.345),
      NA_real_
    ),
    
    # --- Macrorregião ---
    regiao = dplyr::case_when(
      uf %in% c("11","12","13","14","15","16","17") ~ "Norte",
      uf %in% c("21","22","23","24","25","26","27","28","29") ~ "Nordeste",
      uf %in% c("31","32","33","35") ~ "Sudeste",
      uf %in% c("41","42","43") ~ "Sul",
      uf %in% c("50","51","52","53") ~ "Centro-Oeste",
      TRUE ~ NA_character_
    )
  ) |>
  # Mantém apenas a PIT (14+)
  dplyr::filter(pit) |>
  # Seleciona apenas colunas derivadas
  dplyr::select(
    trimestre, ano, tri, tri_data,
    uf, regiao, urbano, peso,
    sexo, raca, idade, escolaridade,
    pit, forca_trabalho, ocupado, desocupado, fora_forca,
    rendimento, horas_semana, rendimento_hora
  )

saveRDS(pnad_reduzida, file.path(PATH$processed, "pnad_reduzida.rds"))

message(glue::glue(
  "  >> pnad_reduzida.rds salvo: ",
  "{format(nrow(pnad_reduzida), big.mark='.')} observações | ",
  "{dplyr::n_distinct(pnad_reduzida$trimestre)} trimestre(s)"
))
message("=== Processamento concluído ===")
