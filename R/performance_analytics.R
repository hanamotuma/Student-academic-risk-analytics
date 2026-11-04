# performance_analysis.R
library(dplyr)

get_subject_summary <- function(df) {
  df %>%
    group_by(subject) %>%
    summarise(
      avg_quiz = mean(quiz, na.rm = TRUE),
      avg_midterm = mean(midterm, na.rm = TRUE),
      avg_final = mean(final, na.rm = TRUE),
      avg_score = mean(avg_score, na.rm = TRUE),
      .groups = "drop"
    )
}

get_performance_trend <- function(df) {
  df %>%
    group_by(subject) %>%
    summarise(avg_score = mean(avg_score, na.rm = TRUE), .groups = "drop")
}

attendance_vs_performance <- function(df) {
  df %>% select(attendance, avg_score)
}