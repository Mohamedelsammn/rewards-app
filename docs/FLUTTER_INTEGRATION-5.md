# Creative Rewards — Flutter Integration Guide (v1, verified)

This guide describes the backend **as implemented and tested**. Every route in §4 exists in `server/src/v1/` and is checked by an automated test (`server/test/contract.test.js`) that fails if this table and the running router ever differ. All JSON examples in §5 were captured from real responses of the running server; only tokens are shortened.

Give this file to the developer or agent working in the Flutter repo (`com.creativehub.rewardsapp`) with this instruction: **"Implement `DATA_MODE=api` against this backend, following this guide. Do not change API contracts; report mismatches instead."**

> **Email OTP is required.** Registration needs a one-time `verificationToken` obtained by verifying a 6-digit code sent by email. Keep the existing OTP screen; it is part of the api flow.

## 1. Base URL: intentionally empty

The production domain has not been assigned yet and will be provided later. Do not hard-code any host.

```dart
// lib/core/config/environment.dart
class Environment {
  /// Full API root ending with /api/v1 and no trailing slash, e.g. https://<domain>/api/v1
  /// Intentionally empty until the backend domain is provided.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
}
```

- Run with `flutter run --dart-define=DATA_MODE=api --dart-define=API_BASE_URL=<provided later>`.
- If `apiBaseUrl` is empty, keep showing the existing "service not connected" screen. Do not crash.
- Local testing only (debug builds): Android emulator `http://10.0.2.2:3000/api/v1`, physical device `http://<LAN-IP>:3000/api/v1`. Release builds must use HTTPS.
- Media URLs (`imageUrl`) are absolute URLs served by the same backend (`https://<domain>/media/<file>`) and may be `null`. Always show a placeholder for `null` or failed images.

## 2. Contract rules (apply to every endpoint)

| Topic | Rule |
|---|---|
| Format | JSON request and response bodies. UTF-8. Send `Content-Type: application/json`. |
| Auth | `Authorization: Bearer <accessToken>` on routes marked **User**. Routes marked **Public** need no token. **Optional** routes return extra per-user data when a token is sent. |
| Tokens | `accessToken` expires after **900 s**; `refreshToken` after **30 days** and **rotates on every refresh**. Store both only in `flutter_secure_storage`. |
| IDs | UUID strings, except avatar IDs (integers 1–9 for the bundled characters) and wallet transaction IDs (numeric strings). |
| Time | ISO-8601 UTC strings (e.g. `2026-10-21T00:36:31.232Z`). Use `serverTime` from `/app-config` for countdowns if the device clock is unreliable. |
| Localized text | Objects `{ "ar": "...", "en": "..." }`. The app chooses the language. |
| Numbers | Points, prices and balances are integers. Never compute balances on the device. |
| Pagination | Cursor lists accept `limit` (1–100, default 20) and `cursor`; they return `{ items, nextCursor }`, with `nextCursor: null` on the last page. Unpaginated lists return `{ items }`. |
| Idempotency | `POST /orders` **requires** `Idempotency-Key` (8–100 chars `[A-Za-z0-9_-]`, use a UUID). A retry with the same key and body replays the original response (header `Idempotent-Replayed: true`). The same key with a different body returns `409 IDEMPOTENCY_KEY_REUSED`. |
| Caching | All API responses carry `Cache-Control: no-store`. Admin changes to catalog, prices, stock, giveaways and settings are visible on the next request. Do not keep catalog caches longer than the current screen session. |
| Errors | `{ "error": { "code", "message", "details"? }, "requestId" }`. Localize by `code`; `message` is English and only for logs. Show `requestId` in support screens. |
| Rate limits | 600 requests/min per IP overall, 20 failed auth attempts per IP per 15 min, and 10 OTP emails per IP per 15 min → `429 RATE_LIMITED`. |
| Validation | Invalid bodies, queries and path IDs (e.g. a malformed UUID) return `422 VALIDATION_FAILED` with `details.fields`. |

### Error codes

| HTTP | Code | When / app behavior |
|---|---|---|
| 400 | `INVALID_JSON` | Malformed JSON body |
| 400 | `INVALID_CURSOR` | Corrupted cursor → reload the list from the start |
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | Missing or invalid `Idempotency-Key` on `POST /orders` |
| 401 | `UNAUTHENTICATED` | No or invalid token, or the account is not active |
| 401 | `TOKEN_EXPIRED` | Access token expired or revoked → refresh once, then retry |
| 401 | `INVALID_REFRESH_TOKEN` | Refresh token invalid, expired, revoked or reused → clear tokens, go to login |
| 401 | `INVALID_CREDENTIALS` | Wrong email or password |
| 403 | `ACCOUNT_SUSPENDED` | Show the suspended screen; do not retry |
| 403 | `FEATURE_DISABLED` | Feature switched off by admin (ad rewards, social-media products) |
| 404 | `NOT_FOUND` | Missing, unpublished, hidden or another user's resource |
| 409 | `EMAIL_TAKEN` | Registration with an existing email |
| 409 | `REFRESH_ALREADY_ROTATED` | Another concurrent request already refreshed with this token → reload tokens from storage and retry. Not a logout |
| 409 | `INSUFFICIENT_POINTS` | `details: { balance, required }` |
| 409 | `OUT_OF_STOCK` | Product stock is 0 |
| 409 | `PRICE_CHANGED` | `details: { pointsPrice }` (the new price) → confirm with the user, then resend with the new `expectedPointsPrice` and a new idempotency key |
| 409 | `INVALID_TRANSITION` | Cancel on an order that is no longer `PENDING` |
| 409 | `IDEMPOTENCY_KEY_REUSED`, `REQUEST_IN_PROGRESS` | Idempotency conflicts (see §2) |
| 409 | `GIVEAWAY_NOT_STARTED`, `GIVEAWAY_ENDED`, `GIVEAWAY_NOT_ACTIVE`, `GIVEAWAY_FULL` | Entry or step not possible now |
| 409 | `STEPS_INCOMPLETE` | Required steps missing; `details: { remaining }` |
| 409 | `CLAIM_NOT_ALLOWED` | Prize already claimed, forfeited or past the deadline |
| 422 | `VALIDATION_FAILED` | `details.fields` maps field → message. For order fulfilment fields the values are `REQUIRED`, `INVALID_FORMAT`, `INVALID_OPTION` or `UNKNOWN_FIELD` |
| 422 | `OTP_INVALID` | Wrong code; `details.attemptsLeft` |
| 422 | `OTP_EXPIRED` | Code older than 10 minutes → request a new one |
| 422 | `OTP_ATTEMPTS_EXCEEDED` | 5 wrong attempts → request a new code |
| 422 | `OTP_VERIFICATION_INVALID` | `verificationToken` missing, expired, already used, or for another email/purpose → restart from email |
| 429 | `OTP_RESEND_COOLDOWN` | `details.retryAfter` seconds |
| 429 | `OTP_SEND_LIMIT` | More than 5 codes for this email in an hour |
| 429 | `OTP_LOCKED` | 15 wrong codes for this email within an hour → sending and verifying blocked for up to an hour (password sign-in still works) |
| 503 | `EMAIL_NOT_CONFIGURED` | Server has no mail credentials (should not happen in production) |
| 422 | `INVALID_PASSWORD` | Wrong current password (password change, account deletion) |
| 422 | `INVALID_AVATAR` | Unknown or inactive avatar ID |
| 422 | `PROOF_REQUIRED` | `ADMIN_REVIEW` step submitted without `proofText` |
| 429 | `RATE_LIMITED` | Back off |
| 429 | `DAILY_LIMIT_REACHED`, `DEVICE_LIMIT_REACHED` | Ad reward daily limits (when opening a session) |
| 429 | `COOLDOWN` | Wait `details.retryAfter` seconds before the next ad |
| 429 | `TOO_MANY_PENDING` | 3 ad sessions are still waiting for Google; wait for them |
| 403 | `INVALID_SIGNATURE` | SSV webhook only (never seen by the app) |
| 503 | `NUMBER_ALLOCATION_FAILED` | Rare; retry the giveaway entry |
| 500 | `INTERNAL_ERROR` | Retry with backoff; show `requestId` |

