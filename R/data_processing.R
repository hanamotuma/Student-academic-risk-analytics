# data_processing.R
library(readr)
library(dplyr)

load_student_data <- function(path = "data/sample/students.csv") {
  df <- read_csv(path, show_col_types = FALSE)
  df <- df %>%
    mutate(
      avg_score = round((quiz + midterm + final) / 3, 1),
      attendance = as.numeric(attendance)
    )
  return(df)
}