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
  )  -> daily_posts_by_group

init_data |>
  set_names(
    tbl_names
  ) |>
  mutate(
    monitoring_group = case_when(
      PG_name %in% c("ახალი ამბები განსჯისთვის", "Javakhk") ~ "სომხურენოვანი სეგმენტი",
      PG_name %in% c("Aktual.ge", "24News.ge") ~ "აზერბაიჯანულენოვანი სეგმენტი",
      PG_name %in% c("ბიძინა ივანიშვილის მხარდამჭერი ჯგუფი აჭარაში", "აჭარა გვერდი") ~ "აჭარის სეგმენტი",
      T ~ "სხვა"
    )
  ) |> 
  select(
    P_Date, Narat1, Narat2, Narat3, monitoring_group
  ) |> 
  pivot_longer(
    cols = -c(P_Date, monitoring_group),
    names_to = "variable_id",
    values_to = "narrative_id"
  ) |> 
  filter(!is.na(narrative_id)) |> 
  left_join(
    narratives_src |> distinct(narrative_id, .keep_all = T), by = "narrative_id"
  ) |> 
  group_by(
    P_Date, narrative_text, monitoring_group
  ) |>
  count() |> 
  mutate(
    P_Date = as.Date(P_Date),
    id = row_number()
  )-> narratives_all
  
cat(format_csv(narratives_all))
