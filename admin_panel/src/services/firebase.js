import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore, serverTimestamp } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

const requiredKeys = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId']

// Determine whether env has all required keys at build time
let isFirebaseConfigured = requiredKeys.every((key) => Boolean(firebaseConfig[key]))

let app = null
let auth = null
let db = null
let storage = null

// Try to initialize Firebase if minimal config is present. This makes the
// admin panel more resilient in dev where env injection or HMR timing may
// cause the initial check to be false. We avoid hardcoding secrets here;
// we only use values from import.meta.env which are already part of the
// app environment.
const hasMinimalConfig = Boolean(firebaseConfig.projectId && firebaseConfig.apiKey && firebaseConfig.appId)
if (hasMinimalConfig) {
  try {
    app = initializeApp(firebaseConfig)
    auth = getAuth(app)
    db = getFirestore(app)
    storage = getStorage(app)
    isFirebaseConfigured = Boolean(db)
  } catch (err) {
    // Initialization failed; keep using local mock data but log for debugging
    // (do not print secrets)
    // eslint-disable-next-line no-console
    console.warn('Firebase initialization failed:', err?.message || err)
    isFirebaseConfigured = false
  }
} else {
  // If minimal config is not present, warn once.
  // eslint-disable-next-line no-console
  console.warn('Firebase is not configured. Using local mock data until env vars are provided.')
}

export { isFirebaseConfigured, app, auth, db, storage, serverTimestamp }
