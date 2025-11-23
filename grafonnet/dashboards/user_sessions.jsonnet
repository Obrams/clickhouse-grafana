local grafana = import '../lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local tablePanel = grafana.tablePanel;
local heatmapPanel = grafana.heatmapPanel;

// Настройки datasource
local datasource = 'ClickHouse';
local datasourceUid = 'clickhouse_ds';

// Создаем дашборд
dashboard.new(
  'User Sessions Analytics (Grafonnet)',
  tags=['grafonnet', 'sessions', 'users', 'analytics'],
  editable=true,
  time_from='now-24h',
  time_to='now',
  refresh='1m',
  timezone='browser',
  uid='grafonnet-user-sessions',
)

// Средняя длительность сессии
.addPanel(
  statPanel.new(
    'Average Session Duration',
    datasource=datasource,
    unit='m',
    colorMode='background',
    graphMode='area',
    reducerFunction='lastNotNull',
  )
  .addTarget({
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    refId: 'A',
    rawSql: |||
      SELECT 
        now() as time,
        round(avg(duration_minutes), 2) as value
      FROM user_sessions
      WHERE start_time >= now() - INTERVAL 24 HOUR
    |||,
    format: 'table',
  })
  .addThresholds([
    { value: null, color: 'red' },
    { value: 5, color: 'yellow' },
    { value: 15, color: 'green' },
  ])
  { gridPos: { x: 0, y: 0, w: 6, h: 6 } },
)

// Всего сессий
.addPanel(
  statPanel.new(
    'Total Sessions (24h)',
    datasource=datasource,
    colorMode='background',
    graphMode='area',
    reducerFunction='lastNotNull',
  )
  .addTarget({
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    refId: 'A',
    rawSql: |||
      SELECT 
        now() as time,
        count() as value
      FROM user_sessions
      WHERE start_time >= now() - INTERVAL 24 HOUR
    |||,
    format: 'table',
  })
  { gridPos: { x: 6, y: 0, w: 6, h: 6 } },
)

// Средний просмотр страниц
.addPanel(
  statPanel.new(
    'Avg Pages per Session',
    datasource=datasource,
    colorMode='value',
    graphMode='area',
    reducerFunction='lastNotNull',
  )
  .addTarget({
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    refId: 'A',
    rawSql: |||
      SELECT 
        now() as time,
        round(avg(pages_visited), 2) as value
      FROM user_sessions
      WHERE start_time >= now() - INTERVAL 24 HOUR
    |||,
    format: 'table',
  })
  { gridPos: { x: 12, y: 0, w: 6, h: 6 } },
)

// Активных пользователей
.addPanel(
  statPanel.new(
    'Unique Users',
    datasource=datasource,
    colorMode='background',
    graphMode='none',
    reducerFunction='lastNotNull',
  )
  .addTarget({
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    refId: 'A',
    rawSql: |||
      SELECT 
        now() as time,
        count(DISTINCT user_id) as value
      FROM user_sessions
      WHERE start_time >= now() - INTERVAL 24 HOUR
    |||,
    format: 'table',
  })
  { gridPos: { x: 18, y: 0, w: 6, h: 6 } },
)

// Sessions по времени (Time Series)
.addPanel(
  {
    type: 'timeseries',
    title: 'Sessions Over Time',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 0, y: 6, w: 12, h: 8 },
    fieldConfig: {
      defaults: {
        color: { mode: 'palette-classic' },
        custom: {
          lineWidth: 2,
          fillOpacity: 20,
          showPoints: 'never',
          spanNulls: true,
          lineInterpolation: 'smooth',
        },
        unit: 'short',
      },
    },
    options: {
      legend: {
        displayMode: 'table',
        placement: 'bottom',
        calcs: ['sum', 'mean'],
      },
      tooltip: { mode: 'multi' },
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            toStartOfInterval(start_time, INTERVAL 1 HOUR) as time,
            device_type,
            count() as sessions
          FROM user_sessions
          WHERE $__timeFilter(start_time)
          GROUP BY time, device_type
          ORDER BY time
        |||,
        format: 'time_series',
      },
    ],
  }
)

// Распределение по устройствам (Pie Chart)
.addPanel(
  {
    type: 'piechart',
    title: 'Device Distribution',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 12, y: 6, w: 12, h: 8 },
    options: {
      legend: {
        displayMode: 'table',
        placement: 'right',
        values: ['value', 'percent'],
      },
      pieType: 'pie',
      displayLabels: ['percent'],
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            device_type as metric,
            count() as value
          FROM user_sessions
          WHERE start_time >= now() - INTERVAL 24 HOUR
          GROUP BY device_type
          ORDER BY value DESC
        |||,
        format: 'table',
      },
    ],
  }
)

