import { html } from 'lit';

export default {
  title: 'Components/StatsCard',
  parameters: {
    // Configure visual testing for this component
    chromatic: {
      viewports: [320, 768, 1024],
      // Disable animations for consistent screenshots
      pauseAnimationAtEnd: true,
    },
  },
  argTypes: {
    title: { control: 'text' },
    value: { control: 'text' },
    trend: { control: 'select', options: ['up', 'down', 'flat'] },
    color: { control: 'color' },
  },
};

// Mock Flutter-like stats card component for visual testing
const Template = ({ title, value, trend, color }) => html`
  <div style="
    background: white;
    border-radius: 12px;
    padding: 16px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    min-width: 200px;
    max-width: 300px;
    font-family: 'Roboto', sans-serif;
  ">
    <div style="
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    ">
      <h3 style="
        margin: 0;
        font-size: 14px;
        font-weight: 500;
        color: #666;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      ">${title}</h3>
      <div style="
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background-color: ${color};
      "></div>
    </div>
    
    <div style="
      display: flex;
      align-items: baseline;
      gap: 8px;
    ">
      <span style="
        font-size: 24px;
        font-weight: 600;
        color: #333;
      ">${value}</span>
      
      <span style="
        font-size: 12px;
        color: ${trend === 'up' ? '#4CAF50' : trend === 'down' ? '#F44336' : '#666'};
        display: flex;
        align-items: center;
        gap: 2px;
      ">
        ${trend === 'up' ? '↗' : trend === 'down' ? '↘' : '→'}
        ${trend}
      </span>
    </div>
  </div>
`;

export const Default = Template.bind({});
Default.args = {
  title: 'Total Scans',
  value: '42',
  trend: 'up',
  color: '#4CAF50',
};

export const HighValue = Template.bind({});
HighValue.args = {
  title: 'Points Earned',
  value: '1,234',
  trend: 'up',
  color: '#2196F3',
};

export const DownTrend = Template.bind({});
DownTrend.args = {
  title: 'Weekly Goal',
  value: '67%',
  trend: 'down',
  color: '#FF9800',
};

export const FlatTrend = Template.bind({});
FlatTrend.args = {
  title: 'Accuracy',
  value: '98%',
  trend: 'flat',
  color: '#9C27B0',
};

// Test overflow scenarios
export const LongTitle = Template.bind({});
LongTitle.args = {
  title: 'Very Long Title That Might Overflow',
  value: '999,999',
  trend: 'up',
  color: '#4CAF50',
};

export const LongValue = Template.bind({});
LongValue.args = {
  title: 'Big Number',
  value: '999,999,999',
  trend: 'up',
  color: '#4CAF50',
}; 