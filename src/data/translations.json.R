library(tidyverse)
library(jsonlite)
library(readxl)


# Load the translations from the Excel file
narratives <- readxl::read_excel("src/data/dashboard_data.xlsx", sheet = "ნარატივები")
actors <- readxl::read_excel("src/data/dashboard_data.xlsx", sheet = "აქტორები")
topics <- readxl::read_excel("src/data/dashboard_data.xlsx", sheet = "თემა")
events <- readxl::read_excel("src/data/dashboard_data.xlsx", sheet = "მოვლენები")

translations <- list(
    ka = list(
        events_count_label = "შემთხვევა",
        narrative_count_axis_text = "შემთხვევების რ-ნობა",
        x_axis_label_daily_posts = "თარიღი",
        y_axis_label_daily_posts = "პოსტების რაოდენობა",
        title_daily_posts = "რელევანტური პოსტების რაოდენობა თარიღის მიხედვით",
        title_narratives  = "შვიდი ყველაზე გავრცელებული ანტიდასავლური ნარატივი",
        title_actors      = "შვიდი ყველაზე ხშირად ნახსენები აქტორი",
        title_topics      = "შვიდი ყველაზე გავრცელებული თემა",
        date_picker_start = "აარჩიეთ საწყისი თარიღი",
        date_picker_end   = "აარჩიეთ საბოლოო თარიღი",
        no_data         = "დროის ამ მონაკვეთისთვის მოცემული სეგმენტის მონაცემები არ არსებობს",
        segments = list(
            all    = "სრული მონაცემები",
            az     = "აზერბაიჯანულენოვანი სეგმენტი",
            adjara = "აჭარის სეგმენტი",
            arm    = "სომხურენოვანი სეგმენტი",
            other  = "ქართულენოვანი სეგმენტი (აჭარის გარეშე)"
        ),
        tone = list(
            positive = "დადებითი",
            negative = "უარყოფითი",
            neutral  = "ნეიტრალური"
        ),
        narratives = setNames(as.list(narratives$narrative_text), narratives$narrative_id),
        actors = setNames(as.list(actors$actor_text), actors$actor_id),
        topics = setNames(as.list(topics$topic_text), topics$topic_id),
        events = setNames(as.list(events$description), events$event_id)
    ),
    en = list(
        events_count_label = "",
        narrative_count_axis_text = "Number of Occurrences",
        x_axis_label_daily_posts = "Date",
        y_axis_label_daily_posts = "Number of Posts",
        title_daily_posts = "Relevant Posts by Date",
        title_narratives  = "Top 7 Anti-Western Narratives",
        title_actors      = "Top 7 Most Mentioned Actors",
        title_topics      = "Top 7 Most Frequent Topics",
        date_picker_start = "Select Start Date",
        date_picker_end   = "Select End Date",
        no_data         = "No data available for the selected time period.",
        segments = list(
            all    = "All Data",
            az     = "Azerbaijani Segment",
            adjara = "Adjara Segment",
            arm    = "Armenian Segment",
            other  = "Georgian Segment (excluding Adjara)"
        ),
        tone = list(
            positive = "Positive",
            negative = "Negative",
            neutral  = "Neutral"
        ),
        narratives = setNames(as.list(narratives$narrative_text_en), narratives$narrative_id),
        actors = setNames(as.list(actors$actor_text_en), actors$actor_id),
        topics = setNames(as.list(topics$topic_text_en), topics$topic_id),
        events = setNames(as.list(events$description_en), events$event_id)
    )
)

# Save the translations to a JSON file

cat(jsonlite::toJSON(
    translations,
    path = "src/data/translations.json",
    pretty = TRUE,
    auto_unbox = TRUE
))
