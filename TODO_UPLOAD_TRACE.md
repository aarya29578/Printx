# TODO_UPLOAD_TRACE.md

- [x] Add temporary logs in `UploadService`:
  - [ ] IMAGE PICKED is printed by callers
  - [x] UPLOAD STARTED
  - [x] UPLOAD PATH
  - [x] putFile success/failure
  - [x] getDownloadURL success/failure
  - [x] UPLOAD SUCCESS
- [x] Add temporary logs in `EditProfileScreen`:
  - [x] IMAGE PICKED printed after picking
  - [ ] UPLOAD PATH is logged before calling UploadService (if available)
  - [x] FIRESTORE UPDATE SUCCESS printed after update
  - [x] FIRESTORE UPDATE FAILURE printed on catch
- [x] Add temporary logs in `ProfileScreen`:
  - [x] PROFILE IMAGE FIELD READ printed for `profileImage`

- [ ] Trace product image flow completely:
  - [ ] Locate product image pick/upload screen and upload call
  - [ ] Identify UploadService usage for product images (or alternative service)
- [ ] After logs are added:
  - [ ] Run one successful product upload and capture full logs
  - [ ] Run one failing profile upload and capture full logs
  - [ ] Identify the exact failing step from logs
- [ ] Only after proof: change logic to fix profile upload to match product flow

