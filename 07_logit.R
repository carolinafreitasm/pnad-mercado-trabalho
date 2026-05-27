# =============================================================================
# 07_logit.R
# Modelo logit: determinantes da participação na força de trabalho
# Versão otimizada — sem marginaleffects, sem profile likelihood
#
# NOTA METODOLÓGICA:
# Estimação via glm() com pesos normalizados (V1028 / mean(V1028)).
# ICs de Wald. Efeitos marginais calculados manualmente na média da amostra.
# Erros padrão não corrigidos para desenho amostral complexo da PNAD.
# =============================================================================

source(here::here("00_config.R"))
library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(gt)
library(scales)
library(broom)

message("=== Estimando modelo logit ===")

# =============================================================================
# 1. Base de estimação
# =============================================================================

pnad <- readRDS(file.path(PATH$processed, "pnad_reduzida.rds"))

base_logit <- pnad |>
  dplyr::filter(
    idade >= 18,
    !is.na(sexo),
    !is.na(raca),
    !is.na(escolaridade),
    !is.na(urbano),
    !is.na(regiao),
    !is.na(peso)
  ) |>
  dplyr::mutate(
    y          = as.integer(forca_trabalho),
    idade2     = idade^2,
    peso_norm  = peso / mean(peso),
    trimestre  = relevel(factor(trimestre),    ref = "1T2025"),
    sexo       = relevel(sexo,                 ref = "Homem"),
    raca       = relevel(raca,                 ref = "Branca"),
    escolaridade = relevel(escolaridade,       ref = "Até fund. incompleto"),
    regiao     = relevel(factor(regiao),       ref = "Norte")
  )

message(glue::glue(
  "  >> {format(nrow(base_logit), big.mark='.')} observações na base"
))

# =============================================================================
# 2. Estimação
# =============================================================================

message("  >> estimando...")

modelo <- glm(
  y ~ sexo + raca + escolaridade + idade + idade2 +
    urbano + regiao + trimestre,
  data    = base_logit,
  weights = peso_norm,
  family  = binomial(link = "logit"),
  control = glm.control(maxit = 200, epsilon = 1e-10)
)

message(glue::glue("  >> convergido: {modelo$converged}"))

# Pseudo-R² McFadden — modelo nulo sem reestimar toda a base
ll_modelo <- as.numeric(logLik(modelo))
ll_nulo   <- as.numeric(logLik(
  glm(y ~ 1, data = base_logit, weights = peso_norm,
      family = binomial(link = "logit"))
))
pseudo_r2 <- 1 - (ll_modelo / ll_nulo)

message(glue::glue("  >> Pseudo-R² McFadden: {round(pseudo_r2, 4)}"))

# =============================================================================
# 3. Tabela de coeficientes — OR com IC Wald
# =============================================================================

message("  >> gerando tabela de coeficientes...")

LABELS_TERMO <- c(
  "sexoMulher"                              = "Mulher",
  "racaPreta"                               = "Preta",
  "racaAmarela"                             = "Amarela",
  "racaParda"                               = "Parda",
  "racaIndígena"                            = "Indígena",
  "escolaridadeFund. completo / médio inc." = "Fund. completo / médio inc.",
  "escolaridadeMédio completo / sup. inc."  = "Médio completo / sup. inc.",
  "escolaridadeSuperior completo"           = "Superior completo",
  "idade"                                   = "Idade",
  "idade2"                                  = "Idade²",
  "urbanoTRUE"                              = "Área urbana",
  "regiaoNordeste"                          = "Nordeste",
  "regiaoCentro-Oeste"                      = "Centro-Oeste",
  "regiaoSudeste"                           = "Sudeste",
  "regiaoSul"                               = "Sul",
  "trimestre2T2025"                         = "2T2025",
  "trimestre3T2025"                         = "3T2025",
  "trimestre4T2025"                         = "4T2025",
  "trimestre1T2026"                         = "1T2026"
)

