---
theme: dashboard
title: Main Page
toc: false
style: custom-style.css
---

```js
// Import required libraries
import * as Inputs from "npm:@observablehq/inputs";

import {Treemap} from "./components/treemap.js";

import {Swatches} from "./components/swatches.js";

// Load custom fonts
FileAttachment("fonts/bpg-arial-caps-webfont.ttf").url().then(url => {
  const style = document.createElement('style');
  style.textContent = `
    @font-face {
      font-family: 'BPG Arial Caps';
      src: url(${url});
    }
    h2 { font-family: 'BPG Arial Caps', sans-serif; }
  `;
  document.head.appendChild(style);
});

FileAttachment("fonts/bpg-arial-webfont.ttf").url().then(url => {
  const style = document.createElement('style');
  style.textContent = `
    @font-face {
      font-family: 'BPG Arial';
      src: url(${url});
    }
    body, label, span { font-family: 'BPG Arial', sans-serif; }
    p { font-family: 'BPG Arial', sans-serif; font-size: 10px; font-style: italic}
  `;
  document.head.appendChild(style);
});


```

```js
// Load data



const dailyPosts = FileAttachment("data/daily_posts_by_group.csv").csv({ typed: true }).then(rows => 
  rows.map(d => ({ 
    ...d, 
    P_Date: new Date(d.P_Date),
    n: +d.n  // ensure numeric type
  }))
);

const narratives = FileAttachment("data/narratives_all.csv").csv({ typed: true }).then(rows => 
  rows.map(d => ({ 
    ...d, 
    P_Date: new Date(d.P_Date),
    n: +d.n  // ensure numeric type
  }))
);

const actors = FileAttachment("data/actors_all.csv").csv({ typed: true }).then(rows => 
  rows.map(d => ({ 
    ...d, 
    P_Date: new Date(d.P_Date),
    n: +d.n  // ensure numeric type
  }))
);

const main_events = FileAttachment("data/events_all.csv").csv({ typed: true }).then(rows => 
  rows.map(d => ({ 
    ...d, 
    date: new Date(d.date)
  }))
);


const main_themes = FileAttachment("data/themes_all.csv").csv({ typed: true }).then(rows => 
  rows.map(d => ({ 
    ...d, 
    P_Date: new Date(d.P_Date),
    n: +d.n  // ensure numeric type
  }))
);

const topic_colors_data = await FileAttachment("data/topic_colors.json").json().then(data => {
  return data;
});


const topicColorScale = d3.scaleOrdinal()
  .domain(topic_colors_data.map(d => d.topic_id)) // fixed internal IDs
  .range(topic_colors_data.map(d => d.color)); // fixed internal IDs
 
const toneColorScale = d3.scaleOrdinal()
  .domain(["positive", "neutral", "negative"])  // fixed internal IDs
  .range(["#66c2a5", "#fc8d62", "#8da0cb"]);

const translations = FileAttachment("data/translations.json").json().then(data => {
  return data;
});
```



