# Solar Ops Mobile

Flutter mobile client for the Solar Ops workflow.

The app connects to the Solar Ops backend. Three tabs cover daily work: Trips, Stock and History. Switch the selected company from the title; Drivers and WhatsApp are in the menu.

Trips group bills together, support PDF upload and require a driver before being marked ready. Bill details support review, audited corrections and cancellation. History groups recent bills by trip and shows the full IST day's deduplicated bill count and can search older saved bills. Stock shows current known balances and supports audited physical counts.

After the initial authorized sign-in, a 90-day mobile session and encrypted local snapshot let the app show saved data before the network refresh completes. The snapshot can be stale when offline. Optional device lock uses the phone's fingerprint/biometrics or OS PIN/pattern; it is off by default. Server authentication remains required. Company selection filters one operator's data; it is not separate tenant access control.

Original PDFs expire after 24 hours through the backend's hourly cleanup. Structured bill data and trip links remain. Ready means stock checks and driver assignment passed, not delivery confirmation.

## Run locally

```bash
flutter pub get
flutter run
```

## Checks

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --release
```

GitHub Actions runs analysis, tests, web and Android builds on pushes and pull requests to `main`. It uploads the APK and screenshots of a synthetic mobile-sized UI fixture. The APK currently uses the repository's existing debug signing configuration; a production keystore is not included. Physical fingerprint and real-phone startup timing still require device verification.

## Daily workflow update (0.4.0)
New Trip opens a short manual dispatch form: company from the switcher, place, driver, product quantities and site count (one by default). Owner is optional. Trip from bills preserves PDF upload and existing-bill attachment separately. Manual dispatch writes stock OUT exactly once and cannot accept bills that would double-deduct it.
Driver selection and new-trip previews appear immediately as Saving; writes are confirmed only by the server. Rejected driver changes roll back. Failed trip saves retain entered values and retry with the same UUID; pending/failed previews are not cached as saved. A confirmed write no longer waits for home refresh. Late refresh responses cannot overwrite newer edits.
Stock shows Today dispatched per product/unit and Balance stock. Product choices include zero balances and canonical recorded bill suggestions. Existing-product Add Stock means quantity received; tapping a balance performs a physical count. Company creation is in the switcher with GSTIN and duplicate checks. Similar-product/company overrides are requested only after a server warning. Monetary values are hidden from the primary mobile screens. Unknown physical balances never display as confirmed zero.
The backend migration and APIs must be deployed before using these new forms. Tests use synthetic data and delayed/rejected requests; they do not measure latency on a real phone.
