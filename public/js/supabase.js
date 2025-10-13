// LSPU Emergency Response System - Supabase Integration
// Enhanced with AI image processing and real-time notifications

class EmergencyResponseSystem {
  constructor() {
    this.supabase = null;
    this.user = null;
    this.isInitialized = false;
    this.location = null;
    this.watchId = null;
    this.opencageApiKey = 'a8fcf18afc4f4fb8a7aa16d8403ae0a2'; // OpenCage API key for geocoding
  }

  async initialize() {
    try {
      // Load Supabase with fallback
      await this.loadSupabase();
      
      // Initialize Supabase client
      this.supabase = window.supabase.createClient(
        'https://hmolyqzbvxxliemclrld.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyNDY5NzAsImV4cCI6MjA3NTgyMjk3MH0.G2AOT-8zZ5sk8qGQUBifFqq5ww2W7Hxvtux0tlQ0Q-4'
      );

      // Check authentication (handle missing session gracefully)
      try {
        await this.checkAuth();
      } catch (error) {
        // Don't fail initialization for missing auth session
        if (error.message.includes('Auth session missing')) {
          console.log('ℹ️ No authenticated user (normal for login page)');
        } else {
          throw error;
        }
      }
      
      // Initialize geolocation
      await this.initializeGeolocation();
      
      this.isInitialized = true;
      console.log('✅ Emergency Response System initialized');
      
      return true;
    } catch (error) {
      console.error('❌ Failed to initialize system:', error);
      this.showError('Failed to initialize the emergency response system. Please refresh the page.');
      return false;
    }
  }

  async loadSupabase() {
    return new Promise((resolve, reject) => {
      if (window.supabase) {
        resolve();
        return;
      }

      const sources = [
        'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
        'https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.js',
        'https://cdn.skypack.dev/@supabase/supabase-js@2'
      ];

      let attempts = 0;
      const maxAttempts = sources.length;

      const tryLoad = () => {
        if (attempts >= maxAttempts) {
          reject(new Error('Failed to load Supabase from all sources'));
          return;
        }

        const script = document.createElement('script');
        script.src = sources[attempts];
        script.onload = () => {
          console.log(`✅ Supabase loaded from source ${attempts + 1}`);
          resolve();
        };
        script.onerror = () => {
          attempts++;
          tryLoad();
        };
        document.head.appendChild(script);
      };

      tryLoad();
    });
  }

  async checkAuth() {
    try {
      const { data: { user }, error } = await this.supabase.auth.getUser();
      
      if (error) {
        // Handle auth session missing gracefully - this is normal for login page
        if (error.message.includes('Auth session missing')) {
          console.log('ℹ️ No authenticated user (normal for login page)');
          this.user = null;
          this.updateUIForGuestUser();
          return;
        }
        throw error;
      }
      
      this.user = user;
      
      if (user) {
        console.log('✅ User authenticated:', user.email);
        this.updateUIForAuthenticatedUser();
      } else {
        console.log('ℹ️ No authenticated user');
        this.updateUIForGuestUser();
      }
    } catch (error) {
      console.error('❌ Auth check failed:', error);
      // Don't throw error for missing session - this is normal for login page
      if (error.message.includes('Auth session missing')) {
        console.log('ℹ️ No authenticated user (normal for login page)');
        this.user = null;
        this.updateUIForGuestUser();
        return;
      }
      throw error;
    }
  }

  async signIn(email, password) {
    try {
      const { data, error } = await this.supabase.auth.signInWithPassword({
        email,
        password
      });

      if (error) throw error;

      this.user = data.user;
      this.updateUIForAuthenticatedUser();
      
      this.showSuccess('Successfully signed in!');
      return data;
    } catch (error) {
      console.error('❌ Sign in failed:', error);
      this.showError('Sign in failed: ' + error.message);
      throw error;
    }
  }

  async signUp(email, password, userData = {}) {
    try {
      const { data, error } = await this.supabase.auth.signUp({
        email,
        password,
        options: {
          data: userData
        }
      });

      if (error) throw error;

      this.showSuccess('Account created! Please check your email to verify your account.');
      return data;
    } catch (error) {
      console.error('❌ Sign up failed:', error);
      this.showError('Sign up failed: ' + error.message);
      throw error;
    }
  }

  async signOut() {
    try {
      console.log('🚪 Signing out...');
      
      const { error } = await this.supabase.auth.signOut();
      if (error) throw error;

      this.user = null;
      this.updateUIForGuestUser();
      
      console.log('✅ Successfully signed out');
      this.showSuccess('Successfully signed out!');
      
      // Redirect to login page after successful sign out
      setTimeout(() => {
        console.log('🔄 Redirecting to login page...');
        window.location.href = 'login.html';
      }, 1000); // Small delay to show success message
      
    } catch (error) {
      console.error('❌ Sign out failed:', error);
      this.showError('Sign out failed: ' + error.message);
      
      // Even if sign out fails, redirect to login page
      setTimeout(() => {
        console.log('🔄 Redirecting to login page despite error...');
        window.location.href = 'login.html';
      }, 2000);
      
      throw error;
    }
  }

