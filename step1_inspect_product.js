const projectId = 'print-5cc56';
const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';

async function inspectProduct() {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products/PRD1780725731834?key=${apiKey}`;
  const res = await fetch(url);
  const doc = await res.json();
  const fields = doc.fields || {};
  
  console.log('📦 FIRESTORE PRODUCT: PRD1780725731834\n');
  console.log('FIELD\t\t\tVALUE\t\t\t\tTYPE');
  console.log('='.repeat(100));
  
  const extract = (val) => {
    if (val.stringValue !== undefined) return [val.stringValue, 'string'];
    if (val.integerValue !== undefined) return [val.integerValue, 'integer'];
    if (val.doubleValue !== undefined) return [val.doubleValue, 'double'];
    if (val.booleanValue !== undefined) return [val.booleanValue, 'boolean'];
    if (val.arrayValue !== undefined) return [(val.arrayValue.values?.length || 0) + ' items', 'array'];
    if (val.nullValue !== undefined) return ['null', 'null'];
    return [JSON.stringify(val), 'unknown'];
  };
  
  const requiredFields = ['id', 'name', 'category', 'description', 'imageUrl', 'status', 'basePrice', 'originalPrice', 'sizes', 'finishes', 'tags', 'rating', 'reviewCount', 'isBestseller', 'minQty', 'quantities', 'badge'];
  
  requiredFields.forEach(field => {
    if (fields[field]) {
      const [val, type] = extract(fields[field]);
      const displayVal = typeof val === 'string' && val.length > 40 ? val.substring(0, 40) + '...' : val;
      console.log(`${field.padEnd(20)}\t${String(displayVal).padEnd(30)}\t${type}`);
    } else {
      console.log(`${field.padEnd(20)}\tMISSING\t\t\t\tN/A`);
    }
  });
  
  console.log('\n' + '='.repeat(100));
  console.log('ANALYSIS:');
  console.log(`❌ name is EMPTY: "${fields.name?.stringValue || 'MISSING'}"`);
  console.log(`❌ basePrice is MISSING: ${fields.basePrice ? 'EXISTS' : 'MISSING'}`);
  console.log(`✅ category is CORRECT: "${fields.category?.stringValue}"`);
  console.log(`✅ category == "cat-1780725700997": ${fields.category?.stringValue === 'cat-1780725700997'}`);
}

inspectProduct();
