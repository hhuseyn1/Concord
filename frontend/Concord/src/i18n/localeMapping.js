export const SHORT_TO_SERVER_LOCALE = {
  en: 'en-EN',
  az: 'az-AZ',
}

export const SERVER_TO_SHORT_LOCALE = {
  'en-EN': 'en',
  'az-AZ': 'az',
}

export const SUPPORTED_LANGUAGES = ['en', 'az']

export function toShortLocale(serverLocale) {
  return SERVER_TO_SHORT_LOCALE[serverLocale] ?? undefined
}

export function toServerLocale(shortLocale) {
  return SHORT_TO_SERVER_LOCALE[shortLocale] ?? SHORT_TO_SERVER_LOCALE.az
}
