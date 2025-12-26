import PropTypes from 'prop-types';
import { useState, useEffect } from 'react';

// material-ui
import { useTheme } from '@mui/material/styles';

// third-party
import ReactApexChart from 'react-apexcharts';

// chart options
const areaChartOptions = {
  chart: {
    type: 'area',
    toolbar: {
      show: false
    }
  },
  dataLabels: {
    enabled: false
  },
  stroke: {
    width: 2,
    curve: 'smooth'
  },
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      type: 'vertical',
      inverseColors: false,
      opacityFrom: 0.5,
      opacityTo: 0
    }
  },
  grid: {
    strokeDashArray: 4
  }
};

// ==============================|| CHART - WEEKLY ANALYTICS ||============================== //

export default function WeeklyAnalyticsChart({ data, categories }) {
  const theme = useTheme();

  const mode = theme.palette.mode;
  const { primary, secondary } = theme.palette.text;
  const line = theme.palette.divider;

  const [options, setOptions] = useState(areaChartOptions);

  useEffect(() => {
    setOptions((prevState) => ({
      ...prevState,
      colors: [theme.palette.primary.main, theme.palette.warning.main],
      xaxis: {
        categories: categories,
        labels: {
          style: {
            colors: secondary
          }
        },
        axisBorder: {
          show: false,
          color: line
        },
        axisTicks: {
          show: false
        }
      },
      yaxis: {
        labels: {
          style: {
            colors: [secondary]
          }
        }
      },
      grid: {
        borderColor: line
      },
      theme: {
        mode: 'light'
      }
    }));
  }, [mode, primary, secondary, line, theme, categories]);

  return <ReactApexChart options={options} series={data} type="area" height={284} />;
}

WeeklyAnalyticsChart.propTypes = {
  data: PropTypes.array,
  categories: PropTypes.array
};
