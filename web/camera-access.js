// Camera access helper for Flutter web
(function() {
  // Track active camera stream
  let activeStream = null;
  
  // Store camera result
  window.cameraResult = null;
  
  // Detect if device is mobile
  window.isMobileDevice = function() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  };
  
  // Initialize camera elements
  window.initializeCameraElements = function() {
    // Remove any existing elements
    const oldVideo = document.getElementById('flutter-video');
    const oldCanvas = document.getElementById('flutter-canvas');
    const oldInput = document.getElementById('flutter-camera-input');
    
    if (oldVideo) oldVideo.remove();
    if (oldCanvas) oldCanvas.remove();
    if (oldInput) oldInput.remove();
    
    // Create video element for desktop
    const video = document.createElement('video');
    video.id = 'flutter-video';
    video.style.display = 'none';
    video.setAttribute('playsinline', 'true');
    video.setAttribute('autoplay', 'true');
    document.body.appendChild(video);
    
    // Create canvas element for capturing frames
    const canvas = document.createElement('canvas');
    canvas.id = 'flutter-canvas';
    canvas.style.display = 'none';
    document.body.appendChild(canvas);
    
    // Create file input for mobile fallback
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.setAttribute('capture', 'environment');
    input.style.position = 'absolute';
    input.style.top = '-9999px';
    input.style.left = '-9999px';
    input.style.opacity = '0';
    input.id = 'flutter-camera-input';
    document.body.appendChild(input);
    
    // Set up the change handler for file input
    input.onchange = function(event) {
      const file = event.target.files[0];
      if (!file) return;
      
      console.log('File selected:', file.name);
      
      const reader = new FileReader();
      reader.onload = function(e) {
        window.cameraResult = e.target.result;
        console.log('Image loaded (file input), size:', Math.round(e.target.result.length / 1024) + 'KB');
      };
      
      reader.readAsDataURL(file);
    };
    
    return true;
  };
  
  // Start camera for desktop - returns a promise
  window.startCamera = function() {
    return new Promise((resolve, reject) => {
      const video = document.getElementById('flutter-video');
      if (!video) {
        reject('Video element not found');
        return;
      }
      
      // Stop any existing stream
      if (activeStream) {
        activeStream.getTracks().forEach(track => track.stop());
        activeStream = null;
      }
      
      // Check if getUserMedia is supported
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        console.warn('getUserMedia not supported in this browser');
        reject('Camera API not supported');
        return;
      }
      
      // Request camera access
      navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'environment',
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      })
      .then(stream => {
        // Store the stream for later cleanup
        activeStream = stream;
        
        // Set the video source
        video.srcObject = stream;
        
        // Wait for video to be ready
        video.onloadedmetadata = () => {
          video.play()
            .then(() => {
              console.log('Camera started successfully');
              resolve(true);
            })
            .catch(err => {
              console.error('Error playing video:', err);
              reject(err);
            });
        };
      })
      .catch(err => {
        console.error('Error accessing camera:', err);
        reject(err);
      });
    });
  };
  
  // Capture image from video feed
  window.captureImageFromVideo = function() {
    return new Promise((resolve, reject) => {
      const video = document.getElementById('flutter-video');
      const canvas = document.getElementById('flutter-canvas');
      
      if (!video || !canvas) {
        reject('Video or canvas element not found');
        return;
      }
      
      try {
        // Get video dimensions
        const width = video.videoWidth;
        const height = video.videoHeight;
        
        if (width === 0 || height === 0) {
          reject('Invalid video dimensions');
          return;
        }
        
        // Set canvas dimensions
        canvas.width = width;
        canvas.height = height;
        
        // Draw current video frame to canvas
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0, width, height);
        
        // Get data URL
        const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
        
        // Store result
        window.cameraResult = dataUrl;
        
        console.log('Image captured from video feed, size:', Math.round(dataUrl.length / 1024) + 'KB');
        
        // Stop the camera stream
        if (activeStream) {
          activeStream.getTracks().forEach(track => track.stop());
          activeStream = null;
        }
        
        resolve(true);
      } catch (err) {
        console.error('Error capturing image:', err);
        reject(err);
      }
    });
  };
  
  // Show live camera feed in a modal
  window.showCameraModal = function() {
    // Create modal container
    const modal = document.createElement('div');
    modal.id = 'camera-modal';
    modal.style.position = 'fixed';
    modal.style.top = '0';
    modal.style.left = '0';
    modal.style.width = '100%';
    modal.style.height = '100%';
    modal.style.backgroundColor = 'rgba(0,0,0,0.9)';
    modal.style.zIndex = '9999';
    modal.style.display = 'flex';
    modal.style.flexDirection = 'column';
    modal.style.justifyContent = 'space-between';
    modal.style.alignItems = 'center';
    
    // Create video container that shows the camera feed
    const videoContainer = document.createElement('div');
    videoContainer.style.width = '100%';
    videoContainer.style.flex = '1';
    videoContainer.style.display = 'flex';
    videoContainer.style.justifyContent = 'center';
    videoContainer.style.alignItems = 'center';
    videoContainer.style.overflow = 'hidden';
    
    // Create live video element
    const liveVideo = document.createElement('video');
    liveVideo.id = 'live-camera-feed';
    liveVideo.style.maxWidth = '100%';
    liveVideo.style.maxHeight = '80vh';
    liveVideo.style.transform = 'scaleX(-1)'; // Mirror front camera
    liveVideo.setAttribute('playsinline', 'true');
    liveVideo.setAttribute('autoplay', 'true');
    
    videoContainer.appendChild(liveVideo);
    
    // Create button container
    const buttonContainer = document.createElement('div');
    buttonContainer.style.padding = '20px';
    buttonContainer.style.width = '100%';
    buttonContainer.style.display = 'flex';
    buttonContainer.style.justifyContent = 'space-around';
    
    // Create capture button
    const captureButton = document.createElement('button');
    captureButton.textContent = 'Take Photo';
    captureButton.style.padding = '12px 24px';
    captureButton.style.borderRadius = '24px';
    captureButton.style.backgroundColor = '#4CAF50';
    captureButton.style.color = 'white';
    captureButton.style.border = 'none';
    captureButton.style.fontSize = '16px';
    
    // Create cancel button
    const cancelButton = document.createElement('button');
    cancelButton.textContent = 'Cancel';
    cancelButton.style.padding = '12px 24px';
    cancelButton.style.borderRadius = '24px';
    cancelButton.style.backgroundColor = '#f44336';
    cancelButton.style.color = 'white';
    cancelButton.style.border = 'none';
    cancelButton.style.fontSize = '16px';
    
    buttonContainer.appendChild(cancelButton);
    buttonContainer.appendChild(captureButton);
    
    // Add elements to modal
    modal.appendChild(videoContainer);
    modal.appendChild(buttonContainer);
    
    // Add modal to document
    document.body.appendChild(modal);
    
    // Start camera and attach to live video
    return new Promise((resolve, reject) => {
      navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'environment',
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      })
      .then(stream => {
        // Store the stream for later cleanup
        activeStream = stream;
        
        // Set the video source
        liveVideo.srcObject = stream;
        liveVideo.play().catch(err => console.error('Error playing video:', err));
        
        // Set up capture button
        captureButton.addEventListener('click', () => {
          try {
            // Create temporary canvas
            const canvas = document.createElement('canvas');
            canvas.width = liveVideo.videoWidth;
            canvas.height = liveVideo.videoHeight;
            
            // Draw current video frame
            const ctx = canvas.getContext('2d');
            ctx.drawImage(liveVideo, 0, 0, canvas.width, canvas.height);
            
            // Get data URL
            const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
            
            // Store result
            window.cameraResult = dataUrl;
            
            console.log('Image captured from live feed, size:', Math.round(dataUrl.length / 1024) + 'KB');
            
            // Stop the camera stream
            if (activeStream) {
              activeStream.getTracks().forEach(track => track.stop());
              activeStream = null;
            }
            
            // Remove modal
            document.body.removeChild(modal);
            
            resolve(true);
          } catch (err) {
            console.error('Error capturing from live feed:', err);
            reject(err);
          }
        });
        
        // Set up cancel button
        cancelButton.addEventListener('click', () => {
          // Stop the camera stream
          if (activeStream) {
            activeStream.getTracks().forEach(track => track.stop());
            activeStream = null;
          }
          
          // Remove modal
          document.body.removeChild(modal);
          
          reject('Cancelled by user');
        });
      })
      .catch(err => {
        console.error('Error accessing camera for modal:', err);
        
        // Remove modal
        document.body.removeChild(modal);
        
        reject(err);
      });
    });
  };
  
  // Function to trigger the appropriate camera method
  window.triggerCamera = function() {
    // Clear any previous result
    window.cameraResult = null;
    
    // If on mobile, use file input approach
    if (window.isMobileDevice()) {
      console.log('Using file input approach for mobile device');
      const input = document.getElementById('flutter-camera-input');
      if (!input) return false;
      
      // Need to wait for user interaction to complete
      setTimeout(() => {
        input.click();
      }, 100);
      
      return true;
    } else {
      // On desktop, use the live camera modal
      console.log('Using live camera modal for desktop');
      window.showCameraModal()
        .then(() => console.log('Camera modal captured successfully'))
        .catch(err => console.error('Camera modal error:', err));
      
      return true;
    }
  };
  
  // Function to check for camera result
  window.checkCameraResult = function() {
    const result = window.cameraResult;
    // Keep the result - Flutter will clear it after reading
    return result;
  };
  
  // Function to clean up camera resources
  window.cleanupCamera = function() {
    if (activeStream) {
      activeStream.getTracks().forEach(track => track.stop());
      activeStream = null;
    }
    window.cameraResult = null;
    return true;
  };
})();