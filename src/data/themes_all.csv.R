library(tidyverse)
library(readxl)

init_data <- read_excel("src/data/dashboard_data.xlsx")

narratives_src <- read_excel("src/data/dashboard_data.xlsx", sheet = "ნარატივები") 

topics_src <- read_excel("src/data/dashboard_data.xlsx", sheet = "თემა")

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
      T ~ "ქართულენოვანი სეგმენტი (აჭარის გარდა)"
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

init_data %>%
    set_names(tbl_names) %>%
    dplyr::filter(
      # P_status == "რელევანტურია"
    ) %>%
    dplyr::mutate(
      monitoring_group = dplyr::case_when(
        PG_name %in% c("ახალი ამბები განსჯისთვის", "Javakhk") ~ "სომხურენოვანი სეგმენტი",
        PG_name %in% c("Aktual.ge", "24News.ge") ~ "აზერბაიჯანულენოვანი სეგმენტი",
        PG_name %in% c("ბიძინა ივანიშვილის მხარდამჭერი ჯგუფი აჭარაში", "აჭარა გვერდი") ~ "აჭარის სეგმენტი",
        TRUE ~ "ქართულენოვანი სეგმენტი (აჭარის გარდა)"
      )
    ) -> cleaned_data

add_topics <- function(data, nar_col, topic_col) {
  data %>%
    select(all_of(nar_col), all_of(topic_col)) %>%
    distinct() %>%
    set_names(c("narrative", "topic"))
}

# Main approach:
all_narratives_topics <- map2_dfr(
  .x = c("Narat1", "Narat2", "Narat3"),
  .y = c("Narat1_topic", "Narat2_topic", "Narat3_topic"),
  ~ add_topics(cleaned_data, .x, .y)
) |> 
filter(!is.na(topic) & !is.na(narrative)) |> 
  left_join(
    narratives_src |> distinct(narrative_id, .keep_all = T), by = c("narrative" = "narrative_id")
  ) |>
  left_join(
    topics_src |> distinct(topic_id, .keep_all = T), by = c("topic" = "topic_id")
  ) 

init_data |>
  set_names(
    tbl_names
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
    P_Date, narrative_text, narrative_id, monitoring_group
  ) |>
  count() |> 
  mutate(
    P_Date = as.Date(P_Date),
    id = row_number()
  ) |> 
  left_join(
    all_narratives_topics |> select(narrative, topic_text) |> distinct(narrative, .keep_all = T), by = c("narrative_id" = "narrative")
  ) |> 
  group_by(
    P_Date, monitoring_group, narrative_text, narrative_id, topic_text
  ) |> 
  summarize(
    n = sum(n)
  )-> narratives_all_with_topics

narratives_all_with_topics |> 
  group_by(topic_text) |> 
  summarize(
    n_topic = sum(n)
  ) |> 
  # select top 5 by n_topic
  top_n(5, n_topic) |>
  select(topic_text) |> unname() |> unlist() -> top_5_topics

narratives_all_with_topics |> 
  filter(topic_text %in% top_5_topics) -> narratives_filtered

cat(format_csv(narratives_all_with_topics))