// Heatmap по часам и дням недели
.addPanel(
  {
    type: 'heatmap',
    title: 'Sessions Heatmap (Hour of Day)',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 0, y: 14, w: 24, h: 8 },
    options: {
      calculate: false,
      cellGap: 2,
      color: {
        mode: 'scheme',
        scheme: 'Spectral',
        steps: 128,
      },
      yAxis: {
        axisPlacement: 'left',
        reverse: false,
      },
      legend: {
        show: true,
      },
      tooltip: {
        show: true,
      },
    },
    fieldConfig: {
      defaults: {
        custom: {
          hideFrom: {
            legend: false,
            tooltip: false,
            viz: false,
          },
          scaleDistribution: {
            type: 'linear',
          },
        },
      },
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            toStartOfHour(start_time) as time,
            toHour(start_time) as hour_of_day,
            count() as sessions
          FROM user_sessions
          WHERE $__timeFilter(start_time)
          GROUP BY time, hour_of_day
          ORDER BY time
        |||,
        format: 'time_series',
      },
    ],
  }
)

// География пользователей (Table)
.addPanel(
  {
    type: 'table',
    title: 'Top Countries by Sessions',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 0, y: 22, w: 12, h: 8 },
    fieldConfig: {
      defaults: {
        custom: {
          align: 'left',
        },
      },
      overrides: [
        {
          matcher: { id: 'byName', options: 'sessions' },
          properties: [
            { id: 'custom.width', value: 100 },
          ],
        },
        {
          matcher: { id: 'byName', options: 'avg_duration' },
          properties: [
            { id: 'unit', value: 'm' },
            { id: 'custom.width', value: 120 },
          ],
        },
        {
          matcher: { id: 'byName', options: 'avg_pages' },
          properties: [
            { id: 'decimals', value: 2 },
            { id: 'custom.width', value: 100 },
          ],
        },
      ],
    },
    options: {
      showHeader: true,
      sortBy: [
        {
          displayName: 'sessions',
          desc: true,
        },
      ],
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            country,
            count() as sessions,
            round(avg(duration_minutes), 2) as avg_duration,
            round(avg(pages_visited), 2) as avg_pages
          FROM user_sessions
          WHERE start_time >= now() - INTERVAL 24 HOUR
          GROUP BY country
          ORDER BY sessions DESC
          LIMIT 15
        |||,
        format: 'table',
      },
    ],
  }
)

// Активность по часам (Bar Gauge)
.addPanel(
  {
    type: 'bargauge',
    title: 'Activity by Hour',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 12, y: 22, w: 12, h: 8 },
    options: {
      orientation: 'horizontal',
      displayMode: 'gradient',
      showUnfilled: true,
    },
    fieldConfig: {
      defaults: {
        color: {
          mode: 'continuous-GrYlRd',
        },
        unit: 'short',
        min: 0,
      },
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            concat('Hour ', toString(toHour(start_time))) as hour,
            count() as sessions
          FROM user_sessions
          WHERE start_time >= now() - INTERVAL 24 HOUR
          GROUP BY hour
          ORDER BY toHour(start_time)
        |||,
        format: 'table',
      },
    ],
  }
)

// Длительность сессий по устройствам (Box plot)
.addPanel(
  {
    type: 'timeseries',
    title: 'Session Duration Trend',
    datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
    gridPos: { x: 0, y: 30, w: 24, h: 8 },
    fieldConfig: {
      defaults: {
        color: { mode: 'palette-classic' },
        custom: {
          lineWidth: 2,
          fillOpacity: 10,
          showPoints: 'never',
          spanNulls: true,
        },
        unit: 'm',
      },
    },
    options: {
      legend: {
        displayMode: 'table',
        placement: 'right',
        calcs: ['mean', 'max', 'min'],
      },
      tooltip: { mode: 'multi' },
    },
    targets: [
      {
        datasource: { type: 'grafana-clickhouse-datasource', uid: datasourceUid },
        refId: 'A',
        rawSql: |||
          SELECT 
            toStartOfInterval(start_time, INTERVAL 1 HOUR) as time,
            round(avg(duration_minutes), 2) as avg_duration,
            round(quantile(0.5)(duration_minutes), 2) as median_duration,
            round(quantile(0.95)(duration_minutes), 2) as p95_duration
          FROM user_sessions
          WHERE $__timeFilter(start_time)
          GROUP BY time
          ORDER BY time
        |||,
        format: 'time_series',
      },
    ],
  }
)