## 3. Implementation checklist

1. **HTTP client** (`dio`): base URL from `Environment.apiBaseUrl`, JSON headers, 15 s timeouts.
2. **Secure token storage** only. Never keep passwords or tokens in Hive or shared preferences.
3. **Auth interceptor**: attach the bearer token. On `401 TOKEN_EXPIRED` or `UNAUTHENTICATED`, run **one shared refresh** (a lock or `Completer` used by every request), save both new tokens, and retry the original request once. On `409 REFRESH_ALREADY_ROTATED`, re-read tokens from storage and retry. On `401 INVALID_REFRESH_TOKEN`, clear tokens and private caches, then go to login.
4. **Typed errors**: `ApiException(code, details, requestId, statusCode)`. Add AR/EN strings for every code in §2.
5. **Repository**: `ApiRewardsRepository implements RewardsRepository` (see the mapping in §6). Keep `LocalRewardsRepository` for `DATA_MODE=demo`.
6. **Models**: `LocalizedText { ar, en }`; integers for points; nullable `imageUrl`.
7. **Onboarding**: Email → `POST /auth/otp/send { email, purpose: "REGISTER", language }` → OTP screen → `POST /auth/otp/verify { email, purpose, code }` returns `verificationToken` (valid 30 min, single use) → Password → Character (avatar 1–9) → `POST /auth/register { email, verificationToken, password, avatarId, language }`. `name` is optional; when omitted the server uses the email's local part, and the user can edit it later with `PATCH /me`.
   - The send response is always `202 { sent, expiresIn: 600, resendAfter: 60 }`, even if the email already has an account (that person receives an "account exists" email instead of a code). Show a 60 s resend countdown; on `429 OTP_RESEND_COOLDOWN` use `details.retryAfter`.
   - Codes expire after 10 minutes, allow 5 wrong attempts (`details.attemptsLeft`), and a new code replaces the previous one. Max 5 codes per email per hour and 10 per day. If an email does not arrive, let the user resend after the countdown (delivery errors are not reported to the app).
   - **Forgot password**: `otp/send` with `purpose: "FORGOT_PASSWORD"` → `otp/verify` → `POST /auth/password/reset { email, verificationToken, newPassword }` → `204`, all sessions revoked → go to login.
8. **Redeem**: build the form from `GET /products/:id` → `product.fields` (`TEXT`, `NUMBER`, `URL`, `PHONE`, `EMAIL`, `SELECT` with `options`, optional `pattern` regex). Show `pointsPrice`; send `expectedPointsPrice`. Use one `Idempotency-Key` per confirm tap and reuse it for retries of that attempt. After success, use `balance` from the response.
9. **Wallet**: `GET /wallet` is the only balance source. Refresh it after orders, cancels and ad claims, and on resume.
10. **Rewarded ads (AdMob server-side verification)** — only if `/app-config` → `adRewards.enabled` is true (it is **false** until the AdMob policy gate in §7 is cleared):
    1. `GET /ad-rewards/status?deviceId=` → show `pointsPerCompletedAd`, `remainingToday`, `nextAvailableAt`.
    2. `POST /ad-rewards/sessions { deviceId, adUnitId }` → `{ session, ssv: { userId, customData } }`. Do this **before** loading the ad.
    3. Load the rewarded ad, then set SSV options **before** `show()`:
       ```dart
       await rewardedAd.setServerSideOptions(ServerSideVerificationOptions(userId: ssv.userId, customData: ssv.customData));
       rewardedAd.show(onUserEarnedReward: (ad, reward) { /* UX only — do not credit locally */ });
       ```
    4. After the ad is dismissed, show "verifying…" and poll `GET /ad-rewards/sessions/:id` every 2 s for up to 60 s (or call `POST /ad-rewards/claims { sessionId }`; same result). `CREDITED` → refresh `/wallet`; `REJECTED`/`EXPIRED` → show `rejectReason`; still `PENDING` after 60 s → "your points will appear shortly" and check again on the Wallet screen.
    5. Points are credited **only** by Google's signed callback to the server. The app never sends proof of a view; `onUserEarnedReward` is UX only. `deviceId` is a stable install UUID in secure storage. Abandoned sessions expire after 1 hour.
11. **Giveaways**: submit each required step via `/steps/:stepId/progress` (send `proofText` for `ADMIN_REVIEW`), then `POST /giveaways/:id/entries`. The returned `participationNumber` is a zero-padded string; display it as-is (LTR) and play the existing Lottie reveal. Re-joining returns the same number, so never generate numbers on the device.
12. **Celebration**: on app start, on resume and on a `WINNER_SELECTED` push, call `GET /me/winnings/pending-celebration`; show the celebration for each item, then `POST .../acknowledge-celebration`.
13. **Push**: after login and on every FCM token change, call `PUT /devices/{installationId}`. On logout, call `DELETE /devices/{installationId}` **before** `POST /auth/logout`. Treat push as a hint and reload the inbox.
14. **Badges**: Home and Profile badges read `GET /notifications/unread-count`; refresh it after read actions and on resume.
15. **App config**: on startup, enforce `minVersion` (force update), `maintenance` (blocking screen with `maintenanceMessage`) and `features`.
16. **Do not**: call Supabase in api mode, compute balances or numbers locally, hard-code the base URL, ask for third-party passwords or codes, or log tokens.

## 4. Endpoint reference

Auth column: **Public**, **User** (bearer required) or **Optional** (bearer adds per-user data).