```js

let currentLang = "ka"; // default language Georgian


// Define Georgian locale for date formatting
const d3Locales = {
  ka: d3.timeFormatLocale({
    dateTime: "%A, %e %B %Y %X",
    date: "%d/%m/%Y",
    time: "%H:%M:%S",
    periods: ["AM", "PM"],
    days: ["კვირა", "ორშაბათი", "სამშაბათი", "ოთხშაბათი", "ხუთშაბათი", "პარასკევი", "შაბათი"],
    shortDays: ["კვ", "ორ", "სმ", "ოთ", "ხთ", "პრ", "შბ"],
    months: ["იანვარი", "თებერვალი", "მარტი", "აპრილი", "მაისი", "ივნისი", "ივლისი", "აგვისტო", "სექტემბერი", "ოქტომბერი", "ნოემბერი", "დეკემბერი"],
    shortMonths: ["იან", "თებ", "მარ", "აპრ", "მაი", "ივნ", "ივლ", "აგვ", "სექ", "ოქტ", "ნოე", "დეკ"]
  }),
  en: d3.timeFormatLocale({
    dateTime: "%A, %e %B %Y %X",
    date: "%m/%d/%Y",
    time: "%H:%M:%S",
    periods: ["AM", "PM"],
    days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    months: ["January", "February", "March", "April", "May", "June",
             "July", "August", "September", "October", "November", "December"],
    shortMonths: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  })
};

// Define chart for daily posts by group
async function renderDailyPostsChart() {
  
  const [dailyDataRaw, rawEvents] = await Promise.all([dailyPosts, main_events]);
  
  const locale = d3Locales[currentLang];
  
  const eventTranslations = translations[currentLang].events;

  const monitoringGroupTranslation = translations[currentLang].segments;

  // Merge translations into events by ID
  const events = rawEvents.map(event => ({
    ...event,
    description: eventTranslations?.[event.event_id] || event.description
  }));   // merge translation events to main_events and then use in the chart

  const dailyData = dailyDataRaw.map(dailyData => ({
    ...dailyData,
    monitoring_group: monitoringGroupTranslation?.[dailyData.monitoring_group_id] || dailyData.monitoring_group
  }));   // merge translation events to main_events and then use in the chart

  return Plot.plot({
    style: {fontFamily: "BPG Arial"},
    color: {
      domain: dailyData.map(d => d.monitoring_group),
      range: ["#ffffb3", "#bc80bd", "#b3de69", "#80b1d3"],
      legend: true
    },
    marks: [
      Plot.barY(dailyData, {
        x: "P_Date",
        y: "n",
        fill: "monitoring_group",
        tip: true
      }),
      Plot.text(events, {
        x: "date",
        y: () => Math.max(...dailyData.map(d => d.n)) * 1.001,
        // split the description into lines of 20 characters each, also consider space
        text: d => d.description.replace(/(.{40}\s)/g, '$1\n').trim(), // split into lines of 20 characters
        // text: "description", // optionally use translated text if available
        dy: 20,
        rotate: -90,
        fill: "red",
        fontSize: 6,
        textAnchor: "middle"
      })
    ],
    x: {
      type: "band",
      tickFormat: locale.format("%d %b"),
      tickRotate: -90,
      label: null
    },
    y: {
      label: translations[currentLang].y_axis_label_daily_posts || "პოსტების რ-ნობა: "
    }
  });
}


const dates = dailyPosts.map(d => new Date(d.P_Date));

const maxDate = new Date(Math.max(...dates));

const initialEndDate = new Date(maxDate); // Preserves original maxDate

const initialStartDate = new Date(initialEndDate);

initialStartDate.setMonth(initialStartDate.getMonth() - 1); // minus one month clearly

const endDate = Inputs.date({ value: initialEndDate});

const startDate = Inputs.date({ value: initialStartDate});

const endDateActors = Inputs.date({ value: initialEndDate});

const startDateActors = Inputs.date({ value: initialStartDate});

const endDateTopics = Inputs.date({ value: initialEndDate});

const startDateTopics = Inputs.date({ value: initialStartDate});


const tabs = document.querySelectorAll('.tabs input[type="radio"]');

const tabs_actors = document.querySelectorAll('.tabs-actors input[type="radio"]');

const tabs_topics = document.querySelectorAll('.tabs-topics input[type="radio"]');

const panels = document.querySelectorAll('.tab-panels .tab-panel');

const panels_actors = document.querySelectorAll('.tab-panels-actors .tab-panel');

const panels_topics = document.querySelectorAll('.tab-panels-topics .tab-panel');


const narrativeTabMappings = {"All":"chart-all","აზერბაიჯანულენოვანი სეგმენტი":"chart-az","აჭარის სეგმენტი":"chart-adjara","სომხურენოვანი სეგმენტი":"chart-arm","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other"};

const actorsTabMappings = {"All":"chart-all-actors","აზერბაიჯანულენოვანი სეგმენტი":"chart-az-actors","აჭარის სეგმენტი":"chart-adjara-actors","სომხურენოვანი სეგმენტი":"chart-arm-actors","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-actors"};

const topicsTabMappings = {"All":"chart-all-topics","აზერბაიჯანულენოვანი სეგმენტი":"chart-az-topics","აჭარის სეგმენტი":"chart-adjara-topics","სომხურენოვანი სეგმენტი":"chart-arm-topics","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-topics"};



async function renderChart(group,id){
  
  const [narrativesRaw] = await Promise.all([narratives]);
  
  const no_data_message = translations[currentLang].no_data;

  const narrativeTranslations = translations[currentLang].narratives;

  const data=narrativesRaw.filter(d=>(group==='All'||d.monitoring_group===group)&&d.P_Date>=startDate.value&&d.P_Date<=endDate.value);
  
  if(data.length===0){
    document.getElementById(id).innerHTML =
      `<p>${no_data_message}</p>`;
    return;
  }
  
  let dataTranslated = data.map(data => ({
    ...data,
    narrative_text: narrativeTranslations?.[data.narrative_id] || data.narrative_text
  }));


  let agg=Object.entries(dataTranslated.reduce((a,{narrative_text,n})=>(a[narrative_text]=(a[narrative_text]||0)+n,a),{})).sort(([,a],[,b])=>b-a).slice(0,7);
  document.getElementById(id).innerHTML='';
  document.getElementById(id).appendChild(Plot.plot(
    {
    style: {fontFamily: "BPG Arial"},

      marks:[
        Plot.barX(
          agg,
            {
              x:d=>d[1],y:d=>d[0],
              sort:{
                y: "x",
                reverse: true
              },
              fill: "#a6cee3",
              tip: true
            }
        ),
        Plot.ruleX([0])
      ],
        width:700,
        height:400,
        marginLeft:150,
        x:{
          label: translations[currentLang].narrative_count_axis_text || "შემთხვევების რ-ნობა: "
        },
        y:{
            label: null,
            tickFormat: d => d.replace(/(.{10}\s)/g, '$1\n')
          }
    }
  ));
}

async function renderChartActors(group, id) {
  const no_data_message = translations[currentLang].no_data;
  const actorTranslations = translations[currentLang].actors;
  const toneTranslations = translations[currentLang].tone;

  const data_actors = (await actors).filter(d =>
    (group === 'All' || d.monitoring_group === group) &&
    d.P_Date >= startDateActors.value && d.P_Date <= endDateActors.value
  );

  if (data_actors.length === 0) {
    document.getElementById(id).innerHTML = `<p>${no_data_message}</p>`;
    return;
  }

  let translatedActors = data_actors.map(d => ({
    actor_text: actorTranslations?.[d.actor_id] || d.actor_text,
    tone_id: d.tone_id,
    tone_label: toneTranslations?.[d.tone_id] || d.tone,
    n: d.n
  }));

  let agg_actors = Object.entries(
    translatedActors.reduce((a, { actor_text, tone_id, tone_label, n }) => {
      const key = `${actor_text}||${tone_id}||${tone_label}`;
      a[key] = (a[key] || 0) + n;
      return a;
    }, {})
  ).map(([key, n]) => {
    const [actor_text, tone_id, tone_label] = key.split("||");
    return { actor_text, tone_id, tone_label, n };
  });

  let totals = agg_actors.reduce((a, { actor_text, n }) => {
    a[actor_text] = (a[actor_text] || 0) + n;
    return a;
  }, {});

  agg_actors = agg_actors
    .filter(({ actor_text }) => totals[actor_text] > 0)
    .sort((a, b) => totals[b.actor_text] - totals[a.actor_text])
    .slice(0, 7);

  document.getElementById(id).innerHTML = '';
  
  const chart = Plot.plot({
    style: { fontFamily: "BPG Arial" },
    color: {
      domain: toneColorScale.domain(),
      range: toneColorScale.range(),
      legend: false  // 👈 explicitly disable Plot's built-in legend
    },
    marks: [
      Plot.barX(agg_actors, {
        x: "n",
        y: "actor_text",
        fill: "tone_id",
        tip: true
      }),
      Plot.ruleX([0])
    ],
    width: 700,
    height: 400,
    marginLeft: 250,
    y: {
      label: null,
      tickFormat: d => d.replace(/(.{10}\s)/g, '$1\n')
    },
    x: { label: translations[currentLang].actor_count_axis_text }
  });

  // Append chart
  document.getElementById(id).appendChild(chart);

  // 👈 Rebuild custom legend dynamically
  const legendContainerId = `${id}-legend`;
  let legendContainer = document.getElementById(legendContainerId);

  if (!legendContainer) {
    legendContainer = document.createElement('div');
    legendContainer.id = legendContainerId;
    legendContainer.style.marginTop = '10px';
    document.getElementById(id).appendChild(legendContainer);
  } else {
    legendContainer.innerHTML = '';
  }

  const translatedLegend = toneColorScale.domain().map(id => ({
    color: toneColorScale(id),
    label: toneTranslations[id]
  }));

  legendContainer.appendChild(Swatches(d3.scaleOrdinal()
    .domain(translatedLegend.map(d => d.label))
    .range(translatedLegend.map(d => d.color))
  ));
}




function getActiveTab(tabsSelector) {
  const selectedTab = document.querySelector(`${tabsSelector}:checked`);
  return selectedTab ? selectedTab.value : 'All';
}

async function renderChartTopics(group, id) {
  const themesData = await main_themes;
  const container = document.getElementById(id);
  const legendContainer = document.getElementById('tab-key-topics');

  container.innerHTML = '';

  legendContainer.innerHTML = '';

  const topicTranslations = translations[currentLang].topics;
  const narrativeTranslations = translations[currentLang].narratives;
  const no_data_message = translations[currentLang].no_data;

  let data_topics = themesData.filter(d =>
    (group === 'All' || d.monitoring_group === group) &&
    d.P_Date >= startDateTopics.value &&
    d.P_Date <= endDateTopics.value
  );

  if(data_topics.length===0){
    document.getElementById(id).innerHTML =
      `<p>${no_data_message}</p>`;
    return;
  }
  
  let dataTopicsTranslated = data_topics.map(data_topics => ({
    ...data_topics,
    narrative_text: narrativeTranslations?.[data_topics.narrative_id] || data_topics.narrative_text
  }));

// 1. Aggregate total value per topic_id
const topicTotals = dataTopicsTranslated.reduce((acc, { topic_id, n }) => {
  topic_id = +topic_id;
  acc[topic_id] = (acc[topic_id] || 0) + n;
  return acc;
}, {});

// 2. Get top 7 topic_ids by total value
const topTopicIDs = Object.entries(topicTotals)
  .sort(([, a], [, b]) => b - a)
  .slice(0, 7)
  .map(([id]) => +id); // Ensure numeric topic_id

// 3. Filter data and nest only top topics
let nested_topics = Object.values(
  dataTopicsTranslated.reduce((acc, { topic_id, narrative_id, narrative_text, n }) => {
    topic_id = +topic_id;
    narrative_id = +narrative_id;

    if (!topTopicIDs.includes(topic_id)) return acc;

    if (!acc[topic_id]) {
      acc[topic_id] = {
        name: topic_id,
        children: []
      };
    }

    const existing = acc[topic_id].children.find(d => d.name === narrative_id);
    if (existing) {
      existing.value += n;
    } else {
      acc[topic_id].children.push({
        name: narrative_id,
        description: narrative_text,
        value: n
      });
    }

    return acc;
  }, {})
);

const hierarchical_topics = {
  name: "topic",
  children: nested_topics  // your current array of topic-level nodes
};

const trmp = Treemap(hierarchical_topics, {
  group: (d, n) => n.ancestors().slice(-2)[0].data.name,  // top-level topic_id
  value: d => d.value,
  label: (d, n) => `${d.description.replace(/(.{10}\s)/g, '$1\n') || ""}\n${n.value.toLocaleString(currentLang)} ${translations[currentLang].events_count_label}`,
  width: 700,
  height: 500,
  zDomain: topicColorScale.domain(),
  colors: topicColorScale.range()
});

  console.log(topicColorScale.domain());


  // filter topicColorScale using nested topic ids
  const filteredTopicColorScale = d3.scaleOrdinal()
    .domain(topicColorScale.domain().filter(topicID => topTopicIDs.includes(+topicID))) // filter to only include top topic IDs
    .range(topicColorScale.range().filter((_, i) => topTopicIDs.includes(+topicColorScale.domain()[i]))); // filter to match the same order
  
  console.log(filteredTopicColorScale.domain());

  const translatedLegendScale = filteredTopicColorScale.domain().map(topicID => ({
    color: topicColorScale(topicID),
    label: topicTranslations[topicID]
  }));


  // 👈 Rebuild custom legend dynamically
  const legendContainerId1 = `${id}-legend`;
  let legendContainer1 = document.getElementById(legendContainerId1);

  if (!legendContainer1) {
    legendContainer1 = document.createElement('div');
    legendContainer1.id = legendContainerId1;
    legendContainer1.style.marginTop = '10px';
    document.getElementById(id).appendChild(legendContainer1);
  } else {
    legendContainer1.innerHTML = '';
  }


legendContainer1.appendChild(Swatches(d3.scaleOrdinal()
  .domain(translatedLegendScale.map(d => d.label))
  .range(translatedLegendScale.map(d => d.color))
));

  container.appendChild(trmp);


  // 🟢 Update Treemap text labels manually (after treemap creation):
  container.querySelectorAll('text').forEach(node => {
    const originalID = node.textContent;
    if (topicTranslations[originalID]) {
      node.textContent = topicTranslations[originalID];
    }
  });

}


renderDailyPostsChart().then(chart => {
  document.getElementById("daily-posts-chart-container").appendChild(chart);
});

function updateCharts(){Object.entries(narrativeTabMappings).forEach(([g,id])=>renderChart(g,id));}

tabs.forEach(t=>t.addEventListener('change',()=>{panels.forEach(p=>p.style.display='none');document.getElementById(`${t.id}-panel`).style.display='block';updateCharts();}));

[startDate,endDate].forEach(e=>e.addEventListener('input',updateCharts));

function updateChartsActors(){Object.entries(actorsTabMappings).forEach(([g,id])=>renderChartActors(g,id));}

tabs_actors.forEach(t => t.addEventListener('change', () => {
  panels_actors.forEach(p => p.style.display = 'none');
  document.getElementById(`${t.id}-panel`).style.display = 'block';
  updateChartsActors();
}));

[startDateActors, endDateActors].forEach(e => e.addEventListener('input', updateChartsActors));

function updateChartsTopics() {
  const activeGroup = getActiveTab('.tabs-topics input[type="radio"]');
  const activeId = topicsTabMappings[activeGroup];
  renderChartTopics(activeGroup, activeId);
}

tabs_topics.forEach(t => t.addEventListener('change', () => {
  panels_topics.forEach(p => p.style.display = 'none');
  document.getElementById(`${t.id}-panel`).style.display = 'block';
  updateChartsTopics();
}));


[startDateTopics, endDateTopics].forEach(e => e.addEventListener('input', updateChartsTopics));


Promise.all([dailyPosts, narratives, actors, main_themes, topic_colors_data, translations])
  .then(() => {
    updateCharts();
    updateChartsActors();
    updateChartsTopics();
  });

async function updateTexts() {
  document.getElementById('start-date-container').innerText = translations[currentLang].date_picker_start;
  document.getElementById('end-date-container').innerText = translations[currentLang].date_picker_end;
  document.getElementById('start-date-container-actors').innerText = translations[currentLang].date_picker_start;
  document.getElementById('end-date-container-actors').innerText = translations[currentLang].date_picker_end;
  document.getElementById('start-date-container-topics').innerText = translations[currentLang].date_picker_start;
  document.getElementById('end-date-container-topics').innerText = translations[currentLang].date_picker_end;
  document.getElementById('title_daily_posts').innerText = translations[currentLang].title_daily_posts;
  document.getElementById('title_narratives').innerText = translations[currentLang].title_narratives;
  document.getElementById('title_actors').innerText = translations[currentLang].title_actors;
  document.getElementById('title_topics').innerText = translations[currentLang].title_topics;
  document.getElementById('smallnote').innerText = translations[currentLang].smallnote;
  document.getElementById('tooltip_narrative').innerText = translations[currentLang].tooltip_narrative;
  document.getElementById('tooltip_n_posts').innerText = translations[currentLang].tooltip_n_posts;
  document.getElementById('tooltip_actors').innerText = translations[currentLang].tooltip_actors;
  document.getElementById('tooltip_topics').innerText = translations[currentLang].tooltip_topics;
  document.getElementById('dash_title').innerText = translations[currentLang].dash_title;

  document.querySelectorAll('.tabs label').forEach((el, idx) => {
    const keys = ['all', 'az', 'adjara', 'arm', 'other'];
    el.innerText = translations[currentLang].segments[keys[idx]];
  });

 document.querySelectorAll('.tabs-actors label').forEach((el, idx) => {
   const keys = ['all', 'az', 'adjara', 'arm', 'other'];
   el.innerText = translations[currentLang].segments[keys[idx]];
 });
 
document.querySelectorAll('.tabs-topics label').forEach((el, idx) => {
  const keys = ['all', 'az', 'adjara', 'arm', 'other'];
  el.innerText = translations[currentLang].segments[keys[idx]];
});


  startDateActors.label = translations[currentLang].date_picker_start;
  endDateActors.label = translations[currentLang].date_picker_end;
  startDateTopics.label = translations[currentLang].date_picker_start;
  endDateTopics.label = translations[currentLang].date_picker_end;
  updateCharts();
  updateChartsActors();
  updateChartsTopics();
}

// Initial UI update
updateTexts();

document.getElementById("languageSwitcher").addEventListener('change', (e) => {
  currentLang = e.target.value;
  updateTexts();         // your existing UI text update logic
  updateCharts();        // your narrative charts
  updateChartsActors();  // your actor charts
  updateChartsTopics();  // your topic charts

  // 👉 Re-render daily posts chart
  renderDailyPostsChart().then(chart => {
    const container = document.getElementById("daily-posts-chart-container");
    container.innerHTML = "";
    container.appendChild(chart);
  });
});

```