GRUPOS_TERMO <- c(
  "sexoMulher"      = "Sexo",
  "racaPreta"       = "Raça/cor",
  "racaAmarela"     = "Raça/cor",
  "racaParda"       = "Raça/cor",
  "racaIndígena"    = "Raça/cor",
  "escolaridadeFund. completo / médio inc." = "Escolaridade",
  "escolaridadeMédio completo / sup. inc."  = "Escolaridade",
  "escolaridadeSuperior completo"           = "Escolaridade",
  "idade"           = "Idade",
  "idade2"          = "Idade",
  "urbanoTRUE"      = "Localização",
  "regiaoNordeste"  = "Região",
  "regiaoCentro-Oeste" = "Região",
  "regiaoSudeste"   = "Região",
  "regiaoSul"       = "Região",
  "trimestre2T2025" = "Trimestre",
  "trimestre3T2025" = "Trimestre",
  "trimestre4T2025" = "Trimestre",
  "trimestre1T2026" = "Trimestre"
)

coef_df <- broom::tidy(modelo, conf.int = FALSE, exponentiate = TRUE) |>
  dplyr::filter(term != "(Intercept)") |>
  dplyr::mutate(
    conf.low  = exp(log(estimate) - 1.96 * std.error),
    conf.high = exp(log(estimate) + 1.96 * std.error),
    variavel  = dplyr::coalesce(LABELS_TERMO[term], term),
    grupo     = dplyr::coalesce(GRUPOS_TERMO[term], "Outros"),
    sig = dplyr::case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      p.value < 0.1   ~ ".",
      TRUE            ~ ""
    )
  ) |>
  dplyr::select(grupo, variavel, estimate, conf.low, conf.high, p.value, sig)

tab_coef <- coef_df |>
  gt::gt(groupname_col = "grupo") |>
  gt::tab_header(
    title    = "Modelo logit — participação na força de trabalho",
    subtitle = glue::glue(
      "Odds ratios com IC 95% (Wald) — poolado 2025–2026 | ",
      "Pseudo-R² McFadden: {round(pseudo_r2, 3)}"
    )
  ) |>
  gt::cols_label(
    variavel  = "Covariada",
    estimate  = "OR",
    conf.low  = "IC 2,5%",
    conf.high = "IC 97,5%",
    p.value   = "p-valor",
    sig       = ""
  ) |>
  gt::fmt_number(columns = c(estimate, conf.low, conf.high), decimals = 3) |>
  gt::fmt_number(columns = p.value, decimals = 4) |>
  gt::tab_style(
    style     = gt::cell_text(color = "#2E7D32", weight = "bold"),
    locations = gt::cells_body(columns = estimate, rows = estimate > 1)
  ) |>
  gt::tab_style(
    style     = gt::cell_text(color = "#B03A2E", weight = "bold"),
    locations = gt::cells_body(columns = estimate, rows = estimate < 1)
  ) |>
  gt::tab_style(
    style     = gt::cell_fill(color = "#F7F7F5"),
    locations = gt::cells_row_groups()
  ) |>
  gt::tab_style(
    style     = gt::cell_text(weight = "bold", size = gt::px(12)),
    locations = gt::cells_row_groups()
  ) |>
  gt::cols_align(align = "center", columns = -variavel) |>
  gt::tab_footnote(
    footnote  = "Ref.: Homem | Branca | Até fund. incompleto | Rural | Norte | 1T2025",
    locations = gt::cells_title(groups = "subtitle")
  ) |>
  gt::tab_footnote(
    footnote  = "*** p<0,001 | ** p<0,01 | * p<0,05 | . p<0,1",
    locations = gt::cells_column_labels(columns = sig)
  ) |>
  gt::tab_source_note(source_note = caption_pnad()) |>
  tema_gt()

gt::gtsave(tab_coef,
           file.path(PATH$tables, "tab_06_logit_coeficientes.html"))
gt::gtsave(tab_coef,
           file.path(PATH$tables, "tab_06_logit_coeficientes.png"),
           vwidth = 800, vheight = 900, zoom = 2)
message("  >> tab_06 salva")

# =============================================================================
# 4. Efeitos marginais — calculados manualmente na média da amostra
# Evita recomputar predições para 800k observações
# AME aproximado: dP/dx = beta * P_media * (1 - P_media)
# =============================================================================

message("  >> calculando efeitos marginais...")

