library(tidyverse)
library(readxl)

init_data <- read_excel("src/data/dashboard_data.xlsx")

actors_src <- read_excel("src/data/dashboard_data.xlsx", sheet = "აქტორები") 

tbl_names <- names(init_data)

tbl_names <- str_replace_all(tbl_names, "\\s+", "_")

# Remove everything after the first dot
tbl_names <- gsub("\\..*", "", tbl_names)

init_data |> 
  set_names(tbl_names) |> 
  mutate(
    monitoring_group = case_when(
      PG_name %in% c("ახალი ამბები განსჯისთვის", "Javakhk") ~ "სომხურენოვანი სეგმენტი",
      PG_name %in% c("Aktual.ge", "24News.ge") ~ "აზერბაიჯანულენოვანი სეგმენტი",
      PG_name %in% c("გაზეთი აჭარა", "ბიძინა ივანიშვილის მხარდამჭერი ჯგუფი აჭარაში") ~ "აჭარის სეგმენტი",
      T ~ "ქართულენოვანი სეგმენტი (აჭარის გარდა)"
    ),
    across(
      starts_with("Actor"),
      ~ as.character(.)
    )
  ) |>
  select(P_Date, monitoring_group, Actor1, Actor1_tone, Actor2, Actor2_tone, Actor3, Actor3_tone) -> actor_data

bind_rows(
  actor_data |> transmute(P_Date, monitoring_group, actor_id = Actor1, tone = Actor1_tone),
  actor_data |> transmute(P_Date, monitoring_group, actor_id = Actor2, tone = Actor2_tone),
  actor_data |> transmute(P_Date, monitoring_group, actor_id = Actor3, tone = Actor3_tone)
) |>
  filter(!is.na(actor_id)) |> 
  group_by(actor_id, monitoring_group, tone, P_Date) |> 
  count() |>
  mutate(
    actor_id = as.numeric(actor_id)
  ) |>
  left_join(
    actors_src, by = "actor_id"
  ) |> 
  select(
    actor_id, actor_text, monitoring_group, tone, P_Date, n
  ) |>
  mutate(
    tone_id = case_when(
      tone == "დადებითი" ~ "positive",
      tone == "უარყოფითი" ~ "negative",
      tone == "ნეიტრალური" ~ "neutral"
    )
  )  -> actors_by_tone

cat(format_csv(actors_by_tone))