<select id="languageSwitcher">
  <option value="ka">ქართული</option>
  <option value="en">English</option>
</select>

<div id = "dash_title"></div>

<div class="grid grid-cols-4">
  
  <div class="card grid-colspan-2 grid-rowspan-1">
  <div class="tooltip-container">
    <h2 id="title_daily_posts"></h2>
    <span class="tooltip-text" id = "tooltip_n_posts"></span>
  </div>
    <figure style="max-width: none;">
      <div style="display: flex; flex-direction: column; align-items: center;">
        <div style="display: flex; align-items: center;">
          <div id="daily-posts-chart-container"></div>
        </div>
      </div>
    </figure>
  </div>

  <div class="card grid-colspan-2">
  <div class="tooltip-container">
    <h2 id="title_narratives"></h2>
    <span class="tooltip-text" id = "tooltip_narrative"></span>
  </div>
        <div class="tabs">
          <input type="radio" name="tabset-narratives" id="tab-full-data" value="All" checked>
          <label for="tab-full-data">სრული მონაცემები</label>
          <input type="radio" name="tabset-narratives" id="tab2" value="აზერბაიჯანულენოვანი სეგმენტი">
          <label for="tab2">აზერბაიჯანულენოვანი სეგმენტი</label>
          <input type="radio" name="tabset-narratives" id="tab3" value="აჭარის სეგმენტი">
          <label for="tab3">აჭარის სეგმენტი</label>
          <input type="radio" name="tabset-narratives" id="tab4" value="სომხურენოვანი სეგმენტი">
          <label for="tab4">სომხურენოვანი სეგმენტი</label>
          <input type="radio" name="tabset-narratives" id="tab5" value="ქართულენოვანი სეგმენტი (აჭარის გარდა)">
          <label for="tab5">ქართულენოვანი სეგმენტი (აჭარის გარდა)</label>
        </div>
        <div class="tab-panels">
          <div class="tab-panel" id="tab-full-data-panel" style="display:block;"><div id="chart-all"></div></div>
          <div class="tab-panel" id="tab2-panel" style="display:none;"><div id="chart-az"></div></div>
          <div class="tab-panel" id="tab3-panel" style="display:none;"><div id="chart-adjara"></div></div>
          <div class="tab-panel" id="tab4-panel" style="display:none;"><div id="chart-arm"></div></div>
          <div class="tab-panel" id="tab5-panel" style="display:none;"><div id="chart-other"></div></div>
        </div>
        <table>
          <tbody>
            <tr></tr>
            <tr>
              <td id="start-date-container"></td>
              <td>${startDate}</td>
            </tr>
            <tr>
              <td id="end-date-container"></td>
              <td>${endDate}</td>
            </tr>
            <tr></tr>
          </tbody>
      </table>
    </div>
  </div>