p_media <- mean(modelo$fitted.values)
fator_delta <- p_media * (1 - p_media)   # escalar para converter log-odds em p.p.

ame_df <- broom::tidy(modelo, conf.int = FALSE, exponentiate = FALSE) |>
  dplyr::filter(
    term != "(Intercept)",
    !grepl("^trimestre", term),   # trimestre: controle, menos relevante visualmente
    term != "idade2"              # idade² entra junto com idade no gráfico
  ) |>
  dplyr::mutate(
    ame       = estimate   * fator_delta * 100,   # em p.p.
    ame_low   = (estimate - 1.96 * std.error) * fator_delta * 100,
    ame_high  = (estimate + 1.96 * std.error) * fator_delta * 100,
    variavel  = dplyr::coalesce(LABELS_TERMO[term], term),
    grupo     = dplyr::coalesce(GRUPOS_TERMO[term], "Outros"),
    sig       = p.value < 0.05,
    variavel  = forcats::fct_reorder(variavel, ame)
  )

# =============================================================================
# 5. Gráfico de efeitos marginais
# =============================================================================

message("  >> fig logit 01 — efeitos marginais")

dir.create(file.path(PATH$figures, "logit"), showWarnings = FALSE)

ggplot(ame_df, aes(x = ame, y = variavel, color = sig, alpha = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = CORES$cinza3, linewidth = 0.6) +
  geom_linerange(aes(xmin = ame_low, xmax = ame_high), linewidth = 0.7) +
  geom_point(size = 2.8) +
  facet_wrap(~grupo, scales = "free_y", ncol = 2) +
  scale_color_manual(
    values = c("TRUE" = CORES$sudeste, "FALSE" = CORES$cinza3),
    guide  = "none"
  ) +
  scale_alpha_manual(
    values = c("TRUE" = 1, "FALSE" = 0.4),
    guide  = "none"
  ) +
  scale_x_continuous(
    labels = label_number(suffix = " p.p.", accuracy = 0.1),
    expand = expansion(mult = c(0.05, 0.05))
  ) +
  labs(
    title    = "Efeitos marginais — participação na força de trabalho",
    subtitle = "Variação em p.p. na probabilidade de participar | pontos opacos: p < 0,05",
    x        = "Efeito marginal (p.p.)",
    y        = NULL,
    caption  = glue::glue(
      caption_pnad(), "\n",
      "Nota: AME aproximado calculado na média da amostra. ",
      "Erros padrão sem correção para desenho amostral."
    )
  ) +
  tema_pnad(grid_v = TRUE, grid_h = FALSE) +
  theme(
    panel.spacing = unit(1.2, "lines"),
    strip.text    = element_text(face = "bold")
  )

salvar_figura("logit_01_efeitos_marginais",
              largura = 12, altura = 9, subdir = "logit")

# =============================================================================
# 6. Probabilidade predita: escolaridade × sexo
# Grid pequeno: 4 escolaridades × 2 sexos = 8 linhas
# =============================================================================

message("  >> fig logit 02 — prob. predita escolaridade × sexo")

idade_media <- mean(base_logit$idade)

grid_escol <- tidyr::expand_grid(
  sexo         = factor(c("Homem","Mulher"), levels = levels(base_logit$sexo)),
  escolaridade = factor(
    levels(base_logit$escolaridade),
    levels = levels(base_logit$escolaridade)
  )
) |>
  dplyr::mutate(
    raca      = factor("Branca",   levels = levels(base_logit$raca)),
    urbano    = TRUE,
    regiao    = factor("Sudeste",  levels = levels(base_logit$regiao)),
    trimestre = factor("1T2026",   levels = levels(base_logit$trimestre)),
    idade     = idade_media,
    idade2    = idade_media^2
  )

pred_escol <- grid_escol |>
  dplyr::mutate(
    fit    = predict(modelo, newdata = grid_escol, type = "response"),
    se_fit = predict(modelo, newdata = grid_escol, type = "link", se.fit = TRUE)$se.fit,
    # IC no espaço do link, depois transforma
    lwr    = plogis(qlogis(fit) - 1.96 * se_fit),
    upr    = plogis(qlogis(fit) + 1.96 * se_fit)
  )

ggplot(pred_escol,
       aes(x = escolaridade, y = fit, color = sexo, group = sexo)) +
  geom_ribbon(aes(ymin = lwr, ymax = upr, fill = sexo),
              alpha = 0.12, color = NA) +
  geom_line(linewidth = 1.0) +
  geom_point(aes(fill = sexo), shape = 21, size = 3.2,
             stroke = 1.3, color = "white") +
  geom_text(
    aes(label = paste0(round(fit * 100, 1), "%")),
    vjust = -1.3, size = 3.0,
    family = FONTE_CORPO, color = CORES$subtexto
  ) +
  scale_color_manual(values = PALETA_SEXO, name = NULL) +
  scale_fill_manual(values  = PALETA_SEXO, name = NULL) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0.1))
  ) +
  labs(
    title    = "Probabilidade predita de participação por escolaridade e sexo",
    subtitle = "Demais covariadas fixadas: Branca, urbana, Sudeste, idade média, 1T2026",
    x        = NULL,
    y        = "Probabilidade predita",
    caption  = glue::glue(
      caption_pnad("1T2026"), "\n",
      "Nota: banda representa IC 95%. Covariadas fixadas na referência."
    )
  ) +
  tema_pnad(legenda_pos = "top")

