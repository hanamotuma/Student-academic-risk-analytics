# app.R
library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(DT)

source(here::here("R", "data_processing.R"))
source(here::here("R", "performance_analytics.R"))
source(here::here("R", "student_statistics.R"))
source(here::here("R", "risk-classification.R"))      
source(here::here("modules", "overview_module.R"))
source(here::here("modules", "students_module.R"))
source(here::here("modules", "performance_module.R"))
source(here::here("modules", "risk_module.R"))
source(here::here("modules", "reports_module.R"))

ui <- dashboardPage(
  dashboardHeader(title = "Student Risk Analytics"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "overview", icon = icon("dashboard")),
      menuItem("Students", tabName = "students", icon = icon("users")),
      menuItem("Performance", tabName = "performance", icon = icon("chart-line")),
      menuItem("Risk", tabName = "risk", icon = icon("exclamation-triangle")),
      menuItem("Reports", tabName = "reports", icon = icon("file-export"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css")
    ),
    tabItems(
      tabItem(tabName = "overview", overviewUI("overview")),
      tabItem(tabName = "students", studentsUI("students")),
      tabItem(tabName = "performance", performanceUI("performance")),
      tabItem(tabName = "risk", riskUI("risk")),
      tabItem(tabName = "reports", reportsUI("reports"))
    )
  )
)

server <- function(input, output, session) {
  df <- load_student_data()
  df <- classify_risk(df)
  
  callModule(overviewServer, "overview", df)
  callModule(studentsServer, "students", df)
  callModule(performanceServer, "performance", df)
  callModule(riskServer, "risk", df)
  callModule(reportsServer, "reports", df)
}

shinyApp(ui, server)