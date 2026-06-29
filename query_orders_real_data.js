/**
 * DIRECT FIRESTORE QUERY (REST API)
 * Fetches a small sample of documents from the real `orders` collection
 * and prints the raw Firestore field names/values.
 */

// Keep in sync with existing query_firestore_real_data.js
const projectId = 'print-5cc56';
const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';

function unwrap(val) {
  if (!val || typeof val !== 'object') return val;
  if ('stringValue' in val) return val.stringValue;
  if ('integerValue' in val) return Number(val.integerValue);
  if ('doubleValue' in val) return Number(val.doubleValue);
  if ('booleanValue' in val) return val.booleanValue;
  if ('timestampValue' in val) return val.timestampValue;
  if ('nullValue' in val) return null;
  if ('mapValue' in val) return Object.fromEntries(Object.entries(val.mapValue.fields || {}).map(([k, v]) => [k, unwrap(v)]));
  if ('arrayValue' in val) return (val.arrayValue.values || []).map(unwrap);
  if ('referenceValue' in val) return val.referenceValue;
  return val;
}

async function queryOrders() {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/orders?pageSize=5&key=${apiKey}`;
  console.log('🔍 Querying Firestore REST API for /orders...');
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Orders query failed: ${res.status} ${res.statusText}`);
  const data = await res.json();

  const docs = data.documents || [];
  console.log(`✅ Found ${docs.length} order docs (pageSize=5)`);

  docs.forEach((doc, idx) => {
    const fields = doc.fields || {};
    console.log('\n' + '='.repeat(100));
    console.log(`Order sample #${idx + 1}`);
    console.log(`Document path: ${doc.name}`);
    console.log('Top-level field names:', Object.keys(fields));
    console.log('Raw field snapshot (unwrapped):');

    const unwrapped = {};
    for (const [k, v] of Object.entries(fields)) {
      unwrapped[k] = unwrap(v);
    }
    console.log(JSON.stringify(unwrapped, null, 2));
  });
}

queryOrders().catch((e) => {
  console.error('❌ Error:', e.message);
});

