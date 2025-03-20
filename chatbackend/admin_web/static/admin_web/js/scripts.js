// Unique Visitors Chart
const uniqueVisitorsCtx = document.getElementById('uniqueVisitorsChart').getContext('2d');
const uniqueVisitorsChart = new Chart(uniqueVisitorsCtx, {
    type: 'line',
    data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [{
            label: 'Unique Visitors',
            data: [500, 800, 1200, 1000, 1500, 2000],
            borderColor: '#007bff',
            fill: false,
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                display: false,
            }
        }
    }
});

// Income Overview Chart
const incomeOverviewCtx = document.getElementById('incomeOverviewChart').getContext('2d');
const incomeOverviewChart = new Chart(incomeOverviewCtx, {
    type: 'bar',
    data: {
        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        datasets: [{
            label: 'Income',
            data: [2000, 3000, 2500, 4000],
            backgroundColor: '#007bff',
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                display: false,
            }
        }
    }
});