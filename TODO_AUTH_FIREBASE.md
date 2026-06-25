# TODO: Firebase Authentication Integration

## 1) Prepare
- [x] Create backup/reset working tree
- [x] Create branch `blackboxai/auth-firebase`

## 2) Implement auth backend
- [ ] Add auth user Firestore helper service (users/{uid} doc creation + fetch)
- [ ] Replace `AuthCubit` mock logic with FirebaseAuth + Firestore user document storage
- [ ] Update `AuthCubit` auto-login using `FirebaseAuth.instance.currentUser`
- [ ] Implement proper logout using `FirebaseAuth.instance.signOut()`

## 3) Update app entry navigation
- [ ] Update Splash to use Firebase currentUser instead of local token

## 4) Update validation to match task rules
- [ ] Adjust Validators: fullName min 3, phone min 10 digits (digits-only), password min 6

## 5) Keep UI intact
- [ ] Ensure Register/Login screens keep their current widgets and only rely on updated AuthCubit states
- [ ] Bypass OTP flow for email/password registration (keep OTP screen code intact)

## 6) Verification
- [ ] Test checklist: register/login error messages, Firestore doc creation, session persistence, logout
- [ ] Produce final report: files changed, flow diagram, test checklist, verification logs

