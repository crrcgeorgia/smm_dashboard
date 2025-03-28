---
theme: dashboard
title: Main Page
toc: false
style: custom-style.css
---

```js
// Import required libraries
import * as Inputs from "npm:@observablehq/inputs";
// import Swatches from "npm:@d3/color-legend";
// import {Treemap} from "/js/treemap.js"

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
    // P_Date: new Date(d.P_Date),
    n: +d.n  // ensure numeric type
  }))
);


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

const dates = narratives.map(d => new Date(d.P_Date));

const minDate = new Date(Math.min(...dates));

const maxDate = new Date(Math.max(...dates))

const endDate = Inputs.date({ value: new Date(maxDate), label: "აარჩიეთ საბოლოო თარიღი" });

const startDate = Inputs.date({ value: new Date(maxDate.setMonth(maxDate.getMonth() - 1)), label: "აარჩიეთ საწყისი თარიღი" });

const endDateActors = Inputs.date({ value: new Date(maxDate), label: "აარჩიეთ საბოლოო თარიღი" });

const startDateActors = Inputs.date({ value: new Date(maxDate.setMonth(maxDate.getMonth() - 1)), label: "აარჩიეთ საწყისი თარიღი" });

const tabs = document.querySelectorAll('.tabs input[type="radio"]');

const tabs_actors = document.querySelectorAll('.tabs-actors input[type="radio"]');

const panels = document.querySelectorAll('.tab-panels .tab-panel');

const panels_actors = document.querySelectorAll('.tab-panels-actors .tab-panel');

const narrativeTabMappings = {"All":"chart-all","აზერბაიჯანულენოვანი სეგმენტი":"chart-az","აჭარის სეგმენტი":"chart-adjara","სომხურენოვანი სეგმენტი":"chart-arm","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other"};

const actorsTabMappings = {"All":"chart-all-actors","აზერბაიჯანულენოვანი სეგმენტი":"chart-az-actors","აჭარის სეგმენტი":"chart-adjara-actors","სომხურენოვანი სეგმენტი":"chart-arm-actors","ქართულენოვანი სეგმენტი (აჭარის გარდა)":"chart-other-actors"};


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

Promise.all([dailyPosts,narratives,actors]).then(()=>{updateCharts(); updateChartsActors();});

// build a word cloud from main_themes, size sould be n, color should be theme

// themeCloud = Treemap(main_themes) {}

```

