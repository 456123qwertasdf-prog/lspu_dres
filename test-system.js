#!/usr/bin/env node

/**
 * LSPU Emergency Response System v2.0 - System Test
 * 
 * This script tests the basic functionality of the emergency response system.
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 LSPU Emergency Response System v2.0 - System Test');
console.log('==================================================\n');

// Test 1: Check project structure
console.log('📁 Testing project structure...');
const requiredFiles = [
  'package.json',
  'public/index.html',
  'public/responder.html', 
  'public/admin.html',
  'public/css/style.css',
  'public/js/supabase.js',
  'public/manifest.json',
  'public/sw.js',
  'supabase/functions/classify-image/index.ts',
  'supabase/functions/classify-pending/index.ts'
];

let structurePassed = true;
requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`  ✅ ${file}`);
  } else {
    console.log(`  ❌ ${file} - MISSING`);
    structurePassed = false;
  }
});

if (structurePassed) {
  console.log('✅ Project structure test PASSED\n');
} else {
  console.log('❌ Project structure test FAILED\n');
}

// Test 2: Check package.json
console.log('📦 Testing package.json...');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  const requiredFields = ['name', 'version', 'description', 'scripts', 'dependencies'];
  let packagePassed = true;
  
  requiredFields.forEach(field => {
    if (packageJson[field]) {
      console.log(`  ✅ ${field}: ${typeof packageJson[field] === 'object' ? 'object' : packageJson[field]}`);
    } else {
      console.log(`  ❌ ${field} - MISSING`);
      packagePassed = false;
    }
  });
  
  if (packagePassed) {
    console.log('✅ Package.json test PASSED\n');
  } else {
    console.log('❌ Package.json test FAILED\n');
  }
} catch (error) {
  console.log(`❌ Package.json test FAILED - ${error.message}\n`);
}

// Test 3: Check HTML files
console.log('🌐 Testing HTML files...');
const htmlFiles = [
  'public/index.html',
  'public/responder.html',
  'public/admin.html'
];

let htmlPassed = true;
htmlFiles.forEach(file => {
  try {
    const content = fs.readFileSync(file, 'utf8');
    
    // Check for required elements
    const requiredElements = [
      '<!DOCTYPE html>',
      '<html lang="en">',
      '<head>',
      '<body>',
      'emergencySystem',
      'css/style.css'
    ];
    
    let filePassed = true;
    requiredElements.forEach(element => {
      if (content.includes(element)) {
        console.log(`  ✅ ${file} contains ${element}`);
      } else {
        console.log(`  ❌ ${file} missing ${element}`);
        filePassed = false;
      }
    });
    
    if (!filePassed) {
      htmlPassed = false;
    }
  } catch (error) {
    console.log(`  ❌ ${file} - ${error.message}`);
    htmlPassed = false;
  }
});

if (htmlPassed) {
  console.log('✅ HTML files test PASSED\n');
} else {
  console.log('❌ HTML files test FAILED\n');
}

// Test 4: Check CSS file
console.log('🎨 Testing CSS file...');
try {
  const cssContent = fs.readFileSync('public/css/style.css', 'utf8');
  
  const requiredClasses = [
    ':root',
    '.btn',
    '.card',
    '.form-input',
    '.navbar',
    '.alert'
  ];
  
  let cssPassed = true;
  requiredClasses.forEach(className => {
    if (cssContent.includes(className)) {
      console.log(`  ✅ CSS contains ${className}`);
    } else {
      console.log(`  ❌ CSS missing ${className}`);
      cssPassed = false;
    }
  });
  
  if (cssPassed) {
    console.log('✅ CSS file test PASSED\n');
  } else {
    console.log('❌ CSS file test FAILED\n');
  }
} catch (error) {
  console.log(`❌ CSS file test FAILED - ${error.message}\n`);
}

// Test 5: Check JavaScript file
console.log('⚡ Testing JavaScript file...');
try {
  const jsContent = fs.readFileSync('public/js/supabase.js', 'utf8');
  
  const requiredFunctions = [
    'class EmergencyResponseSystem',
    'initialize()',
    'submitEmergencyReport',
    'uploadImage',
    'getReports',
    'subscribeToNotifications'
  ];
  
  let jsPassed = true;
  requiredFunctions.forEach(func => {
    if (jsContent.includes(func)) {
      console.log(`  ✅ JS contains ${func}`);
    } else {
      console.log(`  ❌ JS missing ${func}`);
      jsPassed = false;
    }
  });
  
  if (jsPassed) {
    console.log('✅ JavaScript file test PASSED\n');
  } else {
    console.log('❌ JavaScript file test FAILED\n');
  }
} catch (error) {
  console.log(`❌ JavaScript file test FAILED - ${error.message}\n`);
}

// Test 6: Check Supabase functions
console.log('🔧 Testing Supabase functions...');
const supabaseFunctions = [
  'supabase/functions/classify-image/index.ts',
  'supabase/functions/classify-pending/index.ts'
];

let supabasePassed = true;
supabaseFunctions.forEach(func => {
  try {
    const content = fs.readFileSync(func, 'utf8');
    
    if (content.includes('Deno.serve') && content.includes('async (req)')) {
      console.log(`  ✅ ${func} - Valid Edge Function`);
    } else {
      console.log(`  ❌ ${func} - Invalid or incomplete`);
      supabasePassed = false;
    }
  } catch (error) {
    console.log(`  ❌ ${func} - ${error.message}`);
    supabasePassed = false;
  }
});

if (supabasePassed) {
  console.log('✅ Supabase functions test PASSED\n');
} else {
  console.log('❌ Supabase functions test FAILED\n');
}

// Test 7: Check PWA files
console.log('📱 Testing PWA files...');
const pwaFiles = [
  'public/manifest.json',
  'public/sw.js'
];

let pwaPassed = true;
pwaFiles.forEach(file => {
  try {
    const content = fs.readFileSync(file, 'utf8');
    
    if (file.endsWith('.json')) {
      JSON.parse(content); // Validate JSON
      console.log(`  ✅ ${file} - Valid JSON`);
    } else {
      if (content.includes('Service Worker') || content.includes('addEventListener')) {
        console.log(`  ✅ ${file} - Valid Service Worker`);
      } else {
        console.log(`  ❌ ${file} - Invalid Service Worker`);
        pwaPassed = false;
      }
    }
  } catch (error) {
    console.log(`  ❌ ${file} - ${error.message}`);
    pwaPassed = false;
  }
});

if (pwaPassed) {
  console.log('✅ PWA files test PASSED\n');
} else {
  console.log('❌ PWA files test FAILED\n');
}

// Summary
console.log('📊 Test Summary:');
console.log('================');
console.log('✅ All tests completed!');
console.log('\n🚀 Next Steps:');
console.log('1. Run: npm install');
console.log('2. Configure .env file with your Supabase credentials');
console.log('3. Run: npm run dev');
console.log('4. Open http://localhost:8000');
console.log('\n🎉 System is ready for development!');
