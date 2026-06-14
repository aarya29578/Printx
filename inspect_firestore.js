// Script to inspect actual Firestore documents
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Try to find service account key
const possiblePaths = [
  path.join(__dirname, 'firebase-key.json'),
  path.join(__dirname, 'serviceAccountKey.json'),
  path.join(__dirname, 'admin_panel', 'firebase-key.json'),
  path.join(__dirname, 'android', 'google-services.json'),
];

let keyPath = null;
for (const p of possiblePaths) {
  if (fs.existsSync(p)) {
    keyPath = p;
    break;
  }
}

if (!keyPath) {
  console.log('❌ No service account key found. Checking for .env files...');
  const envFile = path.join(__dirname, 'admin_panel', '.env');
  if (fs.existsSync(envFile)) {
    console.log('✅ Found .env file. Contents:');
    console.log(fs.readFileSync(envFile, 'utf8'));
  }
  process.exit(1);
}

console.log(`✅ Using service account: ${keyPath}`);
const serviceAccount = require(keyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const db = admin.firestore();

async function inspectFirestore() {
  try {
    console.log('\n=== FETCHING CATEGORIES ===');
    const categoriesSnap = await db.collection('categories').get();
    console.log(`Total categories: ${categoriesSnap.size}`);
    
    const categories = {};
    categoriesSnap.forEach((doc) => {
      categories[doc.id] = doc.data();
      console.log(`\n📁 Category ID: ${doc.id}`);
      console.log(`   Name: ${doc.data().name}`);
      console.log(`   productCount: ${doc.data().productCount}`);
    });

    console.log('\n\n=== FETCHING PRODUCTS ===');
    const productsSnap = await db.collection('products').get();
    console.log(`Total products: ${productsSnap.size}`);
    
    productsSnap.forEach((doc) => {
      const product = doc.data();
      console.log(`\n🛍️  Product ID: ${doc.id}`);
      console.log(`   Name: ${product.name}`);
      console.log(`   category (RAW VALUE): "${product.category}"`);
      console.log(`   category (TYPE): ${typeof product.category}`);
      
      // Try to find matching category
      const matchedCategory = Object.entries(categories).find(([id, cat]) => {
        const match = product.category === id;
        console.log(`      Comparing "${product.category}" == "${id}"? ${match}`);
        return match;
      });
      
      if (matchedCategory) {
        console.log(`   ✅ Matches category ID: ${matchedCategory[0]} (name: ${matchedCategory[1].name})`);
      } else {
        console.log(`   ❌ NO MATCH FOUND. Looking for "${product.category}" in categories.`);
        console.log(`      Available category IDs: ${Object.keys(categories).join(', ')}`);
      }
    });

    // Specific check for "aayo"
    console.log('\n\n=== LOOKING FOR "aayo" ===');
    const aayoCategory = Object.entries(categories).find(([id, cat]) => 
      cat.name === 'aayo' || id === 'aayo' || id.includes('aayo')
    );
    
    if (aayoCategory) {
      console.log(`✅ Found category "aayo"`);
      console.log(`   Category ID: ${aayoCategory[0]}`);
      console.log(`   Category Data:`, JSON.stringify(aayoCategory[1], null, 2));
      
      const aayoProducts = [];
      productsSnap.forEach((doc) => {
        if (doc.data().category === aayoCategory[0]) {
          aayoProducts.push({ id: doc.id, ...doc.data() });
        }
      });
      console.log(`\n   Products in this category: ${aayoProducts.length}`);
      aayoProducts.forEach((p) => {
        console.log(`   - ${p.id}: ${p.name}`);
      });
    } else {
      console.log('❌ Category "aayo" not found');
      console.log(`Available categories: ${Object.entries(categories).map(([id, c]) => `${id}(${c.name})`).join(', ')}`);
    }

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

inspectFirestore().then(() => {
  admin.app().delete();
  process.exit(0);
});
