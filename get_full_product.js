/**
 * Get COMPLETE product document
 */

const projectId = 'print-5cc56';
const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';
const productId = 'PRD1780725731834';

async function getFullProduct() {
  try {
    console.log(`📦 Fetching complete product document: ${productId}\n`);
    
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products/${productId}?key=${apiKey}`;
    
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Failed: ${res.status} ${res.statusText}`);
    }
    
    const doc = await res.json();
    
    console.log('='.repeat(80));
    console.log('COMPLETE PRODUCT DOCUMENT');
    console.log('='.repeat(80));
    console.log('\nRaw Firestore Response:');
    console.log(JSON.stringify(doc, null, 2));
    
    console.log('\n' + '='.repeat(80));
    console.log('PARSED VALUES');
    console.log('='.repeat(80));
    
    const fields = doc.fields || {};
    const parsed = {};
    
    for (const [key, value] of Object.entries(fields)) {
      // Extract the actual value from Firestore format
      if (value.stringValue !== undefined) {
        parsed[key] = value.stringValue;
      } else if (value.integerValue !== undefined) {
        parsed[key] = value.integerValue;
      } else if (value.doubleValue !== undefined) {
        parsed[key] = value.doubleValue;
      } else if (value.booleanValue !== undefined) {
        parsed[key] = value.booleanValue;
      } else if (value.nullValue !== undefined) {
        parsed[key] = null;
      } else {
        parsed[key] = value;
      }
    }
    
    Object.entries(parsed).forEach(([key, value]) => {
      console.log(`${key}: ${JSON.stringify(value)}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

getFullProduct();
