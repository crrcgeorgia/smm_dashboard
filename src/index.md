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

const globalColorScale = d3.scaleOrdinal(d3.schemeTableau10);

main_themes.then(data => {
  const allTopics = Array.from(new Set(data.map(d => d.topic_text)));
  globalColorScale.domain(allTopics);
});


```



```js
// Define Georgian locale for date formatting
const localeKA = d3.timeFormatLocale({
  dateTime: "%A, %e %B %Y %X",
  date: "%d/%m/%Y",
  time: "%H:%M:%S",
  periods: ["AM", "PM"],
  days: ["კვირა", "ორშაბათი", "სამშაბათი", "ოთხშაბათი", "ხუთშაბათი", "პარასკევი", "შაბათი"],
  shortDays: ["კვ", "ორ", "სმ", "ოთ", "ხთ", "პრ", "შბ"],
  months: ["იანვარი", "თებერვალი", "მარტი", "აპრილი", "მაისი", "ივნისი", "ივლისი", "აგვისტო", "სექტემბერი", "ოქტომბერი", "ნოემბერი", "დეკემბერი"],
  shortMonths: ["იან", "თებ", "მარ", "აპრ", "მაი", "ივნ", "ივლ", "აგვ", "სექ", "ოქტ", "ნოე", "დეკ"]
});

// Define chart for daily posts by group
const dailyPostsChart = Promise.all([dailyPosts, main_events]).then(([dailyData, events]) => {
    return Plot.plot({
      style: {fontFamily: "BPG Arial"},
      color: {
        domain: ["აზერბაიჯანულენოვანი სეგმენტი", "აჭარის სეგმენტი", "სომხურენოვანი სეგმენტი", "ქართულენოვანი სეგმენტი (აჭარის გარდა)"],
        range: ["#66c2a5", "#fc8d62", "#8da0cb", "#e5c494"],
        legend: true
      },
      marks: [
        Plot.barY(dailyPosts, {
          x: "P_Date",
          y: "n",
          fill: "monitoring_group",
          tip: true
        }),
        Plot.text(events, {
          // substract one day from the date to display the text on the left side of the event
          // x: d => new Date(d.date.setDate(d.date.getDate() - 0)),
          x: "date",
          y: () => Math.max(...dailyData.map(d => d.n)) * 1.05,
          text: "description",
          dy: -50,
          // dx: -10,
          rotate: -90,
          fill: "red",
          fontSize: 12,
          textAnchor: "middle"
        })
      ],
      x: {
        type: "band",
        tickFormat: localeKA.format("%d %b"),
        tickRotate: -90,
        label: "თარიღი: "
      },
      y: {
        label: "პოსტების რ-ნობა: "
      }
  })
});

```

```js
const dates = dailyPosts.map(d => new Date(d.P_Date));

const maxDate = new Date(Math.max(...dates));
const initialEndDate = new Date(maxDate); // Preserves original maxDate

const initialStartDate = new Date(initialEndDate);

initialStartDate.setMonth(initialStartDate.getMonth() - 1); // minus one month clearly

const endDate = Inputs.date({ value: initialEndDate, label: "აარჩიეთ საბოლოო თარიღი" });
const startDate = Inputs.date({ value: initialStartDate, label: "აარჩიეთ საწყისი თარიღი" });

const endDateActors = Inputs.date({ value: initialEndDate, label: "აარჩიეთ საბოლოო თარიღი" });
const startDateActors = Inputs.date({ value: initialStartDate, label: "აარჩიეთ საწყისი თარიღი" });

const endDateTopics = Inputs.date({ value: initialEndDate, label: "აარჩიეთ საბოლოო თარიღი" });

const startDateTopics = Inputs.date({ value: initialStartDate, label: "აარჩიეთ საწყისი თარიღი" });


const tabs = document.querySelectorAll('.tabs input[type="radio"]');

const tabs_actors = document.querySelectorAll('.tabs-actors input[type="radio"]');

const tabs_topics = document.querySelectorAll('.tabs-topics input[type="radio"]');

const panels = document.querySelectorAll('.tab-panels .tab-panel');

const panels_actors = document.querySelectorAll('.tab-panels-actors .tab-panel');

const panels_topics = document.querySelectorAll('.tab-panels-topics .tab-panel');


const narrativeTabMappings = {"All":"chart-all","აზერბაიჯანულენოვანი სეგმენტი":"chart-az","აჭარის სეგმენტი":"chart-adjara","სომხურენოვანი სეგმენტი":"chart-arm","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other"};

const actorsTabMappings = {"All":"chart-all-actors","აზერბაიჯანულენოვანი სეგმენტი":"chart-az-actors","აჭარის სეგმენტი":"chart-adjara-actors","სომხურენოვანი სეგმენტი":"chart-arm-actors","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-actors"};

const topicsTabMappings = {"All":"chart-all-topics","აზერბაიჯანულენოვანი სეგმენტი":"chart-az-topics","აჭარის სეგმენტი":"chart-adjara-topics","სომხურენოვანი სეგმენტი":"chart-arm-topics","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-topics"};

```

```js