```js

// Copyright 2021-2023 Observable, Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/treemap
function Treemap(data, { // data is either tabular (array of objects) or hierarchy (nested objects)
    path, // as an alternative to id and parentId, returns an array identifier, imputing internal nodes
    id = Array.isArray(data) ? d => d.id : null, // if tabular data, given a d in data, returns a unique identifier (string)
    parentId = Array.isArray(data) ? d => d.parentId : null, // if tabular data, given a node d, returns its parent’s identifier
    children, // if hierarchical data, given a d in data, returns its children
    value, // given a node d, returns a quantitative value (for area encoding; null for count)
    sort = (a, b) => d3.descending(a.value, b.value), // how to sort nodes prior to layout
    label, // given a leaf node d, returns the name to display on the rectangle
    group, // given a leaf node d, returns a categorical value (for color encoding)
    title, // given a leaf node d, returns its hover text
    link, // given a leaf node d, its link (if any)
    linkTarget = "_blank", // the target attribute for links (if any)
    tile = d3.treemapBinary, // treemap strategy
    width = 640, // outer width, in pixels
    height = 400, // outer height, in pixels
    margin = 0, // shorthand for margins
    marginTop = margin, // top margin, in pixels
    marginRight = margin, // right margin, in pixels
    marginBottom = margin, // bottom margin, in pixels
    marginLeft = margin, // left margin, in pixels
    padding = 1, // shorthand for inner and outer padding
    paddingInner = padding, // to separate a node from its adjacent siblings
    paddingOuter = padding, // shorthand for top, right, bottom, and left padding
    paddingTop = paddingOuter, // to separate a node’s top edge from its children
    paddingRight = paddingOuter, // to separate a node’s right edge from its children
    paddingBottom = paddingOuter, // to separate a node’s bottom edge from its children
    paddingLeft = paddingOuter, // to separate a node’s left edge from its children
    round = true, // whether to round to exact pixels
    colors = d3.schemeTableau10, // array of colors
    zDomain, // array of values for the color scale
    fill = "#ccc", // fill for node rects (if no group color encoding)
    fillOpacity = group == null ? null : 0.6, // fill opacity for node rects
    stroke, // stroke for node rects
    strokeWidth, // stroke width for node rects
    strokeOpacity, // stroke opacity for node rects
    strokeLinejoin, // stroke line join for node rects
  } = {}) {
  
    // If id and parentId options are specified, or the path option, use d3.stratify
    // to convert tabular data to a hierarchy; otherwise we assume that the data is
    // specified as an object {children} with nested objects (a.k.a. the “flare.json”
    // format), and use d3.hierarchy.
  
    // We take special care of any node that has both a value and children, see
    // https://observablehq.com/@d3/treemap-parent-with-value.
    const stratify = data => (d3.stratify().path(path)(data)).each(node => {
      if (node.children?.length && node.data != null) {
        const child = new d3.Node(node.data);
        node.data = null;
        child.depth = node.depth + 1;
        child.height = 0;
        child.parent = node;
        child.id = node.id + "/";
        node.children.unshift(child);
      }
    });
    const root = path != null ? stratify(data)
        : id != null || parentId != null ? d3.stratify().id(id).parentId(parentId)(data)
        : d3.hierarchy(data, children);
  
    // Compute the values of internal nodes by aggregating from the leaves.
    value == null ? root.count() : root.sum(d => Math.max(0, d ? value(d) : null));
  
    // Prior to sorting, if a group channel is specified, construct an ordinal color scale.
    const leaves = root.leaves();
    const G = group == null ? null : leaves.map(d => group(d.data, d));
    if (zDomain === undefined) zDomain = G;
    zDomain = new d3.InternSet(zDomain);
    const color = group == null ? null : d3.scaleOrdinal(zDomain, colors);
  
    // Compute labels and titles.
    const L = label == null ? null : leaves.map(d => label(d.data, d));
    const T = title === undefined ? L : title == null ? null : leaves.map(d => title(d.data, d));
  
    // Sort the leaves (typically by descending value for a pleasing layout).
    if (sort != null) root.sort(sort);
  
    // Compute the treemap layout.
    d3.treemap()
        .tile(tile)
        .size([width - marginLeft - marginRight, height - marginTop - marginBottom])
        .paddingInner(paddingInner)
        .paddingTop(paddingTop)
        .paddingRight(paddingRight)
        .paddingBottom(paddingBottom)
        .paddingLeft(paddingLeft)
        .round(round)
      (root);
  
    const svg = d3.create("svg")
        .attr("viewBox", [-marginLeft, -marginTop, width, height])
        .attr("width", width)
        .attr("height", height)
        .attr("style", "max-width: 100%; height: auto; height: intrinsic;")
        .attr("font-family", "sans-serif")
        .attr("font-size", 10);
  
    const node = svg.selectAll("a")
      .data(leaves)
      .join("a")
        .attr("xlink:href", link == null ? null : (d, i) => link(d.data, d))
        .attr("target", link == null ? null : linkTarget)
        .attr("transform", d => `translate(${d.x0},${d.y0})`);
  
    node.append("rect")
        .attr("fill", color ? (d, i) => color(G[i]) : fill)
        .attr("fill-opacity", fillOpacity)
        .attr("stroke", stroke)
        .attr("stroke-width", strokeWidth)
        .attr("stroke-opacity", strokeOpacity)
        .attr("stroke-linejoin", strokeLinejoin)
        .attr("width", d => d.x1 - d.x0)
        .attr("height", d => d.y1 - d.y0);
  
    if (T) {
      node.append("title").text((d, i) => T[i]);
    }
  
    if (L) {
      // A unique identifier for clip paths (to avoid conflicts).
      const uid = `O-${Math.random().toString(16).slice(2)}`;
  
      node.append("clipPath")
         .attr("id", (d, i) => `${uid}-clip-${i}`)
       .append("rect")
         .attr("width", d => d.x1 - d.x0)
         .attr("height", d => d.y1 - d.y0);
  
      node.append("text")
          .attr("clip-path", (d, i) => `url(${new URL(`#${uid}-clip-${i}`, location)})`)
        .selectAll("tspan")
        .data((d, i) => `${L[i]}`.split(/\n/g))
        .join("tspan")
          .attr("x", 3)
          .attr("y", (d, i, D) => `${(i === D.length - 1) * 0.3 + 1.1 + i * 0.9}em`)
          .attr("fill-opacity", (d, i, D) => i === D.length - 1 ? 0.7 : null)
          .text(d => d);   
    }
  
    return Object.assign(svg.node(), {scales: {color}});
  }

// Copyright 2021, Observable Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/color-legend
function Swatches(color, {
  columns = null,
  format,
  unknown: formatUnknown,
  swatchSize = 15,
  swatchWidth = swatchSize,
  swatchHeight = swatchSize,
  marginLeft = 0
} = {}) {
  const id = `-swatches-${Math.random().toString(16).slice(2)}`;
  const unknown = formatUnknown == null ? undefined : color.unknown();
  const unknowns = unknown == null || unknown === d3.scaleImplicit ? [] : [unknown];
  const domain = color.domain().concat(unknowns);
  if (format === undefined) format = x => x === unknown ? formatUnknown : x;

  function entity(character) {
    return `&#${character.charCodeAt(0).toString()};`;
  }

  if (columns !== null) return htl.html`<div style="display: flex; align-items: center; margin-left: ${+marginLeft}px; min-height: 33px; font: 10px sans-serif;">
  <style>

.${id}-item {
  break-inside: avoid;
  display: flex;
  align-items: center;
  padding-bottom: 1px;
}

.${id}-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: calc(100% - ${+swatchWidth}px - 0.5em);
}

.${id}-swatch {
  width: ${+swatchWidth}px;
  height: ${+swatchHeight}px;
  margin: 0 0.5em 0 0;
}

  </style>
  <div style=${{width: "100%", columns}}>${domain.map(value => {
    const label = `${format(value)}`;
    return htl.html`<div class=${id}-item>
      <div class=${id}-swatch style=${{background: color(value)}}></div>
      <div class=${id}-label title=${label}>${label}</div>
    </div>`;
  })}
  </div>
</div>`;

  return htl.html`<div style="display: flex; align-items: center; min-height: 33px; margin-left: ${+marginLeft}px; font: 10px sans-serif;">
  <style>

.${id} {
  display: inline-flex;
  align-items: center;
  margin-right: 1em;
}

.${id}::before {
  content: "";
  width: ${+swatchWidth}px;
  height: ${+swatchHeight}px;
  margin-right: 0.5em;
  background: var(--color);
}

  </style>
  <div>${domain.map(value => htl.html`<span class="${id}" style="--color: ${color(value)}">${format(value)}</span>`)}</div>`;
}

const themeCloud = Treemap(main_themes, {
  path: d => d.topic_text, 
  value: d => d.n, // size of each node (file); null for internal nodes (folders)
  group: d => d.topic_text, // e.g., "animate" in "flare.animate.Easing"; for color
  label: d => d.narrative_text, // text to show on node
  // label: (d, n) => [...d.name.split(".").pop().split(/(?=[A-Z][a-z])/g), n.value.toLocaleString("en")].join("\n"),
  // title: (d, n) => `${d.name}\n${n.value.toLocaleString("en")}`, // text to show on hover
  // link: (d, n) => `https://github.com/prefuse/Flare/blob/master/flare/src${n.id}.as`,
  // tile, // e.g., d3.treemapBinary; set by input above
  width: 1152,
  height: 1152
})

const key = Swatches(themeCloud.scales.color)

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
    <h2>შვიდი ყველაზე გავრცელებული თემა (ფილტრი ჯერ არ მუშაობს)</h2>
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
    ${themeCloud}
    ${key}
  </div>
</div>

</div>
