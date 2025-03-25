library(tidyverse)
library(readxl)

init_data <- read_excel("src/data/dashboard_data.xlsx")


narratives_src <- read_excel("src/data/dashboard_data.xlsx", sheet = "თემა")

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
      T ~ "ქართულენოვანი სეგმენტი (აჭარის გარდა)"
    )
  ) |>
  select(
    Narat1_topic, Narat2_topic, Narat3_topic
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable_id",
    values_to = "topic_id"
  ) |> 
left_join(
    narratives_src, by = "topic_id"
) |>
count(topic_id, topic_text) |>
filter(
    !is.na(topic_id)
) -> discussed_topics

cat(format_csv(discussed_topics))