| Method | Path | Auth | Request | Success |
|---|---|---|---|---|
| GET | `/health` | Public | — | `200 { status }` |
| POST | `/auth/otp/send` | Public | `{ email, purpose: "REGISTER"\|"FORGOT_PASSWORD", language?: "ar"\|"en" }` | `202 { sent, expiresIn, resendAfter }` |
| POST | `/auth/otp/verify` | Public | `{ email, purpose, code (6 digits) }` | `200 { verificationToken, expiresIn }` |
| POST | `/auth/register` | Public | `{ email, verificationToken, password (8–128), name? (2–60), avatarId?, language?: "ar"\|"en", deviceName? }` | `201 { tokens, user }` |
| POST | `/auth/password/reset` | Public | `{ email, verificationToken (FORGOT_PASSWORD), newPassword (8–128) }` | `204` (all sessions revoked) |
| POST | `/auth/login` | Public | `{ email, password, deviceName? }` | `200 { tokens, user }` (also cancels a pending account deletion) |
| POST | `/auth/refresh` | Public | `{ refreshToken }` | `200 { tokens }` |
| POST | `/auth/logout` | User | — | `204` (current session) |
| POST | `/auth/logout-all` | User | — | `204` (all sessions) |
| POST | `/auth/password/change` | User | `{ currentPassword, newPassword (8–128) }` | `204` (other sessions revoked) |
| GET | `/auth/sessions` | User | — | `200 { items }` |
| DELETE | `/auth/sessions/:id` | User | — | `204` |
| GET | `/me` | User | — | `200 { user }` |
| PATCH | `/me` | User | `{ name?, avatarId? (null clears), language? }` | `200 { user }` |
| DELETE | `/me` | User | `{ password }` | `202 { status: "DELETION_REQUESTED", graceDays: 14 }` |
| GET | `/me/notification-preferences` | User | — | `200 { preferences }` |
| PUT | `/me/notification-preferences` | User | `{ orders, giveaways, announcements }` (booleans, all required) | `200 { preferences }` |
| GET | `/avatars` | Public | — | `200 { items: [{ id, imageUrl }] }` |
| GET | `/app-config` | Public | — | `200` config object |
| GET | `/home` | Public | — | `200 { categories, featuredProducts, giveaways }` |
| GET | `/search` | Public | `?q (1–60)&types=categories,products,giveaways&limit (1–30, default 10)` | `200 { categories?, products?, giveaways? }` |
| GET | `/categories` | Public | — | `200 { items }` |
| GET | `/categories/:id` | Public | — | `200 { category }` (with `groups`) |
| GET | `/categories/:id/products` | Public | `?groupId` | `200 { items }` (no `fields`) |
| GET | `/products/:id` | Public | — | `200 { product }` (with `fields`) |
| GET | `/wallet` | User | — | `200 { wallet }` |
| GET | `/wallet/transactions` | User | `?type=A,B&limit&cursor` (cursor = last `id`) | `200 { items, nextCursor }` |
| POST | `/orders` | User | Header `Idempotency-Key`; `{ productId, fields: { key: string }, expectedPointsPrice? }` | `201 { order, balance }` |
| GET | `/orders` | User | `?statusGroup=IN_PROGRESS\|COMPLETED\|UNSUCCESSFUL&limit&cursor` | `200 { items, nextCursor }` |
| GET | `/orders/:id` | User | — | `200 { order }` (with `fields`, `deliveredCode`, `timeline`) |
| POST | `/orders/:id/cancel` | User | — | `200 { order, balance }` (only while `PENDING`) |
| GET | `/ad-rewards/status` | User | `?deviceId` | `200` status object |
| POST | `/ad-rewards/sessions` | User | `{ deviceId, adUnitId? }` | `201 { session, ssv: { userId, customData } }` |
| GET | `/ad-rewards/sessions/:id` | User | — | `200 { session }` (poll) |
| POST | `/ad-rewards/claims` | User | `{ sessionId }` | `200 { session, balance }` (reconcile only; never credits) |
| GET | `/webhooks/admob/ssv` | Public | Called by Google with signed query parameters | `200 { result }`; invalid signature `403` |
| GET | `/giveaways` | Public | `?status=AVAILABLE\|UPCOMING\|ENDED&q&limit&cursor` | `200 { items, nextCursor }` |
| GET | `/giveaways/:id` | Optional | — | `200 { giveaway, me }` (`me` is `null` without a token) |
| POST | `/giveaways/:id/steps/:stepId/progress` | User | `{ proofText? (≤500) }` | `200 { progress }` |
| POST | `/giveaways/:id/entries` | User | — | `201 { entry }`; already joined `200 { entry }` |
| GET | `/giveaways/:id/results` | Public | — | `200 { giveawayId, winners }` (404 until announced) |
| GET | `/me/entries` | User | `?result=PENDING\|WON\|NOT_SELECTED&limit&cursor` | `200 { items, nextCursor }` |
| GET | `/me/winnings/pending-celebration` | User | — | `200 { items }` |
| POST | `/me/winnings/:id/acknowledge-celebration` | User | — | `204` (idempotent) |
| POST | `/me/winnings/:id/claim` | User | `{ contact (3–500) }` | `200 { winning }` |
| GET | `/notifications` | User | `?unreadOnly=true&limit&cursor` | `200 { items, nextCursor }` |
| GET | `/notifications/unread-count` | User | — | `200 { count }` |
| GET | `/notifications/:id` | User | — | `200 { notification }` |
| POST | `/notifications/:id/read` | User | — | `204` (idempotent) |
| POST | `/notifications/read-all` | User | — | `204` (idempotent) |
| PUT | `/devices/:installationId` | User | `{ fcmToken \| null, platform: android\|ios, appVersion?, language: ar\|en }`; id 8–100 `[A-Za-z0-9_-]` | `204` |
| DELETE | `/devices/:installationId` | User | — | `204` |

### Status values

| Entity | Values |
|---|---|
| Order `status` | `PENDING` → `PROCESSING` → (`SHIPPED` → `DELIVERED` →) `COMPLETED`; unsuccessful: `REJECTED`, `CANCELLED`, `FAILED` |
| `statusGroup` filter | `IN_PROGRESS` = PENDING, PROCESSING, SHIPPED, DELIVERED · `COMPLETED` = COMPLETED · `UNSUCCESSFUL` = REJECTED, CANCELLED, FAILED |
| Refunds | Each REJECTED, CANCELLED or FAILED order gets exactly one `REDEMPTION_REFUND` transaction |
| Wallet transaction `type` | `SIGNUP_BONUS`, `AD_REWARD`, `REDEMPTION_DEBIT` (negative), `REDEMPTION_REFUND`, `ADMIN_CREDIT`, `ADMIN_DEBIT` (negative) |
| Category `kind` | `GAME`, `SOCIAL_MEDIA`, `PHYSICAL_GOODS`, `OTHER` |
| Field `type` | `TEXT`, `NUMBER` (digits only), `URL` (http/https), `PHONE`, `EMAIL`, `SELECT` (value must be one of `options`) |
| Giveaway `status` | `UPCOMING`, `ACTIVE`, `ENDED`, `WINNERS_SELECTED`, `COMPLETED`, `CANCELLED` |
| Giveaway list `status` filter | `AVAILABLE` (started, not ended), `UPCOMING`, `ENDED` |
| Step `verification` | `NONE` and `LINK_CLICK`: completed immediately when reported · `ADMIN_REVIEW`: `SUBMITTED` until an admin approves or rejects; rejecting a required step disqualifies the entry |
| Step progress `status` | `COMPLETED`, `SUBMITTED`, `APPROVED`, `REJECTED` (a rejected or submitted step can be resubmitted) |
| Entry `status` / `result` | `ACTIVE`, `DISQUALIFIED` / `PENDING`, `WON`, `NOT_SELECTED` |
| Winning `status` | `ANNOUNCED`, `CLAIMED`, `FULFILLED`, `FORFEITED` |
| Ad session `status` | `PENDING` (waiting for Google), `CREDITED`, `REJECTED` (`rejectReason`: `DAILY_LIMIT_REACHED`, `DEVICE_LIMIT_REACHED`, `FEATURE_DISABLED`, `ACCOUNT_INACTIVE`), `EXPIRED` (no callback within 1 h) |
| Notification `type` | `ORDER_STATUS` (`data.orderId`, `data.status`), `WINNER_SELECTED` (`data.giveawayId`, `data.winnerId`), `GIVEAWAY_RESULT` (`data.giveawayId`), `ANNOUNCEMENT` |

