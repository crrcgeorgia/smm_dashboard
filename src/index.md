---
theme: dashboard
title: Main Page
toc: false
style: custom-style.css
---

```js
// --- Imports & fonts ----------------------------------------------------------
import * as Inputs from "npm:@observablehq/inputs";
import {Treemap} from "./components/treemap.js";
import {Swatches} from "./components/swatches.js";

FileAttachment("fonts/bpg-arial-caps-webfont.ttf").url().then(url => {
  const style = document.createElement("style");
  style.textContent = `
    @font-face { font-family: 'BPG Arial Caps'; src: url(${url}); }
    h2 { font-family: 'BPG Arial Caps', sans-serif; }
  `;
  document.head.appendChild(style);
});

FileAttachment("fonts/bpg-arial-webfont.ttf").url().then(url => {
  const style = document.createElement("style");
  style.textContent = `
    @font-face { font-family: 'BPG Arial'; src: url(${url}); }
    body, label, span, p { font-family: 'BPG Arial', sans-serif; }
    p { font-size: 10px; font-style: italic; }
  `;
  document.head.appendChild(style);
});

```

```js
// --- Data --------------------------------------------------------------------
const dailyPosts = FileAttachment("data/daily_posts_by_group.csv")
  .csv({ typed: true })
  .then(rows => rows.map(d => ({ ...d, P_Date: new Date(d.P_Date), n: +d.n })));

const narratives = FileAttachment("data/narratives_all.csv")
  .csv({ typed: true })
  .then(rows => rows.map(d => ({ ...d, P_Date: new Date(d.P_Date), n: +d.n })));

const actors = FileAttachment("data/actors_all.csv")
  .csv({ typed: true })
  .then(rows => rows.map(d => ({ ...d, P_Date: new Date(d.P_Date), n: +d.n })));

const main_events = FileAttachment("data/events_all.csv")
  .csv({ typed: true })
  .then(rows => rows.map(d => ({ ...d, date: new Date(d.date) })));

const main_themes = FileAttachment("data/themes_all.csv")
  .csv({ typed: true })
  .then(rows => rows.map(d => ({ ...d, P_Date: new Date(d.P_Date), n: +d.n })));

const topic_colors_data = await FileAttachment("data/topic_colors.json").json();
const translations = await FileAttachment("data/translations.json").json();

```



