# Font Integration for Indian Languages

This directory contains Noto Sans fonts for proper rendering of Indian languages in the AgroScan app.

## Supported Languages and Scripts

- **English (en)**: NotoSans (Latin script)
- **Hindi (hi)**: NotoSansDevanagari (Devanagari script)
- **Tamil (ta)**: NotoSansTamil (Tamil script)
- **Telugu (te)**: NotoSansTelugu (Telugu script)
- **Kannada (kn)**: NotoSansKannada (Kannada script)
- **Malayalam (ml)**: NotoSansMalayalam (Malayalam script)

## Font Files

Each language has three font weights:
- Regular (400)
- Medium (500)
- Bold (700)

### Current Status

The current files are **placeholder files**. To complete the font integration, replace these placeholder files with actual Noto Sans font files:

### Download Instructions

1. Visit [Google Fonts - Noto Sans](https://fonts.google.com/noto/fonts)
2. Download the following font families:
   - Noto Sans
   - Noto Sans Devanagari
   - Noto Sans Tamil
   - Noto Sans Telugu
   - Noto Sans Kannada
   - Noto Sans Malayalam

3. Extract and replace the placeholder files with the actual .ttf files:
   - Use the Regular, Medium, and Bold weights for each font family
   - Ensure file names match exactly: `NotoSans[Language]-[Weight].ttf`

### Alternative: Direct Downloads

You can download specific fonts from:
- [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)
- [Noto Sans Devanagari](https://fonts.google.com/specimen/Noto+Sans+Devanagari)
- [Noto Sans Tamil](https://fonts.google.com/specimen/Noto+Sans+Tamil)
- [Noto Sans Telugu](https://fonts.google.com/specimen/Noto+Sans+Telugu)
- [Noto Sans Kannada](https://fonts.google.com/specimen/Noto+Sans+Kannada)
- [Noto Sans Malayalam](https://fonts.google.com/specimen/Noto+Sans+Malayalam)

## Font Service

The app uses a dynamic `FontService` that automatically selects the appropriate font family based on the current language setting. This ensures:

- ✅ No broken characters
- ✅ No layout shifts  
- ✅ Proper script rendering for all supported languages
- ✅ Graceful fallbacks between font families
- ✅ Performance optimization through font family stacks

## Implementation Details

- Fonts are applied globally through the app theme
- No hardcoded font overrides in individual widgets
- Dynamic font selection based on language state
- Comprehensive fallback chain for mixed-language content
- Material Design 3 compliant text styles

## Testing

After replacing placeholder fonts with actual files:

1. Run `flutter pub get` to refresh dependencies
2. Test the app in different language settings
3. Verify proper rendering of:
   - Hindi text (Devanagari script)
   - Tamil text (Tamil script)
   - Telugu text (Telugu script)
   - Kannada text (Kannada script)
   - Malayalam text (Malayalam script)

## Performance Notes

- Font files are bundled with the app
- Initial app size will increase (~5-10MB total for all fonts)
- Consider using `fontFallback` for optimal loading
- Fonts are loaded on-demand by Flutter's font system