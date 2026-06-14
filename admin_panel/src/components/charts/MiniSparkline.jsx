import ReactApexChart from 'react-apexcharts'

export default function MiniSparkline({ data = [5, 8, 6, 10, 9, 12] }) {
  const options = {
    chart: { toolbar: { show: false }, sparkline: { enabled: true } },
    stroke: { width: 2, curve: 'smooth' },
    colors: ['#4F46E5'],
    tooltip: { enabled: false },
  }

  return <ReactApexChart options={options} series={[{ data }]} type="line" height={40} />
}
