library(tidyverse)
library(readxl)
library(googlesheets4)
library(openxlsx)

gs4_deauth()

url <- "https://docs.google.com/spreadsheets/d/1I_tFgcBLorH2v1lt7ifdQ66bpiHBtUqxSOt59Thu6a0/edit?usp=sharing"

sheets <- c(
  "data", "ნარატივები", "აქტორები", "თემა", "მოვლენები"
)

# Read the data from the Google Sheets

get_sheet_data <- function(url, sheets) {
  read_sheet(
    url,
    sheet = sheets
  )
}

data <- map(sheets, ~ get_sheet_data(url, .x), .id = "sheet_name")

names(data) <- sheets

# Write to the disk an excel file, with list items as separate sheets

write_to_excel <- function(data, file_name) {
  wb <- createWorkbook()
  
  for (i in seq_along(data)) {
    addWorksheet(wb, names(data)[i])
    writeData(wb, names(data)[i], data[[i]])
  }
  
  saveWorkbook(wb, file_name, overwrite = TRUE)
}


# Save the data to an Excel file

write_to_excel(data, "dashboard_data.xlsx")
