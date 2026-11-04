# risk_classification.R
library(dplyr)

classify_risk <- function(df) {
  df %>%
    mutate(
      risk_level = case_when(
        avg_score < 50 | attendance < 60 ~ "High",
        avg_score < 70 | attendance < 75 ~ "Moderate",
        TRUE ~ "Low"
      )
    )
}

high_risk_students <- function(df) {
  df %>% filter(risk_level == "High")
}

risk_distribution <- function(df) {
  df %>% count(risk_level)
}