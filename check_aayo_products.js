const projectId = 'print-5cc56';
const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';

async function checkAayoProducts() {
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products?key=${apiKey}`;
    const res = await fetch(url);
    const data = await res.json();
    
    console.log('🔍 ALL PRODUCTS WITH category = "cat-1780725700997" (aayo):\n');
    
    let found = 0;
    (data.documents || []).forEach(doc => {
      const fields = doc.fields || {};
      const id = doc.name.split('/').pop();
      const category = fields.category?.stringValue;
      const name = fields.name?.stringValue;
      const basePrice = fields.basePrice?.integerValue;
      
      if (category === 'cat-1780725700997') {
        found++;
        console.log(`Product ${found}:`);
        console.log(`  id: ${id}`);
        console.log(`  name: "${name || '(EMPTY)'}"`);
        console.log(`  category: ${category}`);
        console.log(`  basePrice: ${basePrice || '(MISSING)'}`);
        console.log();
      }
    });
    
    if (found === 0) {
      console.log('❌ NO PRODUCTS FOUND with category="cat-1780725700997"');
    } else {
      console.log(`✅ Total products in "aayo" category: ${found}`);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkAayoProducts();
