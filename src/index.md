---
theme: dashboard
title: Main Page
toc: false
---
```js
// Import required libraries
import * as Inputs from "npm:@observablehq/inputs";
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
```

```js
// Define chart for daily posts by group
const dailyPostsChart = Plot.plot({
  marks: [
    Plot.barY(dailyPosts, {
      x: "P_Date",
      y: "n",
      fill: "monitoring_group",
      tip: true
    })
  ],
  x: {
    label: "თარიღი:",
    tickFormat: localeKA.format("%B %Y"),  // Georgian Month Year format
    ticks: d3.timeMonth.every(1),
    //tickSpacing: 50  // Adjust spacing to reduce crowdedness
  },
  y: {label: "პოსტების რ-ნობა"},
  color: {legend: true},
});
```

```js

const dates = narratives.map(d => new Date(d.P_Date));
const minDate = new Date(Math.min(...dates));
const maxDate = new Date(Math.max(...dates))

```

```js
// Define date inputs
const endDate = Inputs.date({ value: new Date(maxDate), label: "აარჩიეთ საბოლოო თარიღი" });
const startDate = Inputs.date({ value: new Date(maxDate.setMonth(maxDate.getMonth() - 1)), label: "აარჩიეთ საწყისი თარიღი" });

// Define aggregatedNarrativesChart variable
let aggregatedNarrativesChart;

// Function to update the chart based on date inputs
function updateChart() {
  let filteredNarratives = [];
  if (startDate.value && endDate.value) {
    filteredNarratives = narratives.filter(d => 
      d.P_Date >= startDate.value && d.P_Date <= endDate.value
    );
  }

  const aggregatedTop5 = Object.entries(
    filteredNarratives.reduce((acc, { narrative_text, n }) => {
      acc[narrative_text] = (acc[narrative_text] || 0) + n;
      return acc;
    }, {})
  )
  .sort(([, a], [, b]) => b - a)
  .slice(0, 7);

  aggregatedNarrativesChart = Plot.plot({
    width: 700,  // Adjust width as needed
    height: 400, // Adjust height as needed
    marginLeft: 150,
    marks: [
      Plot.barX(aggregatedTop5, {
        x: ([,count]) => count,
        y: ([text]) => text,
        sort: {y: "x", reverse: true},
        tip: true
      }),
      Plot.ruleX([0])
    ],
    x: {label: "Frequency"},
    y: {
      label: null,
      tickFormat: d => {
        const words = d.split(' ');
        let wrapped = '';
        let line = '';
        for (const word of words) {
          if ((line + word).length > 10) {
            wrapped += line + '\n';
            line = '';
          }
          line += word + ' ';
        }
        return wrapped + line.trim();
      }
    },
    title: "ხუთი ყველაზე გავრცელებული ანტიდასავლური ნარატივი",
  });

  document.getElementById("aggregatedNarrativesChartDiv").innerHTML = "";
  document.getElementById("aggregatedNarrativesChartDiv").appendChild(aggregatedNarrativesChart);
}

// Update chart when dates change
startDate.addEventListener("input", updateChart);
endDate.addEventListener("input", updateChart);

// Wait for data to load and then display the initial chart
Promise.all([dailyPosts, narratives]).then(() => {
  updateChart();
});
```

<div class="grid grid-cols-4">
  <div class="card grid-colspan-2 grid-rowspan-2">
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
    <h2></h2>
    <div id="aggregatedNarrativesChartDiv">${aggregatedNarrativesChart}</div>
    ${startDate}
    ${endDate}
  </div>
  <div class="card grid-colspan-2">
    <h2></h2>
    
  </div>
  <div class="card grid-colspan-2" style="min-height: 160px;">
    <h2></h2>
    
  </div>
</div>
