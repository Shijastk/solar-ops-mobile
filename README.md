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
### Daily navigation and trip controls

Tap the company title at the top to switch/create a company. The bottom bar contains only Trips, Stock and History. Profile and Settings are in the three-dot menu; device lock is optional and sessions stay saved. Company Profile has a display name, read-only GSTIN and a photo resized/cropped on device to 128px PNG. Photos load on opening Profile, never at app startup. The profile label does not change canonical company identity.

Lists hide empty trips; manual creation offers a hidden optional trip name, defaulting to place. A trip menu supports rename and Delete. Delete removes the group without deleting bills or returning stock; stock correction remains separate. Ready trips have Mark completed, which adds no stock deduction. Recent trip search includes place, name, driver, vehicle, products and bill numbers; existing stock/history search remains. Payments are deferred until operator review.

## Save-only workflow (0.5.0)

Manual creation normally shows place, driver, product and quantity. Site count defaults to one; a single More details expansion contains site adjustment, owner and optional name. Add driver lives in the driver picker. Existing product units are reused.

Opening Trip from bills and selecting PDFs makes no server request or stock change. PDFs stay in the in-memory draft (up to 30 bills / 24 MiB total, each at most 4 MiB) until Save trip. Save uploads/checks each PDF, then atomically creates the group and links its bills. Upload UUIDs and the group UUID are reused on retry. Review-required bills stay in a saved collecting group, not falsely ready. Duplicate-only selections create no group. A failed group save may leave explicitly uploaded bills in History; it does not roll back independent verified bill movements. Leave warns accordingly. Unsaved PDF bytes are not crash-persistent. Save currently keeps the draft page open until acknowledgement; this is not a durable background upload service.

Stock removes Today dispatched. Two cards show Completed today and To complete; a bottom bar chart shows completed trips over 7/30 India-time days. Counts are full-database aggregates, independent of the 60 recent trip rows. All companies counts each trip once even if it contains bills from multiple companies. Ready is not counted as completed. Missing summaries say Unavailable, not zero. The chart is activity, not sales revenue or payment collection. Individual bars expose exact daily counts; 30-day bars scroll horizontally. Unknown physical balances remain Not recorded.

Backend upload logs measure storage/parsing/verification separately without file names or business identifiers. Client timeout covers the whole response, not only headers. CI and synthetic SQL tests are verification gates; physical-phone processing speed and PDF picker still require device acceptance.