```js
// --- Globals & helpers -------------------------------------------------------
let currentLang = "ka";

const d3Locales = {
  ka: d3.timeFormatLocale({
    dateTime: "%A, %e %B %Y %X",
    date: "%d/%m/%Y",
    time: "%H:%M:%S",
    periods: ["AM","PM"],
    days: ["კვირა","ორშაბათი","სამშაბათი","ოთხშაბათი","ხუთშაბათი","პარასკევი","შაბათი"],
    shortDays: ["კვ","ორ","სმ","ოთ","ხთ","პრ","შბ"],
    months: ["იანვარი","თებერვალი","მარტი","აპრილი","მაისი","ივნისი","ივლისი","აგვისტო","სექტემბერი","ოქტომბერი","ნოემბერი","დეკემბერი"],
    shortMonths: ["იან","თებ","მარ","აპრ","მაი","ივნ","ივლ","აგვ","სექ","ოქტ","ნოე","დეკ"]
  }),
  en: d3.timeFormatLocale({
    dateTime: "%A, %e %B %Y %X",
    date: "%m/%d/%Y",
    time: "%H:%M:%S",
    periods: ["AM","PM"],
    days: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
    shortDays: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],
    months: ["January","February","March","April","May","June","July","August","September","October","November","December"],
    shortMonths: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
  })
};
const getLocale = () => d3Locales[currentLang];

const t = (path, fallback="") => {
  const segs = path.split(".");
  let ref = translations[currentLang];
  for (const s of segs) {
    if (!ref || !(s in ref)) return fallback;
    ref = ref[s];
  }
  return ref ?? fallback;
};

// Stable color scales
const toneColorScale = d3.scaleOrdinal()
  .domain(["positive","neutral","negative"])
  .range(["#66c2a5","#fc8d62","#8da0cb"]);

const groupColorScale = d3.scaleOrdinal()
  .domain(["positive","neutral","negative"])
  .range(["#66c2a5","#fc8d62","#8da0cb"]);

const topicColorScale = d3.scaleOrdinal()
  .domain(topic_colors_data.map(d => d.topic_id))
  .range(topic_colors_data.map(d => d.color));

// Top-K helper
function topKBySum(data, keyFn, valueFn, k = 7) {
  const totals = d3.rollup(data, v => d3.sum(v, valueFn), keyFn);
  return Array.from(totals).sort((a,b)=>b[1]-a[1]).slice(0,k).map(d=>d[0]);
}

// Date-range factory (returns {start, end} Inputs)
async function makeRange(monthsOffset = -1) {
  const rows = await dailyPosts;
  const dates = rows.map(d => d.P_Date);
  const max = new Date(Math.max(...dates));
  const start = new Date(max);
  start.setMonth(start.getMonth() + monthsOffset);
  return {
    start: Inputs.date({ value: start }),
    end: Inputs.date({ value: max })
  };
}

// Generic tab wiring
function wireTabs({tabsSelector, panelsSelector, onChange}) {
  const tabs = document.querySelectorAll(`${tabsSelector} input[type="radio"]`);
  const panels = document.querySelectorAll(`${panelsSelector} .tab-panel`);
  tabs.forEach(t => t.addEventListener("change", () => {
    panels.forEach(p => p.style.display = "none");
    document.getElementById(`${t.id}-panel`).style.display = "block";
    onChange();
  }));
}

// Generic legend builder
function mountLegend(containerId, ids, labelFn, colorFn) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";
  const scale = d3.scaleOrdinal().domain(ids.map(labelFn)).range(ids.map(colorFn));
  container.appendChild(Swatches(scale));
}

// --- Date ranges (daily, narratives, actors, topics) -------------------------
const {start: startDateDaily, end: endDateDaily} = await makeRange(-1);
const {start: startDateNarr,  end: endDateNarr } = await makeRange(-1);
const {start: startDateActors, end: endDateActors} = await makeRange(-1);
const {start: startDateTopics, end: endDateTopics} = await makeRange(-1);

// --- Renderers ---------------------------------------------------------------

// Daily posts: filtered by its own range; weekly ticks + monthly labels
async function renderDailyPostsChart() {
  const [dailyDataRaw, rawEvents] = await Promise.all([dailyPosts, main_events]);
  const locale = getLocale();
  const fmtMonth = locale.format("%b");
  const fmtFull  = locale.format("%d %B %Y");

  const evTr = t("events", {}), segTr = t("segments", {});
  const s = startDateDaily.value, e = endDateDaily.value;

  const dailyData = dailyDataRaw
    .filter(d => d.P_Date >= s && d.P_Date <= e)
    .map(d => ({ ...d, monitoring_group: segTr?.[d.monitoring_group_id] ?? d.monitoring_group }));

  const events = rawEvents
    .map(ev => ({...ev, description: evTr?.[ev.event_id] ?? ev.description}))
    .filter(ev => ev.date >= s && ev.date <= e);

  const ymax = Math.max(1, ...dailyData.map(d => d.n));
  const xMin = d3.utcDay.floor(d3.min(dailyData, d => d.P_Date));
  const xMax = d3.utcDay.offset(d3.utcDay.ceil(d3.max(dailyData, d => d.P_Date)), 1);

  return Plot.plot({
    style: { fontFamily: "BPG Arial" },
    marginTop: 70, // more space for labels
    color: {
      domain: Array.from(new Set(dailyData.map(d => d.monitoring_group))),
      range: ["#ffffb3","#bc80bd","#b3de69","#80b1d3"],
      legend: true
    },
    marks: [
      // daily columns
      Plot.rectY(dailyData, {
        x: "P_Date",
        interval: d3.timeDay,
        y: "n",
        fill: "monitoring_group",
        tip: true,
        title: d => [
          `${t("daily_tooltip_mongroup")}: ${d.monitoring_group}`,
          `${t("daily_tooltip_date")}: ${fmtFull(d.P_Date)}`,
          `${t("daily_tooltip_posts")}: ${d.n}`
        ].join("\n")
      }),

      // month labels at bottom
      Plot.axisX({ anchor: "bottom", ticks: d3.timeMonth.every(1), tickFormat: fmtMonth }),

      // weekly grid
      Plot.ruleX(d3.utcMonday.range(xMin, xMax), { strokeOpacity: 0.08 }),

      // connector hairlines (optional but helpful)
      Plot.ruleX(events, { x: "date", y1: ymax * 1.0, y2: ymax * 1.06, stroke: "red", strokeOpacity: 0.35 }),

      // event labels with halo + stagger to reduce collisions
       Plot.dot(events, {
         x: "date",
         y: () => ymax * 2.04,
         r: 3.5,
         fill: "red",
         tip: true,
         title: d => d.description
       }),
    Plot.ruleX(events, { x: "date", y1: 0, y2: ymax * 2.04, stroke: "red", strokeOpacity: 0.3 })
    ],
    x: {
      type: "time",
      ticks: d3.timeWeek.every(1),
      tickFormat: locale.format("%d %b"),
      tickRotate: -90
    },
    y: { label: t("y_axis_label_daily_posts","პოსტების რ-ნობა: ") }
  });
}


// Narratives (bar chart, top 7)
async function renderChartNarratives(group, containerId) {
  const data = (await narratives).filter(d =>
    (group === "All" || d.monitoring_group === group) &&
    d.P_Date >= startDateNarr.value &&
    d.P_Date <= endDateNarr.value
  );

  if (!data.length) {
    document.getElementById(containerId).innerHTML = `<p>${t("no_data")}</p>`;
    return;
  }

  const nTr = t("narratives",{});
  const dataTranslated = data.map(d => ({ ...d, narrative_text: nTr?.[d.narrative_id] ?? d.narrative_text }));
  const agg = Object.entries(
    dataTranslated.reduce((a,{narrative_text,n}) => (a[narrative_text]=(a[narrative_text]||0)+n, a), {})
  ).sort(([,a],[,b]) => b-a).slice(0,7);

  const el = document.getElementById(containerId);
  el.innerHTML = "";
  el.appendChild(Plot.plot({
    style: { fontFamily: "BPG Arial" },
    marks: [
      Plot.barX(agg, {
        x: d=>d[1],
        y: d=>d[0],
        sort: { y:"x", reverse:true },
        fill: "#a6cee3",
        tip: true,
        title: d => [
          `${t("narrative_tooltip_label", translations[currentLang].topic_name)}: ${d[0]}`,
          `${t("narrative_count_axis_text")}: ${d[1]}`
        ].join("\n")
      }),
      Plot.ruleX([0])
    ],
    width: 700, height: 400, marginLeft: 150,
    x: { label: t("narrative_count_axis_text","შემთხვევების რ-ნობა ") },
    y: { label: null, tickFormat: d => d.replace(/(.{10}\s)/g, "$1\n") }
  }));
}

// Actors (stack by tone, stable colors, custom legend)
async function renderChartActors(group, containerId) {
  const data = (await actors).filter(d =>
    (group === "All" || d.monitoring_group === group) &&
    d.P_Date >= startDateActors.value &&
    d.P_Date <= endDateActors.value
  );

  const el = document.getElementById(containerId);
  if (!data.length) {
    el.innerHTML = `<p>${t("no_data")}</p>`;
    return;
  }

  const aTr = t("actors", {});     // {actor_id: translated name}
  const toneTr = t("tone", {});    // {tone_id: translated label}

  // Translate once and keep named fields
  const rows = data.map(d => ({
    actor_id: d.actor_id,
    actor_text: aTr?.[d.actor_id] ?? d.actor_text,
    tone_id: d.tone_id,
    tone_label: toneTr?.[d.tone_id] ?? d.tone,
    n: d.n
  }));

  // Aggregate into objects so tooltips can reference fields
  let agg = Object.values(
    rows.reduce((acc, d) => {
      const key = `${d.actor_text}||${d.tone_id}`; // tone_label implied by tone_id
      if (!acc[key]) acc[key] = {
        actor_text: d.actor_text,
        tone_id: d.tone_id,
        tone_label: d.tone_label,
        n: 0
      };
      acc[key].n += d.n;
      return acc;
    }, {})
  );

  // Pick top 7 actors by total n (across tones)
  const totals = agg.reduce((a, d) => ((a[d.actor_text] = (a[d.actor_text] || 0) + d.n), a), {});
  const topActors = Object.entries(totals)
  .sort(([, a], [, b]) => b - a) // Sort by total descending
  .slice(0, 7)                   // Keep top 7
  .map(([actor]) => actor);      // Extract actor names

// Filter agg to only include top 7
agg = agg.filter(d => topActors.includes(d.actor_text))
    .sort((a, b) => totals[b.actor_text] - totals[a.actor_text]);

  el.innerHTML = "";
  const chart = Plot.plot({
    style: { fontFamily: "BPG Arial" },
    color: {
      domain: toneColorScale.domain(),   // ["positive","neutral","negative"]
      range: toneColorScale.range(),     // fixed colors
      legend: false
    },
    marks: [
      Plot.barX(agg, {
        x: "n",
        y: "actor_text",
        fill: "tone_id",                 // use stable internal ID for color
        tip: true,
        sort: {y: "-x"},
        title: d => [
          `${t("actors_tooltip_actor","Actor")}: ${d.actor_text}`,
          `${t("actors_tooltip_tone","Tone")}: ${d.tone_label}`,
          `${t("daily_tooltip_posts","Posts")}: ${d.n.toLocaleString(currentLang)}`
        ].join("\n")
      }),
      Plot.ruleX([0])
    ],
    width: 700,
    height: 400,
    marginLeft: 250,
    y: { label: null, tickFormat: s => s.replace(/(.{10}\s)/g, "$1\n") },
    x: { label: t("actor_count_axis_text") }
  });
  el.appendChild(chart);

  // Custom legend with translated tone labels (colors from toneColorScale)
  const legendId = `${containerId}-legend`;
  let legend = document.getElementById(legendId);
  if (!legend) {
    legend = document.createElement("div");
    legend.id = legendId;
    legend.style.marginTop = "10px";
    el.appendChild(legend);
  } else {
    legend.innerHTML = "";
  }

  const legendScale = d3.scaleOrdinal()
    .domain(toneColorScale.domain().map(id => toneTr?.[id] ?? id)) // translated labels
    .range(toneColorScale.domain().map(id => toneColorScale(id)));  // stable colors

  legend.appendChild(Swatches(legendScale));
}

// Topics (Treemap of top 7 topics, stable color by topic_id, translated legend)
async function renderChartTopics(group, containerId) {
  const themes = await main_themes;

  const data = themes.filter(d =>
    (group === "All" || d.monitoring_group === group) &&
    d.P_Date >= startDateTopics.value &&
    d.P_Date <= endDateTopics.value
  );

  const el = document.getElementById(containerId);
  if (!data.length) {
    el.innerHTML = `<p>${t("no_data")}</p>`;
    return;
  }

  const nTr = t("narratives",{});
  const dataTr = data.map(d => ({
    ...d,
    narrative_text: nTr?.[d.narrative_id] ?? d.narrative_text
  }));

  // top 7 topics by total n
  const topTopicIDs = topKBySum(dataTr, d => +d.topic_id, d => d.n, 7);

  // nest into { name: topic_id, children: [{name: narrative_id, description, value}] }
  const nested_topics = Object.values(
    dataTr.reduce((acc, { topic_id, narrative_id, narrative_text, n }) => {
      topic_id = +topic_id; narrative_id = +narrative_id;
      if (!topTopicIDs.includes(topic_id)) return acc;

      if (!acc[topic_id]) acc[topic_id] = { name: topic_id, children: [] };
      const found = acc[topic_id].children.find(d => d.name === narrative_id);
      if (found) found.value += n;
      else acc[topic_id].children.push({ name: narrative_id, description: narrative_text, value: n });
      return acc;
    }, {})
  );

  const tree = { name: "topic", children: nested_topics };

  el.innerHTML = "";
  const treemap = Treemap(tree, {
    // color by top-level topic_id (stable)
    group: (d, n) => n.ancestors().slice(-2)[0].data.name,
    value: d => d.value,
    label: (d, n) => `${(d.description || "").replace(/(.{10}\s)/g, "$1\n")}\n${n.value.toLocaleString(currentLang)} ${t("events_count_label","")}`,
    width: 700,
    height: 500,
    zDomain: topicColorScale.domain(),
    colors: topicColorScale.range()
  });
  el.appendChild(treemap);

  // Legend for only top topics, translated labels (keep stable colors)
  const legendId = `${containerId}-legend`;
  if (!document.getElementById(legendId)) {
    const div = document.createElement("div");
    div.id = legendId;
    div.style.marginTop = "10px";
    el.appendChild(div);
  }
  mountLegend(
    legendId,
    topTopicIDs,
    id => t(`topics.${id}`, id),
    id => topicColorScale(id)
  );
}

// --- UI wiring & text updates ------------------------------------------------
function getActiveTab(tabsSelector) {
  const selected = document.querySelector(`${tabsSelector} input[type="radio"]:checked`);
  return selected ? selected.value : "All";
}

function updateStaticTexts() {
  const ids = [
    ["title_daily_posts","title_daily_posts"],
    ["title_narratives","title_narratives"],
    ["title_actors","title_actors"],
    ["title_topics","title_topics"],
    ["smallnote","smallnote"],
    ["tooltip_narrative","tooltip_narrative"],
    ["tooltip_n_posts","tooltip_n_posts"],
    ["tooltip_actors","tooltip_actors"],
    ["tooltip_topics","tooltip_topics"],
    ["dash_title","dash_title"],
    ["start-date-container","date_picker_start"],
    ["end-date-container","date_picker_end"],
    ["start-date-container-actors","date_picker_start"],
    ["end-date-container-actors","date_picker_end"],
    ["start-date-container-topics","date_picker_start"],
    ["end-date-container-topics","date_picker_end"],
    ["start-date-container-daily","date_picker_start"],
    ["end-date-container-daily","date_picker_end"]
  ];
  ids.forEach(([id, key]) => {
    const el = document.getElementById(id);
    if (el) el.innerText = t(key, el?.innerText || "");
  });

  const tabKeys = ["all","az","adjara","arm","other"];
  document.querySelectorAll(".tabs label").forEach((el,i)=> el.innerText = t(`segments.${tabKeys[i]}`, el.innerText));
  document.querySelectorAll(".tabs-actors label").forEach((el,i)=> el.innerText = t(`segments.${tabKeys[i]}`, el.innerText));
  document.querySelectorAll(".tabs-topics label").forEach((el,i)=> el.innerText = t(`segments.${tabKeys[i]}`, el.innerText));
}

function updateChartsNarratives() {
  const group = getActiveTab(".tabs");
  const map = {
    "All":"chart-all",
    "აზერბაიჯანულენოვანი სეგმენტი":"chart-az",
    "აჭარის სეგმენტი":"chart-adjara",
    "სომხურენოვანი სეგმენტი":"chart-arm",
    "ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other"
  };
  Object.entries(map).forEach(([g,id]) => renderChartNarratives(g,id));
}

function updateChartsActors() {
  const map = {
    "All":"chart-all-actors",
    "აზერბაიჯანულენოვანი სეგმენტი":"chart-az-actors",
    "აჭარის სეგმენტი":"chart-adjara-actors",
    "სომხურენოვანი სეგმენტი":"chart-arm-actors",
    "ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-actors"
  };
  Object.entries(map).forEach(([g,id]) => renderChartActors(g,id));
}

function updateChartsTopics() {
  const map = {
    "All":"chart-all-topics",
    "აზერბაიჯანულენოვანი სეგმენტი":"chart-az-topics",
    "აჭარის სეგმენტი":"chart-adjara-topics",
    "სომხურენოვანი სეგმენტი":"chart-arm-topics",
    "ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-topics"
  };
  const active = getActiveTab(".tabs-topics");
  renderChartTopics(active, map[active]);
}

function rerenderAll() {
  updateStaticTexts();
  updateChartsNarratives();
  updateChartsActors();
  updateChartsTopics();
  renderDailyPostsChart().then(chart => {
    const c = document.getElementById("daily-posts-chart-container");
    c.innerHTML = ""; c.appendChild(chart);
  });
}

// Wire tabs
wireTabs({ tabsSelector: ".tabs", panelsSelector: ".tab-panels", onChange: updateChartsNarratives });
wireTabs({ tabsSelector: ".tabs-actors", panelsSelector: ".tab-panels-actors", onChange: updateChartsActors });
wireTabs({ tabsSelector: ".tabs-topics", panelsSelector: ".tab-panels-topics", onChange: updateChartsTopics });

// Wire date inputs
[startDateNarr, endDateNarr].forEach(x => x.addEventListener("input", updateChartsNarratives));
[startDateActors, endDateActors].forEach(x => x.addEventListener("input", updateChartsActors));
[startDateTopics, endDateTopics].forEach(x => x.addEventListener("input", updateChartsTopics));
[startDateDaily, endDateDaily].forEach(x => x.addEventListener("input", () => {
  renderDailyPostsChart().then(chart => {
    const c = document.getElementById("daily-posts-chart-container");
    c.innerHTML = ""; c.appendChild(chart);
  });
}));

// Language switcher
document.getElementById("languageSwitcher").addEventListener("change", e => {
  currentLang = e.target.value;
  rerenderAll();
});

// Initial render after data
Promise.all([dailyPosts, narratives, actors, main_themes]).then(rerenderAll);

```
<!-- --- Language switcher & title ------------------------------------------- -->
<select id="languageSwitcher">
  <option value="ka">ქართული</option>
  <option value="en">English</option>