</div>

<div class="grid grid-cols-4">
  <div class="card grid-colspan-2 grid-rowspan-1">
   <div class="tooltip-container">
    <h2 id="title_actors"></h2>
    <span class="tooltip-text" id = "tooltip_actors"></span>
  </div>
    <div class="tabs-actors">
      <input type="radio" name="tabset-actors" id="tab-full-data-actors" value="All" checked>
      <label for="tab-full-data-actors">სრული მონაცემები</label>
      <input type="radio" name="tabset-actors" id="tab2-actors" value="აზერბაიჯანულენოვანი სეგმენტი">
      <label for="tab2-actors">აზერბაიჯანულენოვანი სეგმენტი</label>
      <input type="radio" name="tabset-actors" id="tab3-actors" value="აჭარის სეგმენტი">
      <label for="tab3-actors">აჭარის სეგმენტი</label>
      <input type="radio" name="tabset-actors" id="tab4-actors" value="სომხურენოვანი სეგმენტი">
      <label for="tab4-actors">სომხურენოვანი სეგმენტი</label>
      <input type="radio" name="tabset-actors" id="tab5-actors" value="ქართულენოვანი სეგმენტი (აჭარის გარდა)">
      <label for="tab5-actors">ქართულენოვანი სეგმენტი (აჭარის გარდა)</label>
    </div>
    <div class="tab-panels-actors">
      <div class="tab-panel" id="tab-full-data-actors-panel" style="display:block;"><div id="chart-all-actors"></div></div>
      <div class="tab-panel" id="tab2-actors-panel" style="display:none;"><div id="chart-az-actors"></div></div>
      <div class="tab-panel" id="tab3-actors-panel" style="display:none;"><div id="chart-adjara-actors"></div></div>
      <div class="tab-panel" id="tab4-actors-panel" style="display:none;"><div id="chart-arm-actors"></div></div>
      <div class="tab-panel" id="tab5-actors-panel" style="display:none;"><div id="chart-other-actors"></div></div>
    </div>
        <table>
          <tbody>
            <tr></tr>
            <tr>
              <td id="start-date-container-actors"></td>
              <td>${startDateActors}</td>
            </tr>
            <tr>
              <td id="end-date-container-actors"></td>
              <td>${endDateActors}</td>
            </tr>
            <tr></tr>
          </tbody>
      </table>
  </div>

  <div class="card grid-colspan-2 grid-rowspan-1">
    <div class="tooltip-container">
    <h2 id="title_topics"></h2>
    <span class="tooltip-text" id = "tooltip_topics"></span>
  </div>
    <div class="tabs-topics">
      <input type="radio" name="tabset-topics" id="tab-full-data-topics" value="All" checked>
      <label for="tab-full-data-topics">სრული მონაცემები</label>
      <input type="radio" name="tabset-topics" id="tab2-topics" value="აზერბაიჯანულენოვანი სეგმენტი">
      <label for="tab2-topics">აზერბაიჯანულენოვანი სეგმენტი</label>
      <input type="radio" name="tabset-topics" id="tab3-topics" value="აჭარის სეგმენტი">
      <label for="tab3-topics">აჭარის სეგმენტი</label>
      <input type="radio" name="tabset-topics" id="tab4-topics" value="სომხურენოვანი სეგმენტი">
      <label for="tab4-topics">სომხურენოვანი სეგმენტი</label>
      <input type="radio" name="tabset-topics" id="tab5-topics" value="ქართულენოვანი სეგმენტი (აჭარის გარდა)">
      <label for="tab5-topics">ქართულენოვანი სეგმენტი (აჭარის გარდა)</label>
    </div>
    <div class="tab-panels-topics">
      <div class="tab-panel" id="tab-full-data-topics-panel" style="display:block;"><div id="chart-all-topics"></div></div>
      <div class="tab-panel" id="tab2-topics-panel" style="display:none;"><div id="chart-az-topics"></div></div>
      <div class="tab-panel" id="tab3-topics-panel" style="display:none;"><div id="chart-adjara-topics"></div></div>
      <div class="tab-panel" id="tab4-topics-panel" style="display:none;"><div id="chart-arm-topics"></div></div>
      <div class="tab-panel" id="tab5-topics-panel" style="display:none;"><div id="chart-other-topics"></div></div>
    </div>
        <table>
          <tbody>
            <tr></tr>
            <tr>
              <td id="start-date-container-topics"></td>
              <td>${startDateTopics}</td>
            </tr>
            <tr>
              <td id="end-date-container-topics"></td>
              <td>${endDateTopics}</td>
            </tr>
            <tr></tr>
          </tbody>
      </table>
    <div id="tab-key-topics" style="display: flex; flex-direction: column; align-items: center; margin-top: 20px;">
  </div>
</div>
</div>

<div id="smallnote"></div>