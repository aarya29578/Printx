# TODO: Profile screen uses Firestore user data only

- [ ] Edit `lib/features/profile/profile_screen.dart`
  - [ ] Remove ALL hardcoded profile values (Raj Kumar, email, stats, dummy image)
  - [ ] Load current Firebase user via `FirebaseAuth.instance.currentUser`
  - [ ] Listen to Firestore doc: `users/{uid}` via realtime stream
  - [ ] Display only: profileImage, fullName, email, phone, address
  - [ ] If any field missing: show empty state (no fake fallback values)
  - [ ] Keep sign-out + existing menu UI
- [ ] Run `flutter analyze`
- [ ] Confirm behaviour: profile screen uses Firestore user data only

