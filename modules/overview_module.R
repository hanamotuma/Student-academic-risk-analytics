# modules/overview_module.R
overviewUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      valueBoxOutput(ns("total_students")),
      valueBoxOutput(ns("avg_score")),
      valueBoxOutput(ns("high_risk")),
      valueBoxOutput(ns("avg_attendance"))
    ),
    fluidRow(
      box(title = "Performance Distribution", width = 6, plotOutput(ns("dist_plot"))),
      box(title = "Risk Summary", width = 6, tableOutput(ns("risk_table")))
    )
  )
}

overviewServer <- function(input, output, session, df) {
  output$total_students <- renderValueBox({
    valueBox(total_students(df), "Total Students", icon = icon("users"), color = "blue")
  })
  output$avg_score <- renderValueBox({
    valueBox(avg_academic_score(df), "Average Score", icon = icon("chart-bar"), color = "green")
  })
  output$high_risk <- renderValueBox({
    valueBox(nrow(high_risk_students(df)), "High Risk", icon = icon("exclamation"), color = "red")
  })
  output$avg_attendance <- renderValueBox({
    valueBox(avg_attendance(df), "Avg Attendance", icon = icon("calendar"), color = "yellow")
  })
  output$dist_plot <- renderPlot({
    ggplot(df, aes(x = avg_score)) +
      geom_histogram(bins = 10, fill = "#2c3e50", color = "white") +
      theme_minimal() +
      labs(x = "Average Score", y = "Count")
  })
  output$risk_table <- renderTable({
    risk_distribution(df)
  })
}