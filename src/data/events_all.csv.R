library(tidyverse)
library(readxl)

init_data <- read_excel("src/data/dashboard_data.xlsx", sheet = "მოვლენები")

cat(format_csv(init_data))
