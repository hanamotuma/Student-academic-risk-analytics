# ==============================================================================
# STUDENT RISK ANALYTICS - PREMIUM SMART UI
# ==============================================================================

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(tidyr)
library(DT)
library(readxl)
library(shinyWidgets)
library(rmarkdown) # For PDF generation

# --- 1. DEFAULT DATA ---
set.seed(42)
default_data <- data.frame(
  student_id    = sprintf("STU-%03d", 1:100),
  quiz_score    = round(runif(100, min = 40, max = 100), 1),
  midterm_score = round(runif(100, min = 35, max = 100), 1),
  final_score   = round(runif(100, min = 30, max = 100), 1),
  math          = round(runif(100, min = 30, max = 100), 1),
  science       = round(runif(100, min = 30, max = 100), 1),
  english       = round(runif(100, min = 30, max = 100), 1),
  attendance    = round(runif(100, min = 50, max = 100), 1)
)

process_data <- function(df) {
  df %>%
    mutate(
      overall_score = (quiz_score * 0.20) + (midterm_score * 0.30) + (final_score * 0.50),
      risk_level = case_when(
        overall_score < 60 | attendance < 70 ~ "High Risk",
        overall_score < 75 ~ "Moderate Risk",
        TRUE ~ "Low Risk"
      ),
      risk_level = factor(risk_level, levels = c("Low Risk", "Moderate Risk", "High Risk"))
    )
}
default_data <- process_data(default_data)

