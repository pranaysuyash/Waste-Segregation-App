const { getStoryContext } = require('@storybook/test-runner');

module.exports = {
  setup() {
    // Global setup for test runner
    console.log('🧪 Setting up Storybook test runner...');
  },
  
  async preRender(page, context) {
    // Pre-render setup for each story
    const storyContext = await getStoryContext(page, context);
    
    // Disable animations for consistent screenshots
    await page.addStyleTag({
      content: `
        *, *::before, *::after {
          animation-duration: 0s !important;
          animation-delay: 0s !important;
          transition-duration: 0s !important;
          transition-delay: 0s !important;
        }
      `,
    });
    
    // Wait for fonts to load
    await page.evaluateHandle('document.fonts.ready');
    
    return storyContext;
  },
  
  async postRender(page, context) {
    // Post-render checks and visual testing
    const storyContext = await getStoryContext(page, context);
    
    // Check for layout overflow
    const hasOverflow = await page.evaluate(() => {
      const elements = document.querySelectorAll('*');
      for (const element of elements) {
        const rect = element.getBoundingClientRect();
        const style = window.getComputedStyle(element);
        
        // Check if element overflows its container
        if (style.overflow === 'visible' && 
            (rect.width > window.innerWidth || rect.height > window.innerHeight)) {
          return true;
        }
      }
      return false;
    });
    
    if (hasOverflow) {
      throw new Error(`Layout overflow detected in story: ${context.title}`);
    }
    
    // Take screenshot for visual diff
    const screenshot = await page.screenshot({
      fullPage: true,
      animations: 'disabled',
    });
    
    // Store screenshot for comparison (in a real implementation, 
    // you'd compare with baseline images)
    console.log(`📸 Screenshot captured for ${context.title}`);
    
    return storyContext;
  },
  
  // Configure test timeout
  testTimeout: 15000,
  
  // Configure browser launch options
  launchOptions: {
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  },
}; 