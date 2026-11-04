# Architecture

## Modules
- `overview_module.R`: KPI cards, distribution chart
- `students_module.R`: Table, search, profile
- `performance_module.R`: Subject comparisons, trends
- `risk_module.R`: Risk distribution, intervention list
- `reports_module.R`: Export buttons

## Data Flow
`data/sample/students.csv` → `data_processing.R` → `performance_analysis.R` → `risk_classification.R` → modules → `app.R`