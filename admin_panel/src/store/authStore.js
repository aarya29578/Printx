import { create } from 'zustand'
import { auth, isFirebaseConfigured } from '../services/firebase'
import { onAuthStateChanged, signInWithEmailAndPassword, signOut, sendPasswordResetEmail as fbSendPasswordResetEmail, EmailAuthProvider, reauthenticateWithCredential, updateEmail as fbUpdateEmail, updatePassword as fbUpdatePassword } from 'firebase/auth'

export const useAuthStore = create((set) => {
  // initial state before Firebase initializes
  set({ admin: null, isAuthenticated: false })

  if (isFirebaseConfigured && auth) {
    onAuthStateChanged(auth, (user) => {
      if (user) {
        const admin = { id: user.uid, name: user.displayName || '', email: user.email }
        set({ admin, isAuthenticated: true })
      } else {
        set({ admin: null, isAuthenticated: false })
      }
    })
  }

  const login = async (email, password) => {
    if (!isFirebaseConfigured || !auth) {
      throw new Error('Firebase not configured')
    }
    const resp = await signInWithEmailAndPassword(auth, email, password)
    const user = resp.user
    if (user) {
      set({ admin: { id: user.uid, name: user.displayName || '', email: user.email }, isAuthenticated: true })
      return true
    }
    return false
  }

  const logout = async () => {
    if (isFirebaseConfigured && auth) {
      try {
        await signOut(auth)
      } catch (e) {
        // ignore sign out errors but clear local state
      }
    }
    set({ admin: null, isAuthenticated: false })
  }

  const sendPasswordReset = async (email) => {
    if (!isFirebaseConfigured || !auth) throw new Error('Firebase not configured')
    return fbSendPasswordResetEmail(auth, email)
  }

  const reauthenticate = async (currentEmail, currentPassword) => {
    if (!isFirebaseConfigured || !auth) throw new Error('Firebase not configured')
    const user = auth.currentUser
    if (!user) throw new Error('Not authenticated')
    const cred = EmailAuthProvider.credential(currentEmail, currentPassword)
    return reauthenticateWithCredential(user, cred)
  }

  const changeEmail = async (newEmail, currentPassword) => {
    if (!isFirebaseConfigured || !auth) throw new Error('Firebase not configured')
    const user = auth.currentUser
    if (!user) throw new Error('Not authenticated')
    await reauthenticate(user.email, currentPassword)
    await fbUpdateEmail(user, newEmail)
    set({ admin: { id: user.uid, name: user.displayName || '', email: newEmail } })
  }

  const changePassword = async (currentPassword, newPassword) => {
    if (!isFirebaseConfigured || !auth) throw new Error('Firebase not configured')
    const user = auth.currentUser
    if (!user) throw new Error('Not authenticated')
    await reauthenticate(user.email, currentPassword)
    await fbUpdatePassword(user, newPassword)
  }

  return {
    admin: null,
    isAuthenticated: false,
    login,
    logout,
    sendPasswordReset,
    changeEmail,
    changePassword,
  }
})
