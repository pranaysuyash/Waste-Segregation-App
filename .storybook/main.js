/** @type { import('@storybook/web-components-vite').StorybookConfig } */
const config = {
  stories: ['../stories/**/*.stories.@(js|jsx|mjs|ts|tsx)'],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
  ],
  framework: {
    name: '@storybook/web-components-vite',
    options: {},
  },
  docs: {
    autodocs: 'tag',
  },
  features: {
    buildStoriesJson: true
  },
  staticDirs: ['../public'],
  async viteFinal(config) {
    // Customize Vite config for Flutter widget testing
    return {
      ...config,
      define: {
        ...config.define,
        'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
      },
    };
  },
};

export default config; 