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
        title_narratives  = "ყველაზე გავრცელებული ანტიდასავლური ნარატივი",
        title_actors      = "ყველაზე ხშირად ნახსენები აქტორი",
        title_topics      = "ყველაზე გავრცელებული თემა",
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
        events = setNames(as.list(events$description), events$event_id),
        smallnote = "პროექტისთვის „ანტიდემოკრატიული პროპაგანდის წინააღმდეგ ბრძოლა“, რომელიც 2025 წლის იანვარში დაიწყო და წლის ბოლომდე გაგრძელდება, CRRC-საქართველო შერეული მეთოდების გამოყენებით ატარებს კვლევას. კვლევის მიზანია, საჯარო პოლიტიკის ექსპერტები, სამოქალაქო საზოგადოება, მედია პროფესიონალები და, ზოგადად, მოსახლეობა აღჭურვოს დეზინფორმაციისა და პროპაგანდის ამოცნობისა და მასთან ბრძოლის ცოდნითა და ხელსაწყოებით. კვლევის მოცემული კომპონენტი სოციალურ ქსელ „ფეისბუქში“ ანტიდასავლური ნარატივების შესწავლას შეეხება. 

წინასწარი მოკვლევისა და საკონსულტაციო ჯგუფის რეკომენდაციების გათვალისწინებით, შერჩეულია 16 საჯარო გვერდი/ჯგუფი, რომელიც ანტიდასავლური შინაარსის პოსტებით გამოირჩევა. კვლევის ფარგლებში გროვდება ინფორმაცია იმაზე, თუ რა ნარატივები გვხვდება ამ გვერდებზე/ჯგუფებში გავრცელებულ პოსტებში, რა თემატიკას ეხება ეს ნარატივები, ვინ ან რომელი უწყებები, ორგანიზაციები თუ ქვეყნებია ნახსენები და რამდენად დადებითი, ნეიტრალური ან უარყოფითია მათი წარმოჩენა.

შერჩეულ 16 საჯარო გვერდს/ჯგუფს შორისაა ორი აზერბაიჯანულენოვანი გვერდი, ერთი სომხურენოვანი გვერდი და ერთი სომხურენოვანი ჯგუფი, ასევე, თითო გვერდი და ჯგუფი, რომელიც აჭარის რეგიონზეა ფოკუსირებული. აღსანიშნავია, რომ აჭარის გვერდისა და აზერბაიჯანულენოვანი გვერდების შემთხვევაში ანტიდასავლური შინაარსის პოსტები შედარებით იშვიათია და გვხვდება მაშინ, როცა ამ თემაზე რაიმე ახალი ამბავია გაშუქებული.

შერჩეულ გვერდებსა და ჯგუფებში მონაცემები გროვდება 2024 წლის 28 ნოემბრის შემდგომი პოსტებიდან. ეს თარიღი, როცა საქართველოს პრემიერმინისტრმა განაცხადა რომ ქვეყანა 2028 წლამდე დღის წესრიგში აღარ დააყენებს ევროკავშირთან მოლაპარაკებების ეტაპის გახსნას, მოსახლეობის დიდმა ნაწილმა ანტიდასავლურ ნაბიჯად აღიქვა და მას გრძელვადიანი პროტესტი მოჰყვა, ამიტომაც კვლევის ამ კომპონენტისთვის საწყის ეტაპად მიიჩნევა.

        ",
        tooltip_narrative = "დიაგრამაზე მოცემულია პოსტების რაოდენობა. ნარატივების ფორმულირება ჩამოყალიბებულია პოსტის შინაარსზე დაყრდნობით.",
        tooltip_n_posts = "პოსტების რაოდენობა, რომლებიც პირველადი ანალიზის შედეგად რელევანტურად ჩაითვალა. რელევანტურია ისეთი პოსტი, რომელიც ავითარებს ანტიდასავლურ ან პრორუსულ დისკურსს, ეხება დასავლეთს ან პროდასავლურ პროტესტს.",
        tooltip_actors = "დიაგრამაზე მოცემულია პოსტების რაოდენობა. სამბალიან სკალაზე (დადებითი, ნეიტრალური, უარყოფითი) შეფასებულია აქტორების წარმოჩენა პოსტში.",
        tooltip_topics = "დიაგრამა აჯამებს პოსტების თემატიკას და წარმოაჩენს ყველაზე გავრცელებულ თემებს (აღნიშნულია ფერით) და ამ თემაზე არსებულ ნარატივებს (თითოეული ფერის ოთხკუთხედში მოცემული ტექსტი)"
    ),
    en = list(
        events_count_label = "",
        narrative_count_axis_text = "Number of Occurrences",
        x_axis_label_daily_posts = "Date",
        y_axis_label_daily_posts = "Number of Posts",
        title_daily_posts = "Relevant Posts by Date",
        title_narratives  = "Top Anti-Western Narratives",
        title_actors      = "Most Mentioned Actors",
        title_topics      = "Most Frequent Topics",
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
        events = setNames(as.list(events$description_en), events$event_id),
        smallnote = "For the project \"Combating Anti-Democratic Propaganda for Engagement\", which began in January 2025 and will continue until the end of the year, CRRC-Georgia is conducting research using a mixed-methods approach. The key objective of the project is to empower policy experts, CSOs, media professionals, and general public with the tools to understand and combat disinformation and propaganda. This specific component of the study focuses on examining anti-Western narratives on the social network Facebook.

Based on preliminary research and recommendations from a consultative group, 16 public pages/groups were selected that are characterized by posts with anti-Western content. Within the scope of the study, information is being collected about the narratives present in the posts shared on these pages/groups, the topics these narratives address, which individuals, institutions, organizations, or countries are mentioned, and how they are portrayed—positively, neutrally, or negatively.

Among the 16 selected public pages/groups are two Azerbaijani-language pages, one Armenian-language page, and one Armenian-language group, as well as a page and a group focused on the Adjara region. It is worth noting that, in the case of the Adjara-focused page and the Azerbaijani-language pages, anti-Western posts are relatively rare and tend to appear only when specific news are covered.

Data is being collected from posts published on the selected pages and groups after November 28, 2024. This date marks the announcement by the Prime Minister of Georgia that the country would not pursue the opening of negotiations with the European Union until at least 2028—a statement that was perceived by a large portion of the population as an anti-Western move and triggered a prolonged wave of protest. As such, it is considered the starting point for this component of the research.
        ",
        tooltip_narrative = "The diagram shows the number of posts. The narratives are formulated based on the content of the posts.",
        tooltip_n_posts = "The number of posts identified as relevant based on preliminary analysis. A post is considered relevant if it promotes an anti-Western or pro-Russian discourse, refers to the West, or addresses pro-Western protests.",
        tooltip_actors = "The diagram shows the number of posts. Each actor's portrayal in the post is evaluated on a three-point scale (positive, neutral, negative).",
        tooltip_topics = "The diagram summarizes the topics of the posts and highlights the most common ones (indicated by color), along with the narratives associated with each topic (the text inside each colored rectangle)."


    )
)

# Save the translations to a JSON file

cat(jsonlite::toJSON(
    translations,
    path = "src/data/translations.json",
    pretty = TRUE,
    auto_unbox = TRUE
))