  async initializeGeolocation() {
    if (!navigator.geolocation) {
      console.warn('⚠️ Geolocation not supported');
      return;
    }

    try {
      const position = await this.getCurrentPosition();
      this.location = {
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy
      };
      
      console.log('✅ Location obtained:', this.location);
      
      // Start watching position for updates (reduced frequency)
      this.watchId = navigator.geolocation.watchPosition(
        (position) => {
          const newLocation = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
          };
          
          // Only update and log if location has changed significantly
          if (!this.location || 
              Math.abs(this.location.latitude - newLocation.latitude) > 0.001 ||
              Math.abs(this.location.longitude - newLocation.longitude) > 0.001) {
            this.location = newLocation;
            console.log('📍 Location updated:', this.location);
          }
        },
        (error) => {
          console.warn('⚠️ Location watch error:', error);
        },
        {
          enableHighAccuracy: false, // Reduced accuracy for better performance
          timeout: 15000,
          maximumAge: 60000 // Increased cache time to reduce updates
        }
      );
    } catch (error) {
      console.warn('⚠️ Geolocation failed:', error);
      this.showWarning('Location access denied. You can still report emergencies manually.');
    }
  }

  getCurrentPosition() {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 30000
      });
    });
  }

  // Method to set OpenCage API key for geocoding
  setOpenCageApiKey(apiKey) {
    this.opencageApiKey = apiKey;
    console.log('✅ OpenCage API key configured');
  }

  async getAddressFromCoordinates(lat, lng) {
    try {
      // Skip geocoding if no API key is configured
      if (!this.opencageApiKey || this.opencageApiKey === 'YOUR_OPENCAGE_API_KEY') {
        console.log('⚠️ OpenCage API key not configured, skipping geocoding');
        return `Location: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
      }
      
      const response = await fetch(
        `https://api.opencagedata.com/geocode/v1/json?q=${lat}+${lng}&key=${this.opencageApiKey}`
      );
      const data = await response.json();
      
      if (data.results && data.results.length > 0) {
        return data.results[0].formatted;
      }
      return `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
    } catch (error) {
      console.warn('⚠️ Address lookup failed:', error);
      return `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
    }
  }

  async submitEmergencyReport(reportData) {
    try {
      if (!this.user) {
        throw new Error('You must be signed in to submit a report');
      }

      // Add location data if available (using JSONB location field)
      if (this.location) {
        reportData.location = JSON.stringify({
          latitude: this.location.latitude,
          longitude: this.location.longitude,
          accuracy: this.location.accuracy,
          address: this.location.address || 'Location detected'
        });
      }

      // Add user data and new flow settings
      reportData.reporter_uid = this.user.id; // Use reporter_uid instead of user_id
      reportData.status = 'pending';
      reportData.lifecycle_status = 'pending';

      console.log('📝 Submitting report:', reportData);

      const { data, error } = await this.supabase
        .from('reports')
        .insert([reportData])
        .select()
        .single();

      if (error) throw error;

      console.log('✅ Report submitted:', data);

      // Trigger AI analysis
      await this.triggerAIAnalysis(data.id);

      this.showSuccess('Emergency report submitted successfully! AI analysis in progress...');
      return data;
    } catch (error) {
      console.error('❌ Report submission failed:', error);
      this.showError('Failed to submit report: ' + error.message);
      throw error;
    }
  }

  async triggerAIAnalysis(reportId) {
    try {
      console.log('🤖 Triggering AI analysis for report:', reportId);
      
      const { data, error } = await this.supabase.functions.invoke('classify-image', {
        body: { reportId }
      });

      if (error) throw error;

      console.log('✅ AI analysis completed:', data);
      return data;
    } catch (error) {
      console.error('❌ AI analysis failed:', error);
      // Don't throw error here as the report is still submitted
      console.warn('⚠️ Report submitted but AI analysis failed');
    }
  }

  async uploadImage(file) {
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}.${fileExt}`;
      const filePath = `emergency-reports/${fileName}`;

      console.log('📤 Uploading image:', fileName);

      const { data, error } = await this.supabase.storage
        .from('reports-images')
        .upload(filePath, file);

      if (error) throw error;

      console.log('✅ Image uploaded:', data);
      
      // Get the public URL for the uploaded image
      const { data: urlData } = this.supabase.storage
        .from('reports-images')
        .getPublicUrl(data.path);
      
      return urlData.publicUrl;
    } catch (error) {
      console.error('❌ Image upload failed:', error);
      this.showError('Failed to upload image: ' + error.message);
      throw error;
    }
  }

  async getReports(filters = {}) {
    try {
      let query = this.supabase
        .from('reports')
        .select('*')
        .order('created_at', { ascending: false });

      // Apply filters
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.type) {
        query = query.eq('type', filters.type);
      }
      if (filters.user_id) {
        query = query.eq('reporter_uid', filters.user_id);
      }

      const { data, error } = await query;

      if (error) {
        console.error('❌ Failed to fetch reports:', error);
        
        // If RLS policy error, try to get reports without filters
        if (error.message.includes('row-level security policy')) {
          console.log('⚠️ RLS policy blocking access, trying alternative approach...');
          
          // For admin and responder roles, try to get all reports
          const userRole = this.user?.user_metadata?.role;
          if (userRole === 'admin' || userRole === 'responder') {
            console.log('🔧 Admin/Responder detected, trying to access all reports...');
            
            // Try without user_id filter for admin/responder
            const { data: allData, error: allError } = await this.supabase
              .from('reports')
              .select('*')
              .order('created_at', { ascending: false });
              
            if (allError) {
              console.error('❌ Alternative approach failed:', allError.message);
              this.showError('Failed to load reports: ' + allError.message);
              throw allError;
            }
            
            console.log('✅ Alternative approach successful:', allData.length, 'reports');
            return allData || [];
          }
        }
        
        this.showError('Failed to load reports: ' + error.message);
        throw error;
      }

      console.log('✅ Reports loaded successfully:', data.length);
      return data || [];
    } catch (error) {
      console.error('❌ Failed to fetch reports:', error);
      this.showError('Failed to load reports: ' + error.message);
      throw error;
    }
  }

  async getReportById(id) {
    try {
      const { data, error } = await this.supabase
        .from('reports')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;

      return data;
    } catch (error) {
      console.error('❌ Failed to fetch report:', error);
      this.showError('Failed to load report: ' + error.message);
      throw error;
    }
  }

  async updateReportStatus(id, status, notes = '') {
    try {
      const updateData = {
        status
      };
      
      // Note: Only update fields that exist in the database schema
      // 'notes' and 'updated_at' fields don't exist in the reports table
      
      const { data, error } = await this.supabase
        .from('reports')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      console.log('✅ Report status updated:', data);
      return data;
    } catch (error) {
      console.error('❌ Failed to update report:', error);
      this.showError('Failed to update report: ' + error.message);
      throw error;
    }
  }

  async subscribeToNotifications(callback) {
    try {
      const channel = this.supabase
        .channel('emergency-notifications')
        .on('postgres_changes', {
          event: '*',
          schema: 'public',
          table: 'reports'
        }, callback)
        .subscribe();

      console.log('🔔 Subscribed to notifications');
      return channel;
    } catch (error) {
      console.error('❌ Failed to subscribe to notifications:', error);
      throw error;
    }
  }

  async sendNotification(title, message, type = 'info') {
    try {
      if ('Notification' in window) {
        if (Notification.permission === 'granted') {
          new Notification(title, {
            body: message,
            icon: '/images/emergency-icon.png'
          });
        } else if (Notification.permission !== 'denied') {
          const permission = await Notification.requestPermission();
          if (permission === 'granted') {
            new Notification(title, {
              body: message,
              icon: '/images/emergency-icon.png'
            });
          }
        }
      }
    } catch (error) {
      console.error('❌ Failed to send notification:', error);
    }
  }

  updateUIForAuthenticatedUser() {
    // Update UI elements for authenticated user
    const authElements = document.querySelectorAll('[data-auth="required"]');
    authElements.forEach(el => el.style.display = 'block');

    const guestElements = document.querySelectorAll('[data-auth="guest"]');
    guestElements.forEach(el => el.style.display = 'none');

    // Update user info
    const userInfoElements = document.querySelectorAll('[data-user-info]');
    userInfoElements.forEach(el => {
      if (el.dataset.userInfo === 'email') {
        el.textContent = this.user.email;
      }
    });
  }

  updateUIForGuestUser() {
    // Update UI elements for guest user
    const authElements = document.querySelectorAll('[data-auth="required"]');
    authElements.forEach(el => el.style.display = 'none');

    const guestElements = document.querySelectorAll('[data-auth="guest"]');
    guestElements.forEach(el => el.style.display = 'block');
  }

  showSuccess(message) {
    this.showAlert(message, 'success');
  }

  showError(message) {
    this.showAlert(message, 'error');
  }

  showWarning(message) {
    this.showAlert(message, 'warning');
  }

  showInfo(message) {
    this.showAlert(message, 'info');
  }

  showAlert(message, type = 'info') {
    // Create alert element
    const alert = document.createElement('div');
    alert.className = `alert alert-${type}`;
    alert.innerHTML = `
      <div class="flex items-center gap-4">
        <span>${message}</span>
        <button onclick="this.parentElement.parentElement.remove()" class="ml-auto text-gray-500 hover:text-gray-700">
          ×
        </button>
      </div>
    `;

    // Add to page
    const container = document.querySelector('.alerts-container') || document.body;
    container.insertBefore(alert, container.firstChild);

    // Auto remove after 5 seconds
    setTimeout(() => {
      if (alert.parentElement) {
        alert.remove();
      }
    }, 5000);
  }

  cleanup() {
    if (this.watchId) {
      navigator.geolocation.clearWatch(this.watchId);
    }
  }
}

// Initialize global instance
window.emergencySystem = new EmergencyResponseSystem();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.emergencySystem.initialize();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  window.emergencySystem.cleanup();
});
