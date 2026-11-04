# student_statistics.R
library(dplyr)

total_students <- function(df) nrow(df)

avg_academic_score <- function(df) round(mean(df$avg_score, na.rm = TRUE), 1)

avg_attendance <- function(df) round(mean(df$attendance, na.rm = TRUE), 1)