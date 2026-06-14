import { fileURLToPath } from 'url';
import path from 'path';
import fetch from 'node-fetch';

const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY,
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.VITE_FIREBASE_APP_ID,
};

const fetch = require('node-fetch');

async function getProduct() {
  const projectId = 'print-5cc56';
  const productId = 'PRD1780725731834';
  
  try {
    const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/-default-/documents/products/${productId}`,
      {
        headers: {
          'Authorization': `Bearer ${await getAccessToken()}`
        }
      }
    );
    
    if (!response.ok) {
      console.error(`Error: ${response.status}`);
      return;
    }
    
    const data = await response.json();
    
    console.log('\n========================================');
    console.log('FIRESTORE PRODUCT DATA');
    console.log('========================================\n');
    console.log('ID:', productId);
    
    const fields = data.fields || {};
    
    console.log('\nAll Fields in Firestore:');
    console.log('------------------------');
    Object.keys(fields).sort().forEach(key => {
      const field = fields[key];
      let value = null;
      
      if (field.stringValue !== undefined) value = field.stringValue;
      else if (field.integerValue !== undefined) value = field.integerValue;
      else if (field.doubleValue !== undefined) value = field.doubleValue;
      else if (field.booleanValue !== undefined) value = field.booleanValue;
      else if (field.arrayValue !== undefined) value = `[array with ${field.arrayValue.values?.length || 0} items]`;
      else if (field.mapValue !== undefined) value = `[map with ${Object.keys(field.mapValue.fields || {}).length} fields]`;
      else value = JSON.stringify(field);
      
      console.log(`${key}: ${value}`);
    });
    
    console.log('\n\nKey Fields for Product Model:');
    console.log('-----------------------------');
    console.log('id:', fields.id?.stringValue || 'MISSING');
    console.log('name:', fields.name?.stringValue || 'MISSING');
    console.log('category:', fields.category?.stringValue || 'MISSING');
    console.log('description:', fields.description?.stringValue || 'MISSING');
    console.log('imageUrl:', fields.imageUrl?.stringValue || 'MISSING');
    console.log('status:', fields.status?.stringValue || 'MISSING');
    console.log('basePrice:', fields.basePrice?.doubleValue || fields.basePrice?.integerValue || 'MISSING');
    console.log('originalPrice:', fields.originalPrice?.doubleValue || fields.originalPrice?.integerValue || 'MISSING');
    console.log('sizes:', fields.sizes?.arrayValue?.values?.length || 'MISSING (0 items)');
    console.log('finishes:', fields.finishes?.arrayValue?.values?.length || 'MISSING (0 items)');
    console.log('tags:', fields.tags?.arrayValue?.values?.length || 'MISSING (0 items)');
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

async function getAccessToken() {
  // For now, we'll use a simpler approach with REST API
  // Return empty string and handle it differently
  return '';
}

// Direct REST API call without authentication first
async function getProductDirect() {
  const projectId = 'print-5cc56';
  const productId = 'PRD1780725731834';
  const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';
  
  try {
    const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/-default-/documents/products/${productId}?key=${apiKey}`,
      {
        method: 'GET'
      }
    );
    
    if (!response.ok) {
      console.error(`Error: ${response.status} ${response.statusText}`);
      const text = await response.text();
      console.error('Response:', text);
      return;
    }
    
    const data = await response.json();
    
    console.log('\n========================================');
    console.log('FIRESTORE PRODUCT: PRD1780725731834');
    console.log('========================================\n');
    
    const fields = data.fields || {};
    
    console.log('ALL FIELDS IN FIRESTORE:');
    console.log('------------------------');
    Object.keys(fields).sort().forEach(key => {
      const field = fields[key];
      let value = null;
      
      if (field.stringValue !== undefined) value = `"${field.stringValue}"`;
      else if (field.integerValue !== undefined) value = field.integerValue;
      else if (field.doubleValue !== undefined) value = field.doubleValue;
      else if (field.booleanValue !== undefined) value = field.booleanValue;
      else if (field.arrayValue !== undefined) value = `[array: ${field.arrayValue.values?.length || 0} items]`;
      else if (field.mapValue !== undefined) value = `[map: ${Object.keys(field.mapValue.fields || {}).length} fields]`;
      else if (field.nullValue !== undefined) value = 'NULL';
      else value = JSON.stringify(field);
      
      console.log(`  ${key}: ${value}`);
    });
    
    console.log('\n\nPRODUCT MODEL REQUIREMENTS:');
    console.log('---------------------------');
    console.log(`  id: ${fields.id?.stringValue || '❌ MISSING'}`);
    console.log(`  name: ${fields.name?.stringValue ? `"${fields.name.stringValue}"` : '❌ MISSING or EMPTY'}`);
    console.log(`  category: ${fields.category?.stringValue || '❌ MISSING'}`);
    console.log(`  description: ${fields.description?.stringValue ? `"${fields.description.stringValue}"` : '❌ MISSING or EMPTY'}`);
    console.log(`  imageUrl: ${fields.imageUrl?.stringValue || '❌ MISSING'}`);
    console.log(`  status: ${fields.status?.stringValue || '❌ MISSING'}`);
    console.log(`  basePrice: ${fields.basePrice?.doubleValue !== undefined ? fields.basePrice.doubleValue : (fields.basePrice?.integerValue || '❌ MISSING')}`);
    console.log(`  originalPrice: ${fields.originalPrice?.doubleValue !== undefined ? fields.originalPrice.doubleValue : (fields.originalPrice?.integerValue || '❌ MISSING')}`);
    console.log(`  sizes: ${fields.sizes?.arrayValue?.values?.length || '❌ MISSING (empty array)'}`);
    console.log(`  finishes: ${fields.finishes?.arrayValue?.values?.length || '❌ MISSING (empty array)'}`);
    console.log(`  tags: ${fields.tags?.arrayValue?.values?.length || '❌ MISSING (empty array)'}`);
    
    console.log('\n========================================\n');
    
  } catch (error) {
    console.error('Error fetching product:', error.message);
  }
}

getProductDirect();
