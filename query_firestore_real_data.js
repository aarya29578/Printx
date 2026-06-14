/**
 * DIRECT FIRESTORE QUERY
 * Reads actual Firestore documents using REST API
 * No service account needed - uses API key from admin_panel/.env
 */

const projectId = 'print-5cc56';
const apiKey = 'AIzaSyBQl6PYWhsC4T2GXGf42GDW31PPnBF2Axc';

async function queryFirestore() {
  try {
    console.log('🔍 Querying Firestore REST API...\n');
    
    // Query categories collection
    console.log('📂 Fetching categories collection...');
    const categoriesUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/categories?key=${apiKey}`;
    
    const categoriesRes = await fetch(categoriesUrl);
    if (!categoriesRes.ok) {
      throw new Error(`Categories query failed: ${categoriesRes.status} ${categoriesRes.statusText}`);
    }
    
    const categoriesData = await categoriesRes.json();
    const categories = (categoriesData.documents || []).map(doc => {
      const fields = doc.fields || {};
      return {
        id: doc.name.split('/').pop(),
        name: fields.name?.stringValue,
        productCount: fields.productCount?.integerValue,
        icon: fields.icon?.stringValue,
        color: fields.color?.stringValue,
      };
    });
    
    console.log(`✅ Found ${categories.length} categories\n`);
    
    // Find "aayo" category
    const aayoCategory = categories.find(c => c.name === 'aayo');
    if (!aayoCategory) {
      console.log('❌ Category "aayo" not found');
      console.log('Available categories:', categories.map(c => c.name).join(', '));
      return;
    }
    
    console.log('='.repeat(80));
    console.log('FOUND CATEGORY: "aayo"');
    console.log('='.repeat(80));
    console.log(`\nCategory Document:\n`);
    console.log(`  Document ID (category.id): "${aayoCategory.id}"`);
    console.log(`  Name (category.name): "${aayoCategory.name}"`);
    console.log(`  productCount: ${aayoCategory.productCount}`);
    console.log(`  icon: "${aayoCategory.icon}"`);
    console.log(`  color: "${aayoCategory.color}"`);
    
    // Query products collection
    console.log('\n📦 Fetching products collection...');
    const productsUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products?key=${apiKey}`;
    
    const productsRes = await fetch(productsUrl);
    if (!productsRes.ok) {
      throw new Error(`Products query failed: ${productsRes.status} ${productsRes.statusText}`);
    }
    
    const productsData = await productsRes.json();
    const products = (productsData.documents || []).map(doc => {
      const fields = doc.fields || {};
      return {
        id: doc.name.split('/').pop(),
        name: fields.name?.stringValue,
        category: fields.category?.stringValue,
        basePrice: fields.basePrice?.integerValue,
      };
    });
    
    console.log(`✅ Found ${products.length} products\n`);
    
    // Find products with category = "aayo"
    const aayoProducts = products.filter(p => p.category === aayoCategory.id || p.category === aayoCategory.name);
    
    console.log('='.repeat(80));
    console.log(`PRODUCTS WITH CATEGORY "aayo" (found ${aayoProducts.length})`);
    console.log('='.repeat(80));
    
    if (aayoProducts.length === 0) {
      console.log('\n❌ NO PRODUCTS FOUND for category "aayo"');
      console.log('\nAnalyzing all products to see what categories exist:\n');
      const allCategories = [...new Set(products.map(p => p.category))];
      console.log('Product category values:', allCategories);
      
      console.log('\n🔎 Checking for category mismatches...\n');
      products.slice(0, 5).forEach(p => {
        console.log(`Product: ${p.id}`);
        console.log(`  product.category = "${p.category}" (TYPE: ${typeof p.category})`);
        console.log(`  Match with category.id "${aayoCategory.id}"? ${p.category === aayoCategory.id ? '✅ YES' : '❌ NO'}`);
        console.log(`  Match with category.name "${aayoCategory.name}"? ${p.category === aayoCategory.name ? '✅ YES' : '❌ NO'}\n`);
      });
    } else {
      aayoProducts.forEach((p, idx) => {
        console.log(`\nProduct ${idx + 1}:`);
        console.log(`  Document ID (product.id): "${p.id}"`);
        console.log(`  Name: "${p.name}"`);
        console.log(`  Category (product.category): "${p.category}"`);
        console.log(`  Price: ${p.basePrice}`);
      });
      
      // Test the comparison
      console.log('\n' + '='.repeat(80));
      console.log('COMPARISON TEST');
      console.log('='.repeat(80));
      
      const firstProduct = aayoProducts[0];
      console.log(`\nproduct.category = "${firstProduct.category}"`);
      console.log(`category.id = "${aayoCategory.id}"`);
      console.log(`category.name = "${aayoCategory.name}"\n`);
      
      console.log(`Test 1: product.category == category.id`);
      console.log(`  "${firstProduct.category}" == "${aayoCategory.id}"`);
      console.log(`  Result: ${firstProduct.category === aayoCategory.id ? '✅ TRUE' : '❌ FALSE'}\n`);
      
      console.log(`Test 2: product.category == category.name`);
      console.log(`  "${firstProduct.category}" == "${aayoCategory.name}"`);
      console.log(`  Result: ${firstProduct.category === aayoCategory.name ? '✅ TRUE' : '❌ FALSE'}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

queryFirestore();
