library(tidyverse)
library(readxl)


init_data <- read_excel("src/data/Test file for dashboard.xlsx")


narratives_src <- read_excel("src/data/SIDA FB Codebook_7Feb2025.xlsx", col_names = F, sheet = "ნარატივები") |> 
  set_names(
    c("narrative_id", "narrative_text", "note")
  )

# რელევანტური პოსტების სიხშირე

tbl_names <- names(init_data)

# Remove everything after the first dot
tbl_names <- gsub("\\..*", "", tbl_names)


init_data |>
  set_names(
    tbl_names
  ) |> 
  filter(
    # P_status == "რელევანტურია"
  ) |>
  mutate(
    monitoring_group = case_when(
      PG_name %in% c("ახალი ამბები განსჯისთვის", "Javakhk") ~ "სომხურენოვანი სეგმენტი",
      PG_name %in% c("Aktual.ge", "24News.ge") ~ "აზერბაიჯანულენოვანი სეგმენტი",
      PG_name %in% c("ბიძინა ივანიშვილის მხარდამჭერი ჯგუფი აჭარაში", "აჭარა გვერდი") ~ "აჭარის სეგმენტი",
      T ~ "სხვა"
    )
  ) |>
  group_by(
    P_Date, monitoring_group
  ) |>  count() |> 
  mutate(
    P_Date = as.Date(P_Date),
    id = row_number()
  ) -> daily_posts_by_group
  

cat(format_csv(daily_posts_by_group))
