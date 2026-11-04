# modules/risk_module.R
riskUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 6, title = "Risk Distribution", plotOutput(ns("risk_plot"))),
      box(width = 6, title = "High Risk Students", DTOutput(ns("high_risk_table")))
    ),
    fluidRow(
      box(width = 12, title = "Intervention Required",
          DTOutput(ns("intervention_table")))
    )
  )
}

riskServer <- function(input, output, session, df) {
  output$risk_plot <- renderPlot({
    r <- risk_distribution(df)
    ggplot(r, aes(x = risk_level, y = n, fill = risk_level)) +
      geom_col() + theme_minimal() +
      scale_fill_manual(values = c("High" = "#e74c3c", "Moderate" = "#f39c12", "Low" = "#2ecc71"))
  })
  output$high_risk_table <- renderDT({
    datatable(high_risk_students(df))
  })
  output$intervention_table <- renderDT({
    datatable(df %>% filter(risk_level != "Low"))
  })
}