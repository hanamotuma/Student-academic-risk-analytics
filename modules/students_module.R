# modules/students_module.R
studentsUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 12, title = "Student Records",
          DTOutput(ns("student_table")))
    ),
    fluidRow(
      box(width = 12, title = "Search & Filter",
          textInput(ns("search"), "Search by name or subject"),
          selectInput(ns("subject_filter"), "Filter by Subject",
                      choices = c("All", "Math", "Science", "English")))
    )
  )
}

studentsServer <- function(input, output, session, df) {
  filtered <- reactive({
    d <- df
    if (!is.null(input$search) && input$search != "") {
      d <- d %>% filter(grepl(input$search, name, ignore.case = TRUE) |
                          grepl(input$search, subject, ignore.case = TRUE))
    }
    if (!is.null(input$subject_filter) && input$subject_filter != "All") {
      d <- d %>% filter(subject == input$subject_filter)
    }
    d
  })
  output$student_table <- renderDT({
    datatable(filtered(), options = list(pageLength = 10))
  })
}