</select>

<div id="dash_title"></div>

<!-- --- Daily posts ---------------------------------------------------------- -->
<div class="grid grid-cols-4">
  <div class="card grid-colspan-2 grid-rowspan-1">
    <div class="tooltip-container">
      <h2 id="title_daily_posts"></h2>
      <span class="tooltip-text" id="tooltip_n_posts"></span>
    </div>
    <figure style="max-width: none;">
      <div style="display:flex;flex-direction:column;align-items:center;">
        <div style="display:flex;align-items:center;">
          <div id="daily-posts-chart-container"></div>
        </div>
      </div>
      <table>
      <tbody>
        <tr>
          <td id="start-date-container-daily"></td>
          <td>${startDateDaily}</td>
        </tr>
        <tr>
          <td id="end-date-container-daily"></td>
          <td>${endDateDaily}</td>
        </tr>
      </tbody>
    </table>
    </figure>
  </div>

  <!-- --- Narratives --------------------------------------------------------- -->
  <div class="card grid-colspan-2">
    <div class="tooltip-container">
      <h2 id="title_narratives"></h2>
      <span class="tooltip-text" id="tooltip_narrative"></span>
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
        <tr>
          <td id="start-date-container"></td>
          <td>${startDateNarr}</td>
        </tr>
        <tr>
          <td id="end-date-container"></td>
          <td>${endDateNarr}</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>