salvar_figura("logit_02_pred_escolaridade_sexo",
              largura = 10, altura = 6, subdir = "logit")

# =============================================================================
# 7. Probabilidade predita: curva de idade × sexo
# Grid pequeno: 62 idades × 2 sexos = 124 linhas
# =============================================================================

message("  >> fig logit 03 — curva de idade × sexo")

idades_seq <- seq(18, 75, by = 1)

grid_idade <- tidyr::expand_grid(
  sexo  = factor(c("Homem","Mulher"), levels = levels(base_logit$sexo)),
  idade = idades_seq
) |>
  dplyr::mutate(
    idade2       = idade^2,
    escolaridade = factor("Médio completo / sup. inc.",
                          levels = levels(base_logit$escolaridade)),
    raca         = factor("Branca",  levels = levels(base_logit$raca)),
    urbano       = TRUE,
    regiao       = factor("Sudeste", levels = levels(base_logit$regiao)),
    trimestre    = factor("1T2026",  levels = levels(base_logit$trimestre))
  )

pred_idade <- grid_idade |>
  dplyr::mutate(
    fit    = predict(modelo, newdata = grid_idade, type = "response"),
    se_fit = predict(modelo, newdata = grid_idade, type = "link", se.fit = TRUE)$se.fit,
    lwr    = plogis(qlogis(fit) - 1.96 * se_fit),
    upr    = plogis(qlogis(fit) + 1.96 * se_fit)
  )

ggplot(pred_idade, aes(x = idade, y = fit, color = sexo, fill = sexo)) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.12, color = NA) +
  geom_line(linewidth = 1.0) +
  scale_color_manual(values = PALETA_SEXO, name = NULL) +
  scale_fill_manual(values  = PALETA_SEXO, name = NULL) +
  scale_x_continuous(
    breaks = seq(20, 75, by = 10),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0.05))
  ) +
  labs(
    title    = "Probabilidade predita de participação por idade e sexo",
    subtitle = "Escolaridade: médio completo — Branca, urbana, Sudeste, 1T2026",
    x        = "Idade (anos)",
    y        = "Probabilidade predita",
    caption  = glue::glue(
      caption_pnad("1T2026"), "\n",
      "Nota: banda representa IC 95%."
    )
  ) +
  tema_pnad(legenda_pos = "top")

salvar_figura("logit_03_pred_idade_sexo",
              largura = 10, altura = 6, subdir = "logit")

# =============================================================================
# 8. Salva resultados
# =============================================================================

saveRDS(
  list(
    modelo    = modelo,
    coef_df   = coef_df,
    ame_df    = ame_df,
    pseudo_r2 = pseudo_r2,
    n_obs     = nobs(modelo)
  ),
  file.path(PATH$processed, "logit_resultados.rds")
)

message("  >> logit_resultados.rds salvo")
message("=== Logit concluído ===")
