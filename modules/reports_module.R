# modules/reports_module.R
reportsUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 12, title = "Reports & Exports",
          downloadButton(ns("download_student"), "Download Student Report"),
          downloadButton(ns("download_risk"), "Download Risk Report"),
          downloadButton(ns("download_subject"), "Download Subject Summary"))
    )
  )
}

reportsServer <- function(input, output, session, df) {
  output$download_student <- downloadHandler(
    filename = function() "student_report.xlsx",
    content = function(file) export_student_report(df, file)
  )
  output$download_risk <- downloadHandler(
    filename = function() "risk_report.xlsx",
    content = function(file) export_risk_report(df, file)
  )
  output$download_subject <- downloadHandler(
    filename = function() "subject_summary.xlsx",
    content = function(file) export_subject_summary(df, file)
  )
}