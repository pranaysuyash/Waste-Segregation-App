// Direct camera access helper for Flutter web
window.directCameraAccess = {
  // Create a file input element for camera capture
  createCameraInput: function() {
    // Remove any existing input
    this.removeCameraInput();
    
    // Create a new file input
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.capture = 'environment'; // This is key for mobile browsers
    input.style.position = 'absolute';
    input.style.top = '-9999px';
    input.style.left = '-9999px';
    input.id = 'flutter-camera-input';
    
    // Add the input to the DOM
    document.body.appendChild(input);
    
    // Return the element ID
    return 'flutter-camera-input';
  },
  
  // Trigger the input click
  triggerCamera: function() {
    const input = document.getElementById('flutter-camera-input');
    if (input) {
      input.click();
      return true;
    }
    return false;
  },
  
  // Set up the change event handler that Flutter will poll
  setupChangeHandler: function() {
    let resultData = null;
    
    const input = document.getElementById('flutter-camera-input');
    if (!input) return false;
    
    input.addEventListener('change', function(e) {
      if (input.files && input.files[0]) {
        const file = input.files[0];
        
        // Create a FileReader to read the image
        const reader = new FileReader();
        reader.onload = function(e) {
          resultData = e.target.result;
          console.log('Image captured: ' + file.name + ', size: ' + Math.round(resultData.length / 1024) + 'KB');
        };
        
        // Read the image as data URL
        reader.readAsDataURL(file);
      }
    });
    
    // Function to check if image data is available
    window.checkCameraResult = function() {
      const result = resultData;
      resultData = null; // Clear after reading
      return result;
    };
    
    return true;
  },
  
  // Remove the input element
  removeCameraInput: function() {
    const input = document.getElementById('flutter-camera-input');
    if (input) {
      input.remove();
    }
  }
};