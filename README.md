# Student Academic Performance & Risk Analytics System

## Overview
The Student Academic Performance & Risk Analytics System is an R-based analytical application designed to process, evaluate, and visualize student academic metrics. The system integrates assessment scores (quizzes, midterms, and final exams) with attendance records to compute weighted performance metrics. It automatically classifies students into actionable academic risk tiers and provides an interactive web dashboard for real-time data exploration and automated PDF reporting.

## Core System Logic

### 1. Weighted Performance Calculation
The system evaluates student academic standing using a standardized weighted distribution across three assessment categories:
*   Quizzes: 20%
*   Midterm Exam: 30%
*   Final Exam: 50%

### 2. Multi-Criteria Risk Classification
Students are automatically assigned to risk tiers based on a combination of their overall weighted score and attendance percentage:
*   **High Risk:** Overall score < 60 OR Attendance < 70. This tier triggers immediate intervention protocols.
*   **Moderate Risk:** Overall score between 60 and 75.
*   **Low Risk:** Overall score ≥ 75 AND Attendance ≥ 70.

## Key Features

*   **Interactive Web Dashboard (Shiny):** Provides a responsive interface with dynamic filtering of attendance thresholds and risk levels. Includes real-time Key Performance Indicator (KPI) cards displaying filtered student counts, average scores, and high-risk totals.
*   **Data Ingestion:** Supports the upload of custom `.csv` or `.xlsx` datasets, allowing the analytics engine to dynamically recalculate metrics for new cohorts.
*   **Automated PDF Generation (R Markdown):** Enables the one-click generation of a professional, multi-page PDF report. The report reflects the current filtered data state, including executive summaries, risk distribution tables, performance scatter plots, and a prioritized intervention list.
*   **Risk Matrix Visualization:** Utilizes `ggplot2` to render a scatter plot mapping overall performance against attendance, featuring visual decision boundary threshold lines to easily identify at-risk populations.
*   **Static Reporting:** The core analytics script exports actionable intervention lists directly to Excel (`.xlsx`) and saves static high-resolution visualizations for offline use.

## Project Architecture

The project is modularized to separate data processing, UI rendering, and report generation.

```text
student-academic-risk-analytics/
├── .gitignore
├── student-academic-risk-analytics.Rproj
├── main_analytics.R          # Core data processing and static analytics script
├── app.R                     # Interactive Shiny Dashboard (UI and Server logic)
├── report_template.Rmd       # R Markdown template for PDF generation
├── README.md                 # Project documentation
├── data/
│   └── raw/
│       └── students.csv      # Default sample dataset for ingestion
└── outputs/
    ├── intervention_list.xlsx # Exported actionable Excel list
    └── subject_risk_boxplot.png # Exported static visualization
