---
theme: dashboard
title: Main Page
toc: false
style: custom-style.css
---

```js
// Import required libraries
import * as Inputs from "npm:@observablehq/inputs";


// Load the custom font

FileAttachment("fonts/bpg-arial-caps-webfont.ttf").url().then(url => {
  const style = document.createElement('style');
  style.textContent = `
  @font-face {
    font-family: 'BPG Arial Caps';
    src: url(${url});
  }
  h2 {
    font-family: 'BPG Arial Caps', sans-serif;
  }`;
  document.head.appendChild(style);
});


FileAttachment("fonts/bpg-arial-webfont.ttf").url().then(url => {
  const style = document.createElement('style');
  style.textContent = `
  @font-face {
    font-family: 'BPG Arial';
    src: url(${url});
  }
  body {
    font-family: 'BPG Arial', sans-serif;
  }
  
  label {
    font-family: 'BPG Arial', sans-serif;
    font-size: 10px;
  }
  span {
    font-family: 'BPG Arial', sans-serif;
  }

  p {
    font-family: 'BPG Arial', sans-serif;
    font-size: 10px;
    font-style: italic
  }
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
const dailyPostsChart = Plot.plot({
  style: {fontFamily: "BPG Arial"},
  color: {
    domain: ["აზერბაიჯანულენოვანი სეგმენტი", "აჭარის სეგმენტი", "სომხურენოვანი სეგმენტი", "სხვა"],
    range: ["#66c2a5", "#fc8d62", "#8da0cb", "#e5c494"],
    legend: true
  },
  marks: [
    Plot.barY(dailyPosts, {
      x: "P_Date",
      y: "n",
      fill: "monitoring_group",
      tip: true
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
});

```

```js

const dates = narratives.map(d => new Date(d.P_Date));

const minDate = new Date(Math.min(...dates));

const maxDate = new Date(Math.max(...dates))

const endDate = Inputs.date({ value: new Date(maxDate), label: "აარჩიეთ საბოლოო თარიღი" });

const startDate = Inputs.date({ value: new Date(maxDate.setMonth(maxDate.getMonth() - 1)), label: "აარჩიეთ საწყისი თარიღი" });

const tabs = document.querySelectorAll('.tabs input[type="radio"]');
const panels = document.querySelectorAll('.tab-panels .tab-panel');

const tabMappings = {
  "All": "chart-all",
  "აზერბაიჯანულენოვანი სეგმენტი": "chart-az",
  "აჭარის სეგმენტი": "chart-adjara",
  "სომხურენოვანი სეგმენტი": "chart-arm",
  "სხვა": "chart-other"
};

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

function updateCharts(){Object.entries(tabMappings).forEach(([g,id])=>renderChart(g,id));}
tabs.forEach(t=>t.addEventListener('change',()=>{panels.forEach(p=>p.style.display='none');document.getElementById(`${t.id}-panel`).style.display='block';updateCharts();}));

[startDate,endDate].forEach(e=>e.addEventListener('input',updateCharts));

Promise.all([dailyPosts,narratives]).then(updateCharts);



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
    <h2>ხუთი ყველაზე გავრცელებული ანტიდასავლური ნარატივი</h2>
        <div class="tabs">
          <input type="radio" name="tabset" id="tab-full-data" value="All" checked>
          <label for="tab-full-data">სრული მონაცემები</label>
          <input type="radio" name="tabset" id="tab2" value="აზერბაიჯანულენოვანი სეგმენტი">
          <label for="tab2">აზერბაიჯანულენოვანი სეგმენტი</label>
          <input type="radio" name="tabset" id="tab3" value="აჭარის სეგმენტი">
          <label for="tab3">აჭარის სეგმენტი</label>
          <input type="radio" name="tabset" id="tab4" value="სომხურენოვანი სეგმენტი">
          <label for="tab4">სომხურენოვანი სეგმენტი</label>
          <input type="radio" name="tabset" id="tab5" value="სხვა">
          <label for="tab5">სხვა</label>
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