# --- 2. CUSTOM CSS FOR PREMIUM FEEL ---
custom_css <- "
  /* Smooth transitions for everything */
  * { transition: all 0.3s ease-in-out; }
  
  /* Make buttons look clickable and premium */
  .btn { border-radius: 8px; font-weight: 600; letter-spacing: 0.5px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
  .btn:hover { transform: translateY(-2px); box-shadow: 0 6px 12px rgba(0,0,0,0.15); }
  
  /* Premium Card Styling */
  .card { border-radius: 12px; border: none; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
  .card-header { border-radius: 12px 12px 0 0 !important; font-weight: 600; text-transform: uppercase; font-size: 0.85rem; letter-spacing: 1px; }
  
  /* Value Box Styling */
  .bslib-value-box { border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
  .bslib-value-box .value-box-title { font-weight: 500; font-size: 1rem; opacity: 0.9; }
  .bslib-value-box .value-box-value { font-weight: 800; font-size: 2.5rem; }
  
  /* Sidebar Background */
  .sidebar { background-color: #1e293b !important; color: #f8fafc !important; }
  .sidebar .card { background-color: #334155; color: #f8fafc; border: 1px solid #475569; }
  .sidebar .card-header { background-color: #0f172a; color: #f8fafc; }
  .sidebar label, .sidebar h5, .sidebar .help-block { color: #cbd5e1 !important; }
"

# --- 3. UI DESIGN ---
ui <- page_sidebar(
  theme = bs_theme(
    version = 5, 
    bootswatch = "flatly", 
    primary = "#10b981",  # Emerald Green
    secondary = "#475569", # Slate Gray
    danger = "#ef4444",    # Soft Red
    base_font = font_google("Inter"),
    heading_font = font_google("Poppins")
  ),
  
  tags$head(tags$style(HTML(custom_css))),
  
  title = tags$div(
    style = "display: flex; align-items: center; justify-content: space-between; width: 100%;",
    tags$div(
      tags$i(class = "fa fa-chart-pie", style = "color: #10b981; margin-right: 10px;"),
      "Student Risk Analytics",
      style = "font-weight: 800; font-family: 'Poppins'; color: #0f172a;"
    ),
    # Smart Light/Dark Mode Toggle
    input_dark_mode(id = "dark_mode", mode = "light")
  ),
  
  # Sidebar
  sidebar = sidebar(
    width = 320,
    bg = "#1e293b",
    
    # 1. Upload Card
    card(
      card_header("📁 Data Source", class = "bg-dark text-white"),
      fileInput("file1", NULL, buttonLabel = "Browse Files", placeholder = "No file selected",
                accept = c(".csv", ".xlsx", ".xls")),
      helpText("Default: 100 simulated students.")
    ),
    
    # 2. Filters Card
    card(
      card_header("🎯 Risk Filters", class = "bg-dark text-white"),
      sliderInput("attendance_filter", "Min Attendance (%)", 
                  min = 0, max = 100, value = 50, step = 5),
      prettyCheckboxGroup(
        inputId = "risk_filter",
        label = NULL,
        choices = c("Low Risk", "Moderate Risk", "High Risk"),
        selected = c("Low Risk", "Moderate Risk", "High Risk"),
        status = "success",
        shape = "round",
        animation = "smooth"
      )
    ),
    
    # 3. Action Button (PDF)
    div(
      style = "margin-top: 20px;",
      downloadButton("download_pdf", "📄 Download PDF Report", 
                     class = "btn-success w-100", 
                     style = "padding: 12px; font-size: 1.1rem;")
    )
  ),
  
  # Main Body
  layout_column_wrap(
    width = 1/3,
    value_box(
      title = "STUDENTS FILTERED",
      value = textOutput("total_students"),
      showcase = icon("users"),
      theme = "secondary" # Slate Gray
    ),
    value_box(
      title = "AVERAGE SCORE",
      value = textOutput("avg_score"),
      showcase = icon("graduation-cap"),
      theme = "primary" # Emerald
    ),
    value_box(
      title = "HIGH RISK STUDENTS",
      value = textOutput("high_risk_count"),
      showcase = icon("triangle-exclamation"),
      theme = "danger" # Soft Red
    )
  ),
  
  navset_card_tab(
    nav_panel("📊 Visual Overview", 
              card(
                card_header("Performance vs Attendance Scatter Plot", class = "bg-secondary text-white"),
                plotOutput("scatter_plot", height = "500px")
              )
    ),
    nav_panel("⚠️ Intervention List", 
              card(
                card_header("Actionable Interventions", class = "bg-danger text-white"),
                DTOutput("data_table")
              )
    )
  )
)

# --- 4. SERVER LOGIC ---
server <- function(input, output, session) {
  
  dataset <- reactive({
    if (is.null(input$file1)) { return(default_data) } 
    else {
      ext <- tools::file_ext(input$file1$name)
      df <- switch(ext,
                   csv = read.csv(input$file1$datapath),
                   xlsx = readxl::read_excel(input$file1$datapath),
                   xls = readxl::read_excel(input$file1$datapath),
                   validate("Invalid file type.")
      )
      process_data(df)
    }
  })
  
  filtered_data <- reactive({
    req(dataset())
    dataset() %>%
      filter(attendance >= input$attendance_filter) %>%
      filter(risk_level %in% input$risk_filter)
  })
  
  output$total_students <- renderText({ nrow(filtered_data()) })
  output$avg_score <- renderText({ paste0(round(mean(filtered_data()$overall_score, na.rm = TRUE), 1), "%") })
  output$high_risk_count <- renderText({ sum(filtered_data()$risk_level == "High Risk") })
  
  output$scatter_plot <- renderPlot({
    # Using theme_minimal with customized text colors to match the UI
    ggplot(filtered_data(), aes(x = attendance, y = overall_score, color = risk_level)) +
      geom_point(size = 4, alpha = 0.8) +
      geom_hline(yintercept = 60, linetype = "dashed", color = "#ef4444", alpha = 0.5) +
      geom_vline(xintercept = 70, linetype = "dashed", color = "#f59e0b", alpha = 0.5) +
      scale_color_manual(values = c("Low Risk" = "#10b981", "Moderate Risk" = "#f59e0b", "High Risk" = "#ef4444")) +
      labs(x = "Attendance Rate (%)", y = "Overall Weighted Score (%)", color = "Risk Level") +
      theme_minimal(base_size = 15, base_family = "Inter") +
      theme(
        legend.position = "bottom",
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.grid.major = element_line(color = "#e2e8f0")
      )
  })
  
  output$data_table <- renderDT({
    filtered_data() %>%
      filter(risk_level != "Low Risk") %>%
      mutate(
        Action_Required = case_when(
          risk_level == "High Risk" & attendance < 60 ~ "🚨 URGENT: Parent Meeting",
          risk_level == "High Risk" & overall_score < 60 ~ "⚠️ URGENT: Tutoring Required",
          risk_level == "High Risk" ~ "High Priority: Counselor Review",
          risk_level == "Moderate Risk" & attendance < 70 ~ "Monitoring: Attendance Warning",
          TRUE ~ "Monitoring: Extra Assignments"
        )
      ) %>%
      select(student_id, risk_level, overall_score, attendance, Action_Required) %>%
      arrange(desc(risk_level), overall_score)
  }, 
  options = list(pageLength = 10, dom = 't', scrollX = TRUE),
  class = "display compact stripe hover"
  )
  
  # --- PDF DOWNLOAD LOGIC ---
  output$download_pdf <- downloadHandler(
    filename = function() { 
      paste0("Risk_Report_", Sys.Date(), ".pdf") 
    },
    content = function(file) {
      # 1. Define the template file and output file
      template_path <- "report_template.Rmd"
      
      # 2. Make sure the file exists before trying to render
      req(file.exists(template_path))
      
      # 3. Pass the data to the Rmd file and render it
      # We use a tryCatch block so if it fails, we see the error in the console
      tryCatch({
        rmarkdown::render(
          input = template_path,
          output_file = file,
          params = list(data = filtered_data(), date = Sys.Date()),
          envir = new.env(parent = globalenv())
        )
      }, error = function(e) {
        cat("ERROR GENERATING PDF: ", e$message, "\n")
        stop("PDF generation failed. Check the R console for details.")
      })
    }
  )
}

shinyApp(ui = ui, server = server)