### Field names that look alike

| Name | Where | Meaning |
|---|---|---|
| `pointsPrice` | Product (catalog) | Current price of the product |
| `pointsCost` | Order | Points actually deducted when this order was created (frozen) |
| `product.pointsPrice` inside an order | Order snapshot | Price at order time (same as `pointsCost`) |
| `balance` | Responses of `POST /orders`, `/orders/:id/cancel`, `/ad-rewards/claims` | Wallet balance right after the operation |
| `wallet.balance` | `GET /wallet` | Current balance |
| `user.stats.points` | `/me`, login, register | Current balance (same source as `wallet.balance`) |
| `user.stats.giveaways` / `orders` | `/me` | Number of giveaway entries / orders the user created (all statuses) |

## 5. Real request/response examples

### Auth

**POST /auth/otp/send** → `202`

```json
// request
{
  "email": "player@example.test",
  "purpose": "REGISTER",
  "language": "ar"
}
```

```json
{
  "sent": true,
  "expiresIn": 600,
  "resendAfter": 60
}
```

**POST /auth/otp/send — again within 60 s** → `429`

```json
{
  "error": {
    "code": "OTP_RESEND_COOLDOWN",
    "message": "Wait before requesting another code.",
    "details": {
      "retryAfter": 60
    }
  },
  "requestId": "<request-id>"
}
```

**POST /auth/otp/verify — wrong code** → `422`

```json
// request
{
  "email": "player@example.test",
  "purpose": "REGISTER",
  "code": "000000"
}
```

```json
{
  "error": {
    "code": "OTP_INVALID",
    "message": "The code is incorrect.",
    "details": {
      "attemptsLeft": 4
    }
  },
  "requestId": "<request-id>"
}
```

**POST /auth/otp/verify** → `200`

```json
// request
{
  "email": "player@example.test",
  "purpose": "REGISTER",
  "code": "<6 digits from the email>"
}
```

```json
{
  "verificationToken": "<verificationToken>",
  "expiresIn": 1800
}
```

**POST /auth/register — invalid or used proof** → `422`

```json
{
  "error": {
    "code": "OTP_VERIFICATION_INVALID",
    "message": "Email verification is missing, expired or already used."
  },
  "requestId": "<request-id>"
}
```

**POST /auth/register** → `201`

```json
// request
{
  "email": "player@example.test",
  "verificationToken": "<verificationToken>",
  "password": "••••••••",
  "avatarId": 3,
  "language": "ar",
  "deviceName": "Pixel 8"
}
```

```json
{
  "tokens": {
    "accessToken": "<accessToken>",
    "refreshToken": "<refreshToken>",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "refreshExpiresIn": 2592000
  },
  "user": {
    "id": "022ae672-fd1e-4c32-86ae-64957029f25a",
    "email": "player@example.test",
    "name": "player",
    "language": "ar",
    "status": "ACTIVE",
    "createdAt": "2026-10-21T01:43:17.089Z",
    "avatar": {
      "id": 3,
      "imageUrl": null
    },
    "stats": {
      "points": 0,
      "giveaways": 0,
      "orders": 0
    }
  }
}
```

**POST /auth/refresh** → `200`

```json
// request
{
  "refreshToken": "<refreshToken>"
}
```

```json
{
  "tokens": {
    "accessToken": "<accessToken>",
    "refreshToken": "<refreshToken>",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "refreshExpiresIn": 2592000
  }
}
```

**POST /auth/refresh (same token again within 10 s from the same app, concurrent refresh)** → `409`

```json
{
  "error": {
    "code": "REFRESH_ALREADY_ROTATED",
    "message": "Tokens were just refreshed by another request. Reload the stored tokens."
  },
  "requestId": "<request-id>"
}
```

**GET /auth/sessions** → `200`

```json
{
  "items": [
    {
      "id": "095aa447-851e-456b-ac3b-f18d667c04f2",
      "deviceName": null,
      "userAgent": null,
      "createdAt": "2026-10-21T01:43:17.157Z",
      "lastUsedAt": "2026-10-21T01:43:17.168Z",
      "current": true
    },
    {
      "id": "2209e8e8-b2fc-497d-bfa3-55854e700408",
      "deviceName": "Pixel 8",
      "userAgent": null,
      "createdAt": "2026-10-21T01:43:17.089Z",
      "lastUsedAt": "2026-10-21T01:43:17.089Z",
      "current": false
    }
  ]
}
```

**GET /me without a token** → `401`

```json
{
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "Sign in to continue."
  },
  "requestId": "<request-id>"
}
```

**POST /auth/register with invalid data** → `422`

```json
// request
{
  "email": "bad",
  "password": "1"
}
```

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Check the submitted data.",
    "details": {
      "fields": {
        "email": "Invalid email address",
        "verificationToken": "<verificationToken>",
        "password": "Too small: expected string to have >=8 characters"
      }
    }
  },
  "requestId": "<request-id>"
}
```

### Profile and app

**PATCH /me** → `200`

```json
// request
{
  "name": "Ahmed",
  "avatarId": 5,
  "language": "ar"
}
```

```json
{
  "user": {
    "id": "022ae672-fd1e-4c32-86ae-64957029f25a",
    "email": "player@example.test",
    "name": "Ahmed",
    "language": "ar",
    "status": "ACTIVE",
    "createdAt": "2026-10-21T01:43:17.089Z",
    "avatar": {
      "id": 5,
      "imageUrl": null
    },
    "stats": {
      "points": 0,
      "giveaways": 0,
      "orders": 0
    }
  }
}
```

**GET /avatars** → `200`

```json
{
  "items": [
    {
      "id": 1,
      "imageUrl": null
    },
    {
      "id": 2,
      "imageUrl": null
    },
    {
      "id": 3,
      "imageUrl": null
    }
  ]
}
```

**GET /me/notification-preferences** → `200`

```json
{
  "preferences": {
    "orders": true,
    "giveaways": true,
    "announcements": false
  }
}
```

**GET /app-config** → `200`

```json
{
  "storeUrl": "",
  "termsUrl": "",
  "minVersion": "1.0.0",
  "privacyUrl": "",
  "maintenance": false,
  "latestVersion": "1.0.0",
  "maintenanceMessage": {
    "ar": "",
    "en": ""
  },
  "features": {
    "adRewards": false,
    "socialProducts": false
  },
  "adRewards": {
    "enabled": false,
    "pointsPerCompletedAd": 10
  },
  "serverTime": "2026-10-21T01:43:17.215Z"
}
```

**GET /home** → `200`

```json
{
  "categories": [
    {
      "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
      "kind": "GAME",
      "name": {
        "ar": "ببجي موبايل",
        "en": "PUBG Mobile"
      },
      "description": {
        "ar": "شحن شدات ببجي",
        "en": "PUBG UC top-ups"
      },
      "imageUrl": "https://example.com/media/pubg.png",
      "sortOrder": 0,
      "status": "PUBLISHED"
    }
  ],
  "featuredProducts": [
    {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "categoryId": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
      "groupId": "1722e06e-914a-4c94-9537-67de82cb6e4c",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "description": {
        "ar": "شحن مباشر",
        "en": "Direct top-up"
      },
      "deliveryNote": {
        "ar": "خلال ٢٤ ساعة",
        "en": "Within 24 hours"
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1,
      "inStock": true,
      "stock": null,
      "featured": true,
      "status": "PUBLISHED"
    }
  ],
  "giveaways": [
    {
      "id": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
      "title": {
        "ar": "سحب آيفون",
        "en": "iPhone giveaway"
      },
      "description": {
        "ar": "ادخل السحب مجانًا",
        "en": "Enter for free"
      },
      "prize": {
        "ar": "آيفون ١٦",
        "en": "iPhone 16"
      },
      "rules": {
        "ar": "مشاركة واحدة لكل حساب",
        "en": "One entry per account"
      },
      "organizer": "Creative Hub",
      "imageUrl": null,
      "categoryId": null,
      "startsAt": "2026-10-21T01:42:16.867Z",
      "endsAt": "2026-10-22T01:43:16.867Z",
      "status": "ACTIVE",
      "participants": 0,
      "maxParticipants": null,
      "winnersCount": 1,
      "numberDigits": 6
    }
  ]
}
```

**GET /search?q=UC** → `200`

```json
{
  "categories": [],
  "products": [
    {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "categoryId": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
      "groupId": "1722e06e-914a-4c94-9537-67de82cb6e4c",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "description": {
        "ar": "شحن مباشر",
        "en": "Direct top-up"
      },
      "deliveryNote": {
        "ar": "خلال ٢٤ ساعة",
        "en": "Within 24 hours"
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1,
      "inStock": true,
      "stock": null,
      "featured": true,
      "status": "PUBLISHED"
    }
  ],
  "giveaways": []
}
```

### Catalog

**GET /categories** → `200`

```json
{
  "items": [
    {
      "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
      "kind": "GAME",
      "name": {
        "ar": "ببجي موبايل",
        "en": "PUBG Mobile"
      },
      "description": {
        "ar": "شحن شدات ببجي",
        "en": "PUBG UC top-ups"
      },
      "imageUrl": "https://example.com/media/pubg.png",
      "sortOrder": 0,
      "status": "PUBLISHED"
    }
  ]
}
```

**GET /categories/:id** → `200`

```json
{
  "category": {
    "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
    "kind": "GAME",
    "name": {
      "ar": "ببجي موبايل",
      "en": "PUBG Mobile"
    },
    "description": {
      "ar": "شحن شدات ببجي",
      "en": "PUBG UC top-ups"
    },
    "imageUrl": "https://example.com/media/pubg.png",
    "sortOrder": 0,
    "status": "PUBLISHED",
    "groups": [
      {
        "id": "1722e06e-914a-4c94-9537-67de82cb6e4c",
        "name": {
          "ar": "شحن",
          "en": "Top-Ups"
        }
      }
    ]
  }
}
```

**GET /categories/:id/products** → `200`

```json
{
  "items": [
    {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "categoryId": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
      "groupId": "1722e06e-914a-4c94-9537-67de82cb6e4c",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "description": {
        "ar": "شحن مباشر",
        "en": "Direct top-up"
      },
      "deliveryNote": {
        "ar": "خلال ٢٤ ساعة",
        "en": "Within 24 hours"
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1,
      "inStock": true,
      "stock": null,
      "featured": true,
      "status": "PUBLISHED"
    }
  ]
}
```

**GET /products/:id** → `200`

```json
{
  "product": {
    "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
    "categoryId": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
    "groupId": "1722e06e-914a-4c94-9537-67de82cb6e4c",
    "name": {
      "ar": "٦٠ شدة",
      "en": "60 UC"
    },
    "description": {
      "ar": "شحن مباشر",
      "en": "Direct top-up"
    },
    "deliveryNote": {
      "ar": "خلال ٢٤ ساعة",
      "en": "Within 24 hours"
    },
    "imageUrl": "https://example.com/media/uc60.png",
    "pointsPrice": 500,
    "priceVersion": 1,
    "inStock": true,
    "stock": null,
    "featured": true,
    "status": "PUBLISHED",
    "fields": [
      {
        "key": "playerId",
        "label": {
          "ar": "معرّف اللاعب",
          "en": "Player ID"
        },
        "type": "NUMBER",
        "required": true,
        "pattern": null,
        "options": []
      },
      {
        "key": "server",
        "label": {
          "ar": "السيرفر",
          "en": "Server"
        },
        "type": "SELECT",
        "required": false,
        "pattern": null,
        "options": [
          "Middle East",
          "Europe"
        ]
      }
    ]
  }
}
```

**GET /products/:id (unknown)** → `404`

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Product not found."
  },
  "requestId": "<request-id>"
}
```

### Wallet

**GET /wallet** → `200`

```json
{
  "wallet": {
    "balance": 1200,
    "lifetimeEarned": 1200,
    "lifetimeSpent": 0,
    "updatedAt": "2026-10-21T01:43:17.268Z"
  }
}
```

**GET /wallet/transactions** → `200`

```json
{
  "items": [
    {
      "id": "370",
      "type": "REDEMPTION_REFUND",
      "amount": 500,
      "balanceAfter": 700,
      "reference": {
        "type": "ORDER",
        "id": "2d95f53e-7c3b-48b8-a999-ff6527028cc5"
      },
      "note": "Cancelled by user",
      "createdAt": "2026-10-21T01:43:17.405Z"
    },
    {
      "id": "369",
      "type": "REDEMPTION_DEBIT",
      "amount": -500,
      "balanceAfter": 200,
      "reference": {
        "type": "ORDER",
        "id": "2d95f53e-7c3b-48b8-a999-ff6527028cc5"
      },
      "note": null,
      "createdAt": "2026-10-21T01:43:17.365Z"
    },
    {
      "id": "368",
      "type": "REDEMPTION_DEBIT",
      "amount": -500,
      "balanceAfter": 700,
      "reference": {
        "type": "ORDER",
        "id": "e9ec9f2e-2911-472a-b27b-cd4958c30e2d"
      },
      "note": null,
      "createdAt": "2026-10-21T01:43:17.319Z"
    },
    {
      "id": "367",
      "type": "ADMIN_CREDIT",
      "amount": 1200,
      "balanceAfter": 1200,
      "reference": {
        "type": "ADJUSTMENT",
        "id": "2dc5e78b-b7d4-4244-a23f-cc88f45beae6"
      },
      "note": "Welcome credit",
      "createdAt": "2026-10-21T01:43:17.268Z"
    }
  ],
  "nextCursor": null
}
```

### Orders

**POST /orders (Idempotency-Key: <uuid>)** → `201`

```json
// request
{
  "productId": "<product-id>",
  "fields": {
    "playerId": "5123456789",
    "server": "Middle East"
  },
  "expectedPointsPrice": 500
}
```

```json
{
  "order": {
    "id": "e9ec9f2e-2911-472a-b27b-cd4958c30e2d",
    "orderNumber": "CR-2026-000309",
    "status": "PENDING",
    "pointsCost": 500,
    "product": {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "fields": [
        {
          "key": "playerId",
          "label": {
            "ar": "معرّف اللاعب",
            "en": "Player ID"
          }
        },
        {
          "key": "server",
          "label": {
            "ar": "السيرفر",
            "en": "Server"
          }
        }
      ],
      "category": {
        "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
        "kind": "GAME",
        "name": {
          "ar": "ببجي موبايل",
          "en": "PUBG Mobile"
        }
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1
    },
    "statusReason": null,
    "trackingInfo": null,
    "createdAt": "2026-10-21T01:43:17.319Z",
    "updatedAt": "2026-10-21T01:43:17.319Z"
  },
  "balance": 700
}
```

**POST /orders — invalid fulfilment fields** → `422`

```json
// request
{
  "productId": "<product-id>",
  "fields": {
    "playerId": "abc",
    "password": "x"
  }
}
```

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Check the required fields.",
    "details": {
      "fields": {
        "playerId": "INVALID_FORMAT",
        "password": "UNKNOWN_FIELD"
      }
    }
  },
  "requestId": "<request-id>"
}
```

**POST /orders — price changed since the user saw it** → `409`

```json
{
  "error": {
    "code": "PRICE_CHANGED",
    "message": "The price has changed.",
    "details": {
      "pointsPrice": 500
    }
  },
  "requestId": "<request-id>"
}
```

**POST /orders — not enough points** → `409`

```json
{
  "error": {
    "code": "INSUFFICIENT_POINTS",
    "message": "Not enough points.",
    "details": {
      "balance": 200,
      "required": 500
    }
  },
  "requestId": "<request-id>"
}
```

**POST /orders/:id/cancel** → `200`

```json
{
  "order": {
    "id": "2d95f53e-7c3b-48b8-a999-ff6527028cc5",
    "orderNumber": "CR-2026-000310",
    "status": "CANCELLED",
    "pointsCost": 500,
    "product": {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "fields": [
        {
          "key": "playerId",
          "label": {
            "ar": "معرّف اللاعب",
            "en": "Player ID"
          }
        },
        {
          "key": "server",
          "label": {
            "ar": "السيرفر",
            "en": "Server"
          }
        }
      ],
      "category": {
        "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
        "kind": "GAME",
        "name": {
          "ar": "ببجي موبايل",
          "en": "PUBG Mobile"
        }
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1
    },
    "statusReason": "Cancelled by user",
    "trackingInfo": null,
    "createdAt": "2026-10-21T01:43:17.365Z",
    "updatedAt": "2026-10-21T01:43:17.405Z"
  },
  "balance": 700
}
```

**GET /orders** → `200`

```json
{
  "items": [
    {
      "id": "2d95f53e-7c3b-48b8-a999-ff6527028cc5",
      "orderNumber": "CR-2026-000310",
      "status": "CANCELLED",
      "pointsCost": 500,
      "product": {
        "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
        "name": {
          "ar": "٦٠ شدة",
          "en": "60 UC"
        },
        "fields": [
          {
            "key": "playerId",
            "label": {
              "ar": "معرّف اللاعب",
              "en": "Player ID"
            }
          },
          {
            "key": "server",
            "label": {
              "ar": "السيرفر",
              "en": "Server"
            }
          }
        ],
        "category": {
          "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
          "kind": "GAME",
          "name": {
            "ar": "ببجي موبايل",
            "en": "PUBG Mobile"
          }
        },
        "imageUrl": "https://example.com/media/uc60.png",
        "pointsPrice": 500,
        "priceVersion": 1
      },
      "statusReason": "Cancelled by user",
      "trackingInfo": null,
      "createdAt": "2026-10-21T01:43:17.365Z",
      "updatedAt": "2026-10-21T01:43:17.405Z"
    }
  ],
  "nextCursor": null
}
```

**GET /orders/:id (completed, with delivered code)** → `200`

```json
{
  "order": {
    "id": "e9ec9f2e-2911-472a-b27b-cd4958c30e2d",
    "orderNumber": "CR-2026-000309",
    "status": "COMPLETED",
    "pointsCost": 500,
    "product": {
      "id": "5e9afc7f-3458-4c27-9a31-ee57a8e24d2f",
      "name": {
        "ar": "٦٠ شدة",
        "en": "60 UC"
      },
      "fields": [
        {
          "key": "playerId",
          "label": {
            "ar": "معرّف اللاعب",
            "en": "Player ID"
          }
        },
        {
          "key": "server",
          "label": {
            "ar": "السيرفر",
            "en": "Server"
          }
        }
      ],
      "category": {
        "id": "5bdb42b9-8e1a-4fa5-8b09-ad4f2c3fd06e",
        "kind": "GAME",
        "name": {
          "ar": "ببجي موبايل",
          "en": "PUBG Mobile"
        }
      },
      "imageUrl": "https://example.com/media/uc60.png",
      "pointsPrice": 500,
      "priceVersion": 1
    },
    "statusReason": null,
    "trackingInfo": null,
    "createdAt": "2026-10-21T01:43:17.319Z",
    "updatedAt": "2026-10-21T01:43:17.472Z",
    "fields": {
      "playerId": "5123456789",
      "server": "Middle East"
    },
    "deliveredCode": "UC-CODE-1234",
    "timeline": [
      {
        "status": "PENDING",
        "reason": null,
        "at": "2026-10-21T01:43:17.319Z"
      },
      {
        "status": "PROCESSING",
        "reason": null,
        "at": "2026-10-21T01:43:17.447Z"
      },
      {
        "status": "COMPLETED",
        "reason": null,
        "at": "2026-10-21T01:43:17.472Z"
      }
    ]
  }
}
```

### Rewarded ads (AdMob SSV)

**GET /ad-rewards/status (feature off)** → `200`

```json
{
  "enabled": false,
  "verification": "ADMOB_SSV",
  "pointsPerCompletedAd": 10,
  "dailyLimit": 10,
  "usedToday": 0,
  "remainingToday": 10,
  "cooldownSeconds": 120,
  "nextAvailableAt": null,
  "serverTime": "2026-10-21T01:43:17.510Z"
}
```

**POST /ad-rewards/sessions (feature off)** → `403`

```json
{
  "error": {
    "code": "FEATURE_DISABLED",
    "message": "Ad rewards are not available."
  },
  "requestId": "<request-id>"
}
```

**POST /ad-rewards/sessions** → `201`

```json
// request
{
  "deviceId": "install-0f3c2a9b",
  "adUnitId": "ca-app-pub-0000000000000000/0000000000"
}
```

```json
{
  "session": {
    "id": "116d6e4b-9405-48ed-86e3-818a15ab16c5",
    "status": "PENDING",
    "points": 10,
    "rejectReason": null,
    "createdAt": "2026-10-21T01:43:17.539Z",
    "expiresAt": "2026-10-21T02:43:17.539Z",
    "verifiedAt": null
  },
  "ssv": {
    "userId": "022ae672-fd1e-4c32-86ae-64957029f25a",
    "customData": "116d6e4b-9405-48ed-86e3-818a15ab16c5"
  }
}
```

**GET /ad-rewards/sessions/:id (before Google's callback)** → `200`

```json
{
  "session": {
    "id": "116d6e4b-9405-48ed-86e3-818a15ab16c5",
    "status": "PENDING",
    "points": 10,
    "rejectReason": null,
    "createdAt": "2026-10-21T01:43:17.539Z",
    "expiresAt": "2026-10-21T02:43:17.539Z",
    "verifiedAt": null
  }
}
```

**POST /ad-rewards/claims (before Google's callback)** → `200`

```json
// request
{
  "sessionId": "<session id>"
}
```

```json
{
  "session": {
    "id": "116d6e4b-9405-48ed-86e3-818a15ab16c5",
    "status": "PENDING",
    "points": 10,
    "rejectReason": null,
    "createdAt": "2026-10-21T01:43:17.539Z",
    "expiresAt": "2026-10-21T02:43:17.539Z",
    "verifiedAt": null
  },
  "balance": 700
}
```

**GET /webhooks/admob/ssv?…&signature=…&key_id=… (sent by Google, not the app)** → `200`

```json
{
  "result": "CREDITED"
}
```

**Same callback replayed** → `200`

```json
{
  "result": "DUPLICATE_TRANSACTION"
}
```

**Callback with an invalid signature** → `403`

```json
{
  "error": {
    "code": "INVALID_SIGNATURE",
    "message": "Invalid signature."
  },
  "requestId": "<request-id>"
}
```

**GET /ad-rewards/sessions/:id (after the callback)** → `200`

```json
{
  "session": {
    "id": "116d6e4b-9405-48ed-86e3-818a15ab16c5",
    "status": "CREDITED",
    "points": 10,
    "rejectReason": null,
    "createdAt": "2026-10-21T01:43:17.539Z",
    "expiresAt": "2026-10-21T02:43:17.539Z",
    "verifiedAt": "2026-10-21T01:43:17.567Z"
  }
}
```

**POST /ad-rewards/claims (after the callback)** → `200`

```json
{
  "session": {
    "id": "116d6e4b-9405-48ed-86e3-818a15ab16c5",
    "status": "CREDITED",
    "points": 10,
    "rejectReason": null,
    "createdAt": "2026-10-21T01:43:17.539Z",
    "expiresAt": "2026-10-21T02:43:17.539Z",
    "verifiedAt": "2026-10-21T01:43:17.567Z"
  },
  "balance": 710
}
```

**POST /ad-rewards/sessions — during cooldown** → `429`

```json
{
  "error": {
    "code": "COOLDOWN",
    "message": "Wait before watching another ad.",
    "details": {
      "retryAfter": 120
    }
  },
  "requestId": "<request-id>"
}
```

**GET /ad-rewards/status** → `200`

```json
{
  "enabled": true,
  "verification": "ADMOB_SSV",
  "pointsPerCompletedAd": 10,
  "dailyLimit": 10,
  "usedToday": 1,
  "remainingToday": 9,
  "cooldownSeconds": 120,
  "nextAvailableAt": "2026-10-21T01:45:17.567Z",
  "serverTime": "2026-10-21T01:43:17.622Z"
}
```

### Giveaways

**GET /giveaways?status=AVAILABLE** → `200`

```json
{
  "items": [
    {
      "id": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
      "title": {
        "ar": "سحب آيفون",
        "en": "iPhone giveaway"
      },
      "description": {
        "ar": "ادخل السحب مجانًا",
        "en": "Enter for free"
      },
      "prize": {
        "ar": "آيفون ١٦",
        "en": "iPhone 16"
      },
      "rules": {
        "ar": "مشاركة واحدة لكل حساب",
        "en": "One entry per account"
      },
      "organizer": "Creative Hub",
      "imageUrl": null,
      "categoryId": null,
      "startsAt": "2026-10-21T01:42:16.867Z",
      "endsAt": "2026-10-22T01:43:16.867Z",
      "status": "ACTIVE",
      "participants": 0,
      "maxParticipants": null,
      "winnersCount": 1,
      "numberDigits": 6
    }
  ],
  "nextCursor": null
}
```

**POST /giveaways/:id/entries before required steps** → `409`

```json
{
  "error": {
    "code": "STEPS_INCOMPLETE",
    "message": "Complete the required steps first.",
    "details": {
      "remaining": 1
    }
  },
  "requestId": "<request-id>"
}
```

**POST /giveaways/:id/steps/:stepId/progress** → `200`

```json
// request
{
  "proofText": "@ahmed"
}
```

```json
{
  "progress": {
    "stepId": "c32e3215-28b7-4c96-895b-b7803e0968dc",
    "status": "SUBMITTED",
    "note": null
  }
}
```

**POST /giveaways/:id/entries** → `201`

```json
{
  "entry": {
    "id": "492706fa-7d1f-4458-bce4-547e82798cf2",
    "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
    "participationNumber": "424869",
    "status": "ACTIVE",
    "createdAt": "2026-10-21T01:43:17.660Z"
  }
}
```

**POST /giveaways/:id/entries (again)** → `200`

```json
{
  "entry": {
    "id": "492706fa-7d1f-4458-bce4-547e82798cf2",
    "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
    "participationNumber": "424869",
    "status": "ACTIVE",
    "createdAt": "2026-10-21T01:43:17.660Z"
  }
}
```

**GET /giveaways/:id (with token)** → `200`

```json
{
  "giveaway": {
    "id": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
    "title": {
      "ar": "سحب آيفون",
      "en": "iPhone giveaway"
    },
    "description": {
      "ar": "ادخل السحب مجانًا",
      "en": "Enter for free"
    },
    "prize": {
      "ar": "آيفون ١٦",
      "en": "iPhone 16"
    },
    "rules": {
      "ar": "مشاركة واحدة لكل حساب",
      "en": "One entry per account"
    },
    "organizer": "Creative Hub",
    "imageUrl": null,
    "categoryId": null,
    "startsAt": "2026-10-21T01:42:16.867Z",
    "endsAt": "2026-10-22T01:43:16.867Z",
    "status": "ACTIVE",
    "participants": 1,
    "maxParticipants": null,
    "winnersCount": 1,
    "numberDigits": 6,
    "steps": [
      {
        "id": "c32e3215-28b7-4c96-895b-b7803e0968dc",
        "kind": "FOLLOW",
        "title": {
          "ar": "تابع حسابنا على إنستجرام",
          "en": "Follow us on Instagram"
        },
        "url": "https://instagram.com/example",
        "verification": "ADMIN_REVIEW",
        "required": true,
        "sortOrder": 0
      }
    ]
  },
  "me": {
    "entry": {
      "id": "492706fa-7d1f-4458-bce4-547e82798cf2",
      "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
      "participationNumber": "424869",
      "status": "ACTIVE",
      "createdAt": "2026-10-21T01:43:17.660Z"
    },
    "steps": {
      "c32e3215-28b7-4c96-895b-b7803e0968dc": {
        "status": "SUBMITTED",
        "note": null
      }
    }
  }
}
```

**GET /giveaways/:id/results** → `200`

```json
{
  "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
  "winners": [
    {
      "rank": 1,
      "participationNumber": "424869",
      "announcedAt": "2026-10-21T01:43:17.714Z"
    }
  ]
}
```

**GET /me/entries** → `200`

```json
{
  "items": [
    {
      "id": "492706fa-7d1f-4458-bce4-547e82798cf2",
      "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
      "participationNumber": "424869",
      "status": "ACTIVE",
      "createdAt": "2026-10-21T01:43:17.660Z",
      "result": "WON",
      "winnerId": "4d6181db-5b35-4b59-9896-8d64307d5958",
      "giveaway": {
        "id": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
        "title": {
          "ar": "سحب آيفون",
          "en": "iPhone giveaway"
        },
        "imageUrl": null,
        "endsAt": "2026-10-21T01:43:16.686Z"
      }
    }
  ],
  "nextCursor": null
}
```

**GET /me/winnings/pending-celebration** → `200`

```json
{
  "items": [
    {
      "id": "4d6181db-5b35-4b59-9896-8d64307d5958",
      "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
      "rank": 1,
      "status": "ANNOUNCED",
      "claimDeadline": "2026-11-04T01:43:17.714Z",
      "claimedAt": null,
      "giveaway": {
        "title": {
          "ar": "سحب آيفون",
          "en": "iPhone giveaway"
        },
        "prize": {
          "ar": "آيفون ١٦",
          "en": "iPhone 16"
        },
        "imageUrl": null
      },
      "participationNumber": "424869"
    }
  ]
}
```

**POST /me/winnings/:id/claim** → `200`

```json
// request
{
  "contact": "+20 100 000 0000, Cairo"
}
```

```json
{
  "winning": {
    "id": "4d6181db-5b35-4b59-9896-8d64307d5958",
    "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef",
    "rank": 1,
    "status": "CLAIMED",
    "claimDeadline": "2026-11-04T01:43:17.714Z",
    "claimedAt": "2026-10-21T01:43:17.753Z",
    "giveaway": {
      "title": {
        "ar": "سحب آيفون",
        "en": "iPhone giveaway"
      },
      "prize": {
        "ar": "آيفون ١٦",
        "en": "iPhone 16"
      },
      "imageUrl": null
    },
    "participationNumber": "424869"
  }
}
```

### Notifications

**GET /notifications?limit=5** → `200`

```json
{
  "items": [
    {
      "id": "c46955b7-043f-477a-b648-561000e2a974",
      "type": "WINNER_SELECTED",
      "title": {
        "ar": "مبروك! لقد فزت 🎉",
        "en": "Congratulations, you won! 🎉"
      },
      "body": {
        "ar": "سحب آيفون",
        "en": "iPhone giveaway"
      },
      "data": {
        "winnerId": "4d6181db-5b35-4b59-9896-8d64307d5958",
        "giveawayId": "a518620b-467c-4f1f-aaaf-dc1b6c91b0ef"
      },
      "read": false,
      "readAt": null,
      "createdAt": "2026-10-21T01:43:17.714Z"
    },
    {
      "id": "d90c8e56-7a76-4a65-ae42-4f8f3fd94836",
      "type": "ORDER_STATUS",
      "title": {
        "ar": "تم إكمال طلبك",
        "en": "Your order is complete"
      },
      "body": {
        "ar": "طلب رقم CR-2026-000309",
        "en": "Order CR-2026-000309"
      },
      "data": {
        "status": "COMPLETED",
        "orderId": "e9ec9f2e-2911-472a-b27b-cd4958c30e2d"
      },
      "read": false,
      "readAt": null,
      "createdAt": "2026-10-21T01:43:17.472Z"
    },
    {
      "id": "4d11ab23-093d-4c00-b5c2-159d629fa32a",
      "type": "ORDER_STATUS",
      "title": {
        "ar": "طلبك قيد التنفيذ",
        "en": "Your order is being processed"
      },
      "body": {
        "ar": "طلب رقم CR-2026-000309",
        "en": "Order CR-2026-000309"
      },
      "data": {
        "status": "PROCESSING",
        "orderId": "e9ec9f2e-2911-472a-b27b-cd4958c30e2d"
      },
      "read": false,
      "readAt": null,
      "createdAt": "2026-10-21T01:43:17.447Z"
    }
  ],
  "nextCursor": null
}
```

**GET /notifications/unread-count** → `200`

```json
{
  "count": 3
}
```

**PUT /devices/:installationId** → `204`

```json
// request
{
  "fcmToken": "fcm-token-example-123",
  "platform": "android",
  "appVersion": "2.0.0",
  "language": "ar"
}
```

### Account deletion

**DELETE /me** → `202`

```json
// request
{
  "password": "••••••••"
}
```

```json
{
  "status": "DELETION_REQUESTED",
  "graceDays": 14
}
```

## 6. Mapping from the demo `RewardsRepository`

| Demo operation | API |
|---|---|
| Sign up (Email → OTP → Password → Character) | `POST /auth/otp/send`, `POST /auth/otp/verify`, `POST /auth/register` |
| Reset password | `POST /auth/otp/send` (`FORGOT_PASSWORD`), `POST /auth/otp/verify`, `POST /auth/password/reset` |
| Log in / restore session / log out | `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` |
| Profile, name, character, language | `GET /me`, `PATCH /me`, `GET /avatars` |
| Points balance and history | `GET /wallet`, `GET /wallet/transactions` |
| Categories, groups (Top-Ups, Items & Skins), products | `GET /categories`, `GET /categories/:id`, `GET /categories/:id/products?groupId=`, `GET /products/:id` |
| Redeem | `POST /orders` |
| My Orders and order details | `GET /orders?statusGroup=`, `GET /orders/:id`, `POST /orders/:id/cancel` |
| Giveaways, enter, My Giveaways | `GET /giveaways`, `GET /giveaways/:id`, `POST /giveaways/:id/steps/:stepId/progress`, `POST /giveaways/:id/entries`, `GET /me/entries` |
| Winner celebration and prize claim | `GET /me/winnings/pending-celebration`, `POST .../acknowledge-celebration`, `POST .../claim` |
| Notifications and badges | `GET /notifications`, `GET /notifications/unread-count`, `POST /notifications/:id/read`, `POST /notifications/read-all` |
| Earn (rewarded ads) | `GET /ad-rewards/status`, `POST /ad-rewards/sessions`, AdMob SSV options, `GET /ad-rewards/sessions/:id` |
| Write a Review / Refer a Friend | Not backed by the API (store link only; referral is not implemented) |

## 7. Known limitations (decided by the product owner, not by the app)

> **Breaking changes in this version:** `POST /ad-rewards/claims` no longer accepts `{ rewardEventId, deviceId }` and never credits points; it takes `{ sessionId }`. Use `POST /ad-rewards/sessions` + SSV options instead. `COOLDOWN` now carries `details.retryAfter` instead of `details.balance`. Social-media categories and products are now hidden while `features.socialProducts` is false. No other route or field changed.


- **Rewarded ads — policy gate.** Ad rewards are verified by AdMob SSV, but the feature stays **off** until the product owner has explicit clearance that AdMob's rewarded-ads policy allows points to be redeemed for off-app goods and services (game top-ups, physical items, social services). SSV proves an ad was watched; it does not make the reward model compliant. The callback URL must be set on the rewarded ad unit in AdMob and must be public HTTPS.
- **Social-media products** are hidden from the catalog, Home and search, and return `403 FEATURE_DISABLED` on order, until the admin enables `socialProducts` after a policy review of the specific services. Their fields must be public usernames or profile URLs; the server refuses fields asking for passwords or codes.
- **Steps** with `NONE` or `LINK_CLICK` are self-reported by the app; only `ADMIN_REVIEW` steps are checked by a person.
- **Announcements** reach only users who opted in (`announcements: true`, default `false`). Order and giveaway notifications are on by default.
- **Push delivery** needs Firebase credentials on the server. Without them the inbox still works and pushes are skipped.