function renderChart(group,id){
  let data=narratives.filter(d=>(group==='All'||d.monitoring_group===group)&&d.P_Date>=startDate.value&&d.P_Date<=endDate.value);
  if(data.length===0){
    document.getElementById(id).innerHTML='<p>დროის ამ მონაკვეთში მოცემული სეგმენტის შესაბამისი მონაცემები არ არსებობს</p>';
    return;
  }
  let agg=Object.entries(data.reduce((a,{narrative_text,n})=>(a[narrative_text]=(a[narrative_text]||0)+n,a),{})).sort(([,a],[,b])=>b-a).slice(0,7);
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
              tip: true
            }
        ),
        Plot.ruleX([0])
      ],
        width:700,
        height:400,
        marginLeft:150,
        x:{
          label: "რ-ნობა: "
        },
        y:{
            label: null,
            tickFormat: d => d.replace(/(.{10}\s)/g, '$1\n')
          }
    }
  ));
}

function renderChartActors(group, id) {
  let data_actors = actors.filter(d =>
    (group === 'All' || d.monitoring_group === group) &&
    d.P_Date >= startDateActors.value && d.P_Date <= endDateActors.value
  );

  if (data_actors.length === 0) {
    document.getElementById(id).innerHTML =
      '<p>დროის ამ მონაკვეთში მოცემული სეგმენტის შესაბამისი მონაცემები არ არსებობს</p>';
    return;
  }

  let agg_actors = Object.entries(
    data_actors.reduce((a, { actor_text, tone, n }) => {
      const key = `${actor_text}||${tone}`;
      a[key] = (a[key] || 0) + n;
      return a;
    }, {})
  ).map(([key, n]) => {
    const [actor_text, tone] = key.split("||");
    return { actor_text, tone, n };
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
  document.getElementById(id).appendChild(Plot.plot({
    style: { fontFamily: "BPG Arial" },
    color: {
      domain: ["დადებითი", "ნეიტრალური", "უარყოფითი"],
      range: ["#66c2a5", "#fc8d62", "#8da0cb"],
      legend: true
    },
    marks: [
      Plot.barX(agg_actors, {
        x: "n",
        y: "actor_text",
        fill: "tone",
        tip: true
      }),
      Plot.ruleX([0])
    ],
    width: 700,
    height: 400,
    marginLeft: 250,
      y:{
      label: null,
      tickFormat: d => d.replace(/(.{10}\s)/g, '$1\n')
    },
    x: { label: "რ-ნობა" }
  }));
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

  let data_topics = themesData.filter(d =>
    (group === 'All' || d.monitoring_group === group) &&
    d.P_Date >= startDateTopics.value &&
    d.P_Date <= endDateTopics.value
  );

  if (data_topics.length === 0) {
    container.innerHTML =
      '<p>დროის ამ მონაკვეთში მოცემული სეგმენტის შესაბამისი მონაცემები არ არსებობს</p>';
    return;
  }

  let agg_topics = Object.entries(
    data_topics.reduce((a, { topic_text, narrative_text, n }) => {
      const key = `${topic_text}||${narrative_text}`;
      a[key] = (a[key] || 0) + n;
      return a;
    }, {})
  ).map(([key, n]) => {
    const [topic_text, narrative_text] = key.split("||");
    return { topic_text, narrative_text, n };
  });

  const trmp = Treemap(agg_topics, {
    path: d => d.topic_text,
    value: d => d.n,
    group: d => d.topic_text,
    label: d => d.narrative_text.replace(/(.{10}\s)/g, '$1\n') + ". " + d.n.toLocaleString("en") + " შემთხვევა",
    width: 700,
    height: 500,
    zDomain: globalColorScale.domain(),   // Stable domain
    colors: globalColorScale.range()      // Stable colors
  });

  container.appendChild(trmp);

  const key = Swatches(globalColorScale);
  legendContainer.appendChild(key);
}



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


Promise.all([dailyPosts, narratives, actors, main_themes])
  .then(() => {
    updateCharts();
    updateChartsActors();
    updateChartsTopics();
  });

```


<div class="grid grid-cols-4">
  
  <div class="card grid-colspan-2 grid-rowspan-1">
    <h2>რელევანტური პოსტების რაოდენობა თარიღის მიხედვით</h2>
    <figure style="max-width: none;">
      <div style="display: flex; flex-direction: column; align-items: center;">
        <div style="display: flex; align-items: center;">
          ${dailyPostsChart}
        </div>
      </div>
    </figure>
  </div>

  <div class="card grid-colspan-2">
    <h2>შვიდი ყველაზე გავრცელებული ანტიდასავლური ნარატივი</h2>
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
      ${startDate}
      ${endDate}
    </div>
  </div>
</div>

<div class="grid grid-cols-4">
  <div class="card grid-colspan-2 grid-rowspan-1">
    <h2>შვიდი ყველაზე ხშირად ნახსენები აქტორი</h2>
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
    ${startDateActors}
    ${endDateActors}
  </div>

  <div class="card grid-colspan-2 grid-rowspan-1">
    <h2>შვიდი ყველაზე გავრცელებული თემა (დიაგრამის სანახავად წელი გადაიყვანე 2025-ზე)</h2>
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
    ${startDateTopics}
    ${endDateTopics}
    <div id="tab-key-topics" style="display: flex; flex-direction: column; align-items: center; margin-top: 20px;">
  </div>
</div>

</div>
