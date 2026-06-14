async function getProduct() {
  const projectId = 'print-5cc56';
  const productId = 'PRD1780725731834';
  const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';
  
  try {
    const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/-default-/documents/products/${productId}?key=${apiKey}`,
      { method: 'GET' }
    );
    
    if (!response.ok) {
      console.error(`Error: ${response.status}`);
      return;
    }
    
    const data = await response.json();
    const fields = data.fields || {};
    
    console.log('\n========================================');
    console.log('FIRESTORE PRODUCT: PRD1780725731834');
    console.log('========================================\n');
    
    console.log('ALL FIELDS IN FIRESTORE:');
    console.log('------------------------');
    Object.keys(fields).sort().forEach(key => {
      const field = fields[key];
      let value = null;
      
      if (field.stringValue !== undefined) value = field.stringValue === '' ? '(EMPTY STRING)' : `"${field.stringValue}"`;
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
    const isEmpty = (val) => val === undefined || val === null || val === '';
    const name = fields.name?.stringValue;
    const imageUrl = fields.imageUrl?.stringValue;
    const basePrice = fields.basePrice?.doubleValue !== undefined ? fields.basePrice.doubleValue : fields.basePrice?.integerValue;
    const status = fields.status?.stringValue;
    
    console.log(`  id: ${fields.id?.stringValue || '❌ MISSING'}`);
    console.log(`  name: ${isEmpty(name) ? '❌ EMPTY or MISSING' : `"${name}"`}`);
    console.log(`  category: ${fields.category?.stringValue || '❌ MISSING'}`);
    console.log(`  description: ${fields.description?.stringValue || '❌ MISSING'}`);
    console.log(`  imageUrl: ${isEmpty(imageUrl) ? '❌ MISSING' : `"${imageUrl}"`}`);
    console.log(`  status: ${status || '❌ MISSING'}`);
    console.log(`  basePrice: ${basePrice !== undefined ? basePrice : '❌ MISSING'}`);
    console.log(`  originalPrice: ${fields.originalPrice?.doubleValue !== undefined ? fields.originalPrice.doubleValue : (fields.originalPrice?.integerValue || '❌ MISSING')}`);
    console.log(`  sizes: ${fields.sizes?.arrayValue?.values?.length || 0} items`);
    console.log(`  finishes: ${fields.finishes?.arrayValue?.values?.length || 0} items`);
    console.log(`  tags: ${fields.tags?.arrayValue?.values?.length || 0} items`);
    
    console.log('\n========================================\n');
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

getProduct();
