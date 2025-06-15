/** @type { import('@storybook/web-components').Preview } */
const preview = {
  parameters: {
    actions: { argTypesRegex: '^on[A-Z].*' },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    // Configure visual testing
    chromatic: {
      // Pause animations for consistent screenshots
      pauseAnimationAtEnd: true,
      // Disable animations
      disableSnapshot: false,
      // Set viewport sizes for responsive testing
      viewports: [320, 768, 1024, 1440],
    },
    // Configure test runner
    test: {
      // Increase timeout for visual diff tests
      timeout: 10000,
      // Configure screenshot options
      screenshot: {
        mode: 'fullPage',
        clip: { x: 0, y: 0, width: 1024, height: 768 },
      },
    },
  },
  // Global decorators for consistent styling
  decorators: [
    (Story) => {
      // Add Material Design theme wrapper
      return `
        <div style="
          font-family: 'Roboto', sans-serif;
          background-color: #fafafa;
          padding: 16px;
          min-height: 100vh;
        ">
          ${Story()}
        </div>
      `;
    },
  ],
};

export default preview; 