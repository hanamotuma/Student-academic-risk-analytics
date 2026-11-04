# app.R - Modern Dashboard
library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(readxl)
library(rmarkdown)

# --- 1. Core Data Processing Logic ---
process_data <- function(df) {
  # If data is loaded from Excel/CSV, ensure column names match
  # Weighted Score
  df$overall_score <- (df$quiz_score * 0.20) + 
                      (df$midterm_score * 0.30) + 
                      (df$final_score * 0.50)
  
  # Risk Level
  df$risk_level <- ifelse(
    df$overall_score < 60 | df$attendance < 70, "High Risk",
    ifelse(df$overall_score < 75, "Moderate Risk", "Low Risk")
  )
  
  # Action Required
  df$Action_Required <- dplyr::case_when(
    df$risk_level == "High Risk" & df$attendance < 60 ~ "URGENT: Parent Meeting & Attendance Contract",
    df$risk_level == "High Risk" & df$overall_score < 60 ~ "URGENT: Academic Tutoring Required",
    df$risk_level == "High Risk" ~ "High Priority: Counselor Review",
    df$risk_level == "Moderate Risk" & df$attendance < 70 ~ "Monitoring: Attendance Warning",
    df$risk_level == "Moderate Risk" ~ "Monitoring: Extra Assignments",
    TRUE ~ "No Action Needed"
  )
  
  df
}

# --- 2. UI Definition (Matching your screenshot) ---
ui <- page_sidebar(
  theme = bs_theme(bootswatch = "flatly", base_font = font_google("Inter")),
  title = "Lunor Analytics",
  
  # Sidebar
  sidebar = sidebar(
    width = 250,
    # Add a logo or title here
    h4("Menu", class = "text-muted"),
    navset_pill_list(
      nav_panel("Dashboard", icon = icon("chart-line")),
      nav_panel("Reports", icon = icon("file-alt")),
      nav_panel("Data Upload", icon = icon("upload"))
    ),
    hr(),
    actionButton("btn_upgrade", "Upgrade to Premium", class = "btn-dark w-100")
  ),
  
  # Main Content
  navset_hidden(
    nav_panel_hidden(
      "Dashboard",
      # Welcome Header
      div(class = "d-flex justify-content-between align-items-center mb-4",
          h2("Welcome back, John Doe!"),
          actionButton("btn_export", "Export Data", icon = icon("download"), class = "btn-outline-secondary")
      ),
      
      # KPI Cards (Dynamic)
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        card(
          card_header("Total Students", class = "bg-light"),
          h2(textOutput("kpi_total")),
          p("Active in system", class = "text-muted")
        ),
        card(
          card_header("High Risk", class = "bg-light"),
          h2(textOutput("kpi_high"), class = "text-danger"),
          p("Require immediate action", class = "text-muted")
        ),
        card(
          card_header("Average Score", class = "bg-light"),
          h2(textOutput("kpi_avg_score")),
          p("Weighted overall", class = "text-muted")
        ),
        card(
          card_header("Avg Attendance", class = "bg-light"),
          h2(textOutput("kpi_avg_attendance")),
          p("Class average", class = "text-muted")
        )
      ),
      
      # Charts and Tables Row
      layout_columns(
        col_widths = c(7, 5),
        card(
          card_header("Performance vs. Attendance"),
          plotOutput("scatter_plot", height = "300px")
        ),
        card(
          card_header("Recent Interventions"),
          tableOutput("intervention_table")
        )
      )
    ),
    
    nav_panel_hidden(
      "Reports",
      card(
        card_header("Generate PDF Report"),
        p("Click below to generate the dynamic PDF report based on current data."),
        downloadButton("download_pdf", "Download PDF Report", class = "btn-primary")
      )
    ),
    
    nav_panel_hidden(
      "Data Upload",
      card(
        card_header("Upload Dataset"),
        fileInput("file_upload", "Upload CSV or Excel", accept = c(".csv", ".xlsx")),
        p("If no file is uploaded, the default simulated dataset will be used.")
      )
    )
  )
)

# --- 3. Server Logic ---
server <- function(input, output, session) {
  
  # Reactive Data Source
  current_data <- reactive({
    if (is.null(input$file_upload)) {
      # Fallback to simulated data if nothing is uploaded
      set.seed(42)
      n <- 50
      df <- data.frame(
        student_id = sprintf("STU-%03d", 1:n),
        quiz_score = round(runif(n, 40, 100), 1),
        midterm_score = round(runif(n, 35, 100), 1),
        final_score = round(runif(n, 30, 100), 1),
        math = round(runif(n, 30, 100), 1),
        science = round(runif(n, 30, 100), 1),
        english = round(runif(n, 30, 100), 1),
        attendance = round(runif(n, 50, 100), 1)
      )
      process_data(df)
    } else {
      # Load uploaded data
      ext <- tools::file_ext(input$file_upload$name)
      df <- if (ext == "csv") {
        read.csv(input$file_upload$datapath)
      } else {
        readxl::read_excel(input$file_upload$datapath)
      }
      process_data(df)
    }
  })
  
  # KPI Outputs
  output$kpi_total <- renderText({ nrow(current_data()) })
  output$kpi_high <- renderText({ 
    sum(current_data()$risk_level == "High Risk") 
  })
  output$kpi_avg_score <- renderText({ 
    paste0(round(mean(current_data()$overall_score), 1), "%") 
  })
  output$kpi_avg_attendance <- renderText({ 
    paste0(round(mean(current_data()$attendance), 1), "%") 
  })
  
  # Scatter Plot
  output$scatter_plot <- renderPlot({
    ggplot(current_data(), aes(x = attendance, y = overall_score, color = risk_level)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_hline(yintercept = 60, linetype = "dashed", color = "red") +
      geom_vline(xintercept = 70, linetype = "dashed", color = "orange") +
      scale_color_manual(values = c("Low Risk" = "#2ecc71", 
                                    "Moderate Risk" = "#f39c12", 
                                    "High Risk" = "#e74c3c")) +
      theme_minimal() +
      labs(x = "Attendance (%)", y = "Overall Score (%)", color = "Risk Profile")
  })
  
  # Intervention Table
  output$intervention_table <- renderTable({
    current_data() %>%
      filter(risk_level == "High Risk") %>%
      arrange(desc(overall_score)) %>%
      select(student_id, overall_score, Action_Required) %>%
      head(5)
  })
  
  # PDF Download Handler
  output$download_pdf <- downloadHandler(
    filename = function() { paste0("Student_Report_", Sys.Date(), ".pdf") },
    content = function(file) {
      # Ensure the old file is deleted to prevent the file lock error!
      if (file.exists("report_template.pdf")) file.remove("report_template.pdf")
      
      rmarkdown::render(
        "report_template.Rmd",
        params = list(data = current_data()),
        output_file = file,
        envir = new.env()
      )
    }
  )
}

shinyApp(ui, server)