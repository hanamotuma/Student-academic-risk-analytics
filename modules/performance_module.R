# modules/performance_module.R
performanceUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 6, title = "Subject Comparison", plotOutput(ns("subject_plot"))),
      box(width = 6, title = "Attendance vs Performance", plotOutput(ns("att_plot")))
    ),
    fluidRow(
      box(width = 12, title = "Performance Trend", plotOutput(ns("trend_plot")))
    )
  )
}

performanceServer <- function(input, output, session, df) {
  output$subject_plot <- renderPlot({
    s <- get_subject_summary(df)
    ggplot(s, aes(x = subject, y = avg_score, fill = subject)) +
      geom_col() + theme_minimal() + labs(x = "Subject", y = "Average Score")
  })
  output$att_plot <- renderPlot({
    ggplot(df, aes(x = attendance, y = avg_score)) +
      geom_point(color = "#2c3e50") + geom_smooth(method = "lm", se = FALSE) +
      theme_minimal() + labs(x = "Attendance (%)", y = "Average Score")
  })
  output$trend_plot <- renderPlot({
    t <- get_performance_trend(df)
    ggplot(t, aes(x = subject, y = avg_score, group = 1)) +
      geom_line(color = "#e74c3c") + geom_point() +
      theme_minimal() + labs(x = "Subject", y = "Avg Score")
  })
}