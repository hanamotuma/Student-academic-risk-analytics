# ==============================================================================
# Student Academic Performance & Risk Analytics System
# Description: Ingests student performance indicators, calculates weighted averages,
#              evaluates attendance thresholds, and assigns risk levels.
# ==============================================================================

# 1. Load Required Libraries
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("tidyr")) install.packages("tidyr")
if (!require("writexl")) install.packages("writexl")

library(ggplot2)
library(dplyr)
library(tidyr)
library(writexl)

# 2. Simulate Student Dataset (Including Subject-Specific Scores)
set.seed(42) # Ensure reproducible data generation

n_students <- 50
student_ids <- sprintf("STU-%03d", 1:n_students)

students_df <- data.frame(
  student_id    = student_ids,
  quiz_score    = round(runif(n_students, min = 40, max = 100), 1),
  midterm_score = round(runif(n_students, min = 35, max = 100), 1),
  final_score   = round(runif(n_students, min = 30, max = 100), 1),
  math          = round(runif(n_students, min = 30, max = 100), 1),
  science       = round(runif(n_students, min = 30, max = 100), 1),
  english       = round(runif(n_students, min = 30, max = 100), 1),
  attendance    = round(runif(n_students, min = 50, max = 100), 1)
)

# 3. Core Analytics Engine: Calculate Weighted Performance
# Weights: Quizzes 20%, Midterm 30%, Final Exam 50%
students_df$overall_score <- (students_df$quiz_score * 0.20) +
  (students_df$midterm_score * 0.30) +
  (students_df$final_score * 0.50)

# 4. Risk Assessment Logic: Categorize Academic Risk
# High Risk: Overall Score < 60 OR Attendance < 70%
# Moderate Risk: Overall Score between 60 and 75
# Low Risk: Overall Score >= 75 AND Attendance >= 70%

students_df$risk_level <- ifelse(
  students_df$overall_score < 60 | students_df$attendance < 70, "High Risk",
  ifelse(students_df$overall_score < 75, "Moderate Risk", "Low Risk")
)

students_df$risk_level <- factor(students_df$risk_level, 
                                 levels = c("Low Risk", "Moderate Risk", "High Risk"))

# 5. Summary Insights & Reporting
cat("====================================================\n")
cat("      STUDENT RISK ANALYTICS SUMMARY REPORT         \n")
cat("====================================================\n\n")

cat("Total Students Analyzed:", nrow(students_df), "\n")
cat("Class Average Score:     ", round(mean(students_df$overall_score), 2), "%\n")
cat("Average Attendance:      ", round(mean(students_df$attendance), 2), "%\n\n")

cat("Risk Level Distribution:\n")
print(table(students_df$risk_level))

cat("\n--- High Risk Students Requiring Immediate Intervention ---\n")
high_risk_list <- subset(students_df, risk_level == "High Risk", 
                         select = c(student_id, overall_score, attendance))
print(head(high_risk_list, 10))

# 6. Visualization: Academic Performance vs. Attendance by Risk Profile
p <- ggplot(students_df, aes(x = attendance, y = overall_score, color = risk_level)) +
  geom_point(size = 3.5, alpha = 0.8) +
  geom_hline(yintercept = 60, linetype = "dashed", color = "red", alpha = 0.6) +
  geom_vline(xintercept = 70, linetype = "dashed", color = "orange", alpha = 0.6) +
  scale_color_manual(values = c("Low Risk" = "#2ecc71", 
                                "Moderate Risk" = "#f39c12", 
                                "High Risk" = "#e74c3c")) +
  labs(
    title = "Student Academic Performance & Risk Profiling",
    subtitle = "Dashed lines represent minimum passing & attendance thresholds",
    x = "Attendance Rate (%)",
    y = "Overall Weighted Score (%)",
    color = "Risk Category"
  ) +
  theme_minimal()

print(p)

# ==========================================================
# EXPANSION: ADVANCED ANALYTICS & ACTIONABLE INSIGHTS
# ==========================================================

# 1. Create Actionable Interventions
intervention_df <- students_df %>%
  mutate(
    Action_Required = case_when(
      risk_level == "High Risk" & attendance < 60 ~ "🚨 URGENT: Parent Meeting & Attendance Contract",
      risk_level == "High Risk" & overall_score < 60 ~ "⚠️ URGENT: Academic Tutoring Required",
      risk_level == "High Risk" ~ "High Priority: Counselor Review",
      risk_level == "Moderate Risk" & attendance < 70 ~ "Monitoring: Attendance Warning",
      risk_level == "Moderate Risk" ~ "Monitoring: Extra Assignments",
      TRUE ~ "No Action Needed"
    )
  ) %>%
  filter(risk_level != "Low Risk") %>%  
  arrange(desc(overall_score))          

# Print the action list to console
cat("\n--- ACTIONABLE INTERVENTION LIST ---\n")
print(intervention_df %>% select(student_id, risk_level, overall_score, Action_Required))

# Export to Excel
write_xlsx(intervention_df, "intervention_list.xlsx")
cat("\n✅ Exported Intervention List to 'intervention_list.xlsx'\n")

# 2. Subject-wise Performance by Risk Level
subject_summary <- students_df %>%
  group_by(risk_level) %>%
  summarise(
    Count = n(),
    Avg_Math = mean(math, na.rm = TRUE),
    Avg_Science = mean(science, na.rm = TRUE),
    Avg_English = mean(english, na.rm = TRUE),
    Avg_Attendance = mean(attendance, na.rm = TRUE)
  )

print(subject_summary)

# 3. Visualizing the Breakdown (Boxplot)
long_data <- students_df %>%
  select(student_id, risk_level, math, science, english) %>%
  pivot_longer(cols = c(math, science, english), 
               names_to = "Subject", 
               values_to = "Score")

p_box <- ggplot(long_data, aes(x = risk_level, y = Score, fill = risk_level)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~ Subject) + 
  scale_fill_manual(values = c("Low Risk" = "#2ecc71", 
                               "Moderate Risk" = "#f39c12", 
                               "High Risk" = "#e74c3c")) +
  labs(
    title = "Subject Score Distribution by Risk Level",
    subtitle = "Are high-risk students failing across all subjects?",
    x = "Risk Category",
    y = "Subject Score (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none") 

print(p_box)

# Save the plot to a file
ggsave("subject_risk_boxplot.png", width = 8, height = 5, dpi = 300)
cat("\n✅ Saved subject breakdown chart to 'subject_risk_boxplot.png'\n")

