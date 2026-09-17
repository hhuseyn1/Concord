/**
 * Route paths for the Stars flows, declared once so the Stripe redirect screens,
 * the router and every "back to Stars" link agree.
 *
 * The two purchase paths are what the backend's `StarsSuccessUrl` /
 * `StarsCancelUrl` Stripe settings must point at. The success screen needs the
 * purchase id in the query string; it accepts `purchase_id` (preferred),
 * `purchaseId` or `session_id`.
 */
export const STARS_SETTINGS_PATH = '/cabinet/settings?tab=stars'
export const STARS_PURCHASE_SUCCESS_PATH = '/cabinet/stars/purchase/success'
export const STARS_PURCHASE_CANCEL_PATH = '/cabinet/stars/purchase/cancel'
