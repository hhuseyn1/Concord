export const SHORT_TO_SERVER_LOCALE = {
  en: 'en-EN',
  az: 'az-AZ',
}

export const SERVER_TO_SHORT_LOCALE = {
  'en-EN': 'en',
  'az-AZ': 'az',
}

export const SUPPORTED_LANGUAGES = ['en', 'az']

/**
 * Display names for every supported language, always written in that language
 * itself (never translated) - `short` for space-constrained triggers like the
 * landing navbar, `long` for menu items and the Settings row.
 */
export const LANGUAGE_LABELS = {
  en: { short: 'EN', long: 'English' },
  az: { short: 'AZ', long: 'Azərbaycan' },
}

export function toShortLocale(serverLocale) {
  return SERVER_TO_SHORT_LOCALE[serverLocale] ?? undefined
}

export function toServerLocale(shortLocale) {
  return SHORT_TO_SERVER_LOCALE[shortLocale] ?? SHORT_TO_SERVER_LOCALE.az
}