<!-- --- Actors & Topics ------------------------------------------------------ -->
<div class="grid grid-cols-4">
  <!-- Actors -->
  <div class="card grid-colspan-2 grid-rowspan-1">
    <div class="tooltip-container">
      <h2 id="title_actors"></h2>
      <span class="tooltip-text" id="tooltip_actors"></span>
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
        <tr>
          <td id="start-date-container-actors"></td>
          <td>${startDateActors}</td>
        </tr>
        <tr>
          <td id="end-date-container-actors"></td>
          <td>${endDateActors}</td>
        </tr>
      </tbody>
    </table>
  </div>

  <!-- Topics -->
  <div class="card grid-colspan-2 grid-rowspan-1">
    <div class="tooltip-container">
      <h2 id="title_topics"></h2>
      <span class="tooltip-text" id="tooltip_topics"></span>
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
        <tr>
          <td id="start-date-container-topics"></td>
          <td>${startDateTopics}</td>
        </tr>
        <tr>
          <td id="end-date-container-topics"></td>
          <td>${endDateTopics}</td>
        </tr>
      </tbody>
    </table>
    <div id="tab-key-topics" style="display:flex;flex-direction:column;align-items:center;margin-top:20px;"></div>
  </div>
</div>

<div id="smallnote"></div>
