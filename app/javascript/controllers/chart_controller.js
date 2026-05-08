import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initializeChart()
  }

  initializeChart() {
    const ctx = document.getElementById('myAreaChart')
    if (!ctx) return

    new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
        datasets: [{
          label: '売上',
          data: [1200000, 1900000, 1500000, 1800000, 2100000, 2400000, 2200000, 2500000, 2300000, 2600000, 2400000, 2800000],
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1,
          fill: true,
          backgroundColor: 'rgba(75, 192, 192, 0.2)'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return '¥' + value.toLocaleString()
              }
            }
          }
        }
      }
    })
  }
} 