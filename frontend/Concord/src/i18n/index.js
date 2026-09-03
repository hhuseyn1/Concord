import i18next from 'i18next'
import { initReactI18next } from 'react-i18next'
import az from './locales/az/common.json'
import en from './locales/en/common.json'
import { SUPPORTED_LANGUAGES } from './localeMapping'

export const LOCALE_STORAGE_KEY = 'concord.locale'

function resolveInitialLanguage() {
  try {
    const stored = localStorage.getItem(LOCALE_STORAGE_KEY)
    if (stored && SUPPORTED_LANGUAGES.includes(stored)) return stored
  } catch {
  }

  const browserLanguage = (navigator.language || '').slice(0, 2).toLowerCase()
  if (SUPPORTED_LANGUAGES.includes(browserLanguage)) return browserLanguage

  return 'az'
}

i18next.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    az: { translation: az },
  },
  lng: resolveInitialLanguage(),
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
})

export function setLanguage(shortLocale) {
  if (!SUPPORTED_LANGUAGES.includes(shortLocale)) return
  i18next.changeLanguage(shortLocale)
  try {
    localStorage.setItem(LOCALE_STORAGE_KEY, shortLocale)
  } catch {
  }
}

export function hasExplicitLanguageChoice() {
  try {
    return Boolean(localStorage.getItem(LOCALE_STORAGE_KEY))
  } catch {
    return false
  }
}

export default i18next
