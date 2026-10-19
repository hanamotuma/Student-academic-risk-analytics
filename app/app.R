# ==============================================================================
# EDUCATION PERFORMANCE ANALYTICS (Clean & Modular)
# ==============================================================================

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(DT)
library(reticulate)
library(shinyjs)

# --- 1. LOAD EXTERNAL PYTHON ---
use_python(Sys.which("python"), required = TRUE)
source_python("ml_engine.py") # Loads train_risk_model() from Python

# --- 2. DATA GENERATION ---
set.seed(42)
default_data <- data.frame(
  student_id    = sprintf("STU-%03d", 1:100),
  quiz_score    = round(runif(100, 40, 100), 1),
  midterm_score = round(runif(100, 35, 100), 1),
  final_score   = round(runif(100, 30, 100), 1),
  attendance    = round(runif(100, 50, 100), 1),
  grade         = sample(c("A", "B", "C", "D", "F"), 100, replace = TRUE, prob = c(0.2, 0.3, 0.3, 0.1, 0.1)),
  subject       = sample(c("Math", "Science", "English"), 100, replace = TRUE)
)

# --- 3. THE UI ---
ui <- fluidPage(
  useShinyjs(),
  theme = bs_theme(version = 5, bg = "#f8fafc", fg = "#0f172a", base_font = font_google("Inter")),
  
  tags$head(
    # Load external JS
    tags$script(src = "script.js"),
    
    # CSS remains here since it's specific to this app
    tags$style(HTML("
      body { overflow-x: hidden; background-color: #f8fafc; }
      .row { margin: 0; }
      .custom-sidebar { background-color: #1a1f2e; color: white; height: 100vh; padding: 30px 20px; position: fixed; width: 260px; top: 0; left: 0; z-index: 1000; }
      .sidebar-logo { font-size: 1.5rem; font-weight: 800; color: white; margin-bottom: 50px; display: flex; align-items: center; gap: 10px;}
      .sidebar-menu-item { color: #94a3b8; font-size: 1rem; padding: 12px 15px; border-radius: 8px; margin-bottom: 10px; cursor: pointer; transition: 0.2s; display: flex; align-items: center; gap: 10px; }
      .sidebar-menu-item:hover { background-color: #2a3245; color: white; }
      .sidebar-menu-item.active { background-color: #2a3245; color: white; font-weight: 600; border-left: 4px solid #3b82f6; }
      .main-content { margin-left: 260px; padding: 30px 40px; }
      .top-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
      .page-title { font-size: 1.8rem; font-weight: 800; margin: 0; color: #1e293b; }
      .page-subtitle { color: #64748b; font-size: 0.9rem; margin-top: 5px; }
      .filter-group { display: flex; gap: 15px; align-items: center; }
      .ui-card { background: white; border-radius: 16px; padding: 24px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02); border: 1px solid #f1f5f9; margin-bottom: 24px; height: calc(100% - 24px); }
      .kpi-title { font-size: 0.85rem; color: #64748b; font-weight: 600; margin-bottom: 10px;}
      .kpi-value { font-size: 2rem; font-weight: 800; color: #0f172a; line-height: 1;}
      table.dataTable thead th { border-bottom: none !important; color: #64748b; font-weight: 600; }
      table.dataTable tbody tr { border-bottom: 1px solid #f1f5f9; }
    "))
  ),
  
  # --- SIDEBAR ---
  div(class = "custom-sidebar",
      div(class = "sidebar-logo", icon("chart-line"), "EduAnalytics"),
      actionLink("nav_summary", div(class = "sidebar-menu-item active", id = "menu_summary", icon("home"), " Summary")),
      actionLink("nav_insights", div(class = "sidebar-menu-item", id = "menu_insights", icon("chart-pie"), " Insights")),
      actionLink("nav_students", div(class = "sidebar-menu-item", id = "menu_students", icon("users"), " Students"))
  ),
  
  # --- MAIN CONTENT ---
  div(class = "main-content",
      div(class = "top-header",
          div(
            h1(textOutput("current_page_title"), class = "page-title"),
            p("Academic Performance | High-Impact Student Analytics", class = "page-subtitle")
          ),
          div(class = "filter-group",
              selectInput("file1", NULL, choices = c("Default Data"), width = "200px"),
              actionButton("update_btn", "Apply Filters", class = "btn btn-dark", style = "border-radius: 8px; font-weight: 600; height: 42px;")
          )
      ),
      
      # PAGE 1
      div(id = "page_summary",
          fluidRow(
            column(3, div(class = "ui-card", div(class = "kpi-title", "Average Score"), div(class = "kpi-value", textOutput("avg_score")))),
            column(3, div(class = "ui-card", div(class = "kpi-title", "Total Students"), div(class = "kpi-value", textOutput("total_students")))),
            column(3, div(class = "ui-card", div(class = "kpi-title", "Pass Rate"), div(class = "kpi-value", textOutput("pass_rate")))),
            column(3, div(class = "ui-card", div(class = "kpi-title", "High Risk Prob."), div(class = "kpi-value", textOutput("ai_risk_prob"), style = "color: #ef4444;")))
          ),
          fluidRow(
            column(4, div(class = "ui-card", h4("Grade Distribution", style="font-weight:700; font-size:1rem; margin-bottom:20px;"), plotOutput("grade_plot", height = "250px"))),
            column(8, div(class = "ui-card", h4("Performance Trend", style="font-weight:700; font-size:1rem; margin-bottom:20px;"), plotOutput("trend_plot", height = "250px")))
          )
      ),
      
      # PAGE 2
      hidden(div(id = "page_insights", fluidRow(column(12, div(class = "ui-card", h4("Risk Profile Breakdown", style="font-weight:700; font-size:1rem; margin-bottom:20px;"), plotOutput("scatter_plot", height = "400px")))))),
      
      # PAGE 3
      hidden(div(id = "page_students", fluidRow(column(12, div(class = "ui-card", h4("Student Directory", style="font-weight:700; font-size:1rem; margin-bottom:20px;"), DTOutput("full_student_table"))))))
  )
)

# --- 4. SERVER LOGIC ---
server <- function(input, output, session) {
  
  # Navigation
  output$current_page_title <- renderText({
    if (input$nav_summary > 0) "Education Performance Analysis"
    else if (input$nav_insights > 0) "Deep Dive Insights"
    else if (input$nav_students > 0) "Student Directory"
    else "Education Performance Analysis"
  })
  
  observeEvent(input$nav_summary, { show("page_summary"); hide("page_insights"); hide("page_students"); addClass("menu_summary", "active"); removeClass("menu_insights", "active"); removeClass("menu_students", "active") })
  observeEvent(input$nav_insights, { hide("page_summary"); show("page_insights"); hide("page_students"); removeClass("menu_summary", "active"); addClass("menu_insights", "active"); removeClass("menu_students", "active") })
  observeEvent(input$nav_students, { hide("page_summary"); hide("page_insights"); show("page_students"); removeClass("menu_summary", "active"); removeClass("menu_insights", "active"); addClass("menu_students", "active") })
  
  # Data Processing (Notice the Python call is now clean)
  processed_data <- reactive({
    df <- default_data 
    py_df <- r_to_py(df)
    
    # Call external Python function directly!
    probs <- train_risk_model(py_df) 
    
    df$ai_risk_prob <- as.numeric(probs)
    df$overall_score <- (df$quiz_score * 0.2) + (df$midterm_score * 0.3) + (df$final_score * 0.5)
    df$risk_level <- ifelse(df$ai_risk_prob > 0.6, "High Risk", ifelse(df$ai_risk_prob > 0.3, "Moderate Risk", "Low Risk"))
    df
  })
  
  filtered_data <- eventReactive(input$update_btn, { processed_data() }, ignoreNULL = FALSE)
  
  # Outputs
  output$total_students <- renderText({ nrow(filtered_data()) })
  output$avg_score <- renderText({ paste0(round(mean(filtered_data()$overall_score), 2), "%") })
  output$pass_rate <- renderText({ paste0(round((sum(filtered_data()$overall_score >= 60) / nrow(filtered_data())) * 100, 1), "%") })
  output$ai_risk_prob <- renderText({ paste0(round(mean(filtered_data()$ai_risk_prob) * 100, 1), "%") })
  
  output$grade_plot <- renderPlot({
    grade_counts <- filtered_data() %>% mutate(calc_grade = case_when(overall_score >= 90 ~ "A", overall_score >= 80 ~ "B", overall_score >= 70 ~ "C", overall_score >= 60 ~ "D", TRUE ~ "F")) %>% count(calc_grade)
    ggplot(grade_counts, aes(x = 2, y = n, fill = calc_grade)) + geom_bar(stat = "identity", width = 1, color = "white") + coord_polar("y", start = 0) + xlim(0.5, 2.5) + scale_fill_manual(values = c("A" = "#10b981", "B" = "#3b82f6", "C" = "#f59e0b", "D" = "#f97316", "F" = "#ef4444")) + theme_void() + theme(legend.position = "right", legend.title = element_blank())
  }, bg = "transparent")
  
  output$trend_plot <- renderPlot({
    trend_data <- data.frame(Term = c("Term 1", "Term 2", "Term 3", "Term 4"), Score = c(mean(filtered_data()$overall_score) - 5, mean(filtered_data()$overall_score) - 2, mean(filtered_data()$overall_score) + 1, mean(filtered_data()$overall_score)))
    ggplot(trend_data, aes(x = Term, y = Score)) + geom_col(fill = "#1e293b", width = 0.4) + geom_text(aes(label = round(Score, 1)), vjust = -0.5, fontface = "bold", color = "#1e293b") + scale_y_continuous(limits = c(0, 100)) + theme_minimal() + theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(), axis.title = element_blank())
  }, bg = "transparent")
  
  output$scatter_plot <- renderPlot({
    ggplot(filtered_data(), aes(x = attendance, y = overall_score, color = risk_level)) + geom_point(size = 4, alpha = 0.8) + scale_color_manual(values = c("Low Risk" = "#10b981", "Moderate Risk" = "#f59e0b", "High Risk" = "#ef4444")) + labs(x = "Attendance Rate (%)", y = "Overall Weighted Score (%)", color = "Risk Level") + theme_minimal(base_size = 14) + theme(legend.position = "bottom", panel.grid.minor = element_blank())
  }, bg = "transparent")
  
  output$full_student_table <- renderDT({
    datatable(filtered_data() %>% select(student_id, overall_score, attendance, risk_level, ai_risk_prob), rownames = FALSE, options = list(pageLength = 10)) %>% formatPercentage("ai_risk_prob", 1) %>% formatRound("overall_score", 1)
  })
}

shinyApp(ui, server)