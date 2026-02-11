/// Service for converting technical terms to farmer-friendly vocabulary
/// Only applies transformations when Simple Mode is enabled
/// Does not modify stored data - only affects display layer
class VocabularyService {
  const VocabularyService();

  /// Comprehensive glossary mapping: technical → simple farmer-friendly terms
  /// Organized by language for future multilingual expansion
  static const Map<String, Map<String, String>> _glossary = {
    'en': {
      // Disease-related terms
      'pathogen': 'disease germ',
      'fungicide': 'fungus medicine',
      'pesticide': 'pest killer',
      'insecticide': 'insect killer',
      'herbicide': 'weed killer',
      'bactericide': 'bacteria killer',
      
      // Symptom terms
      'chlorosis': 'leaf yellowing',
      'necrosis': 'dead tissue',
      'lesion': 'infected spot',
      'blight': 'plant disease',
      'wilt': 'drooping plant',
      'rust': 'orange spots',
      'scab': 'rough patches',
      'mildew': 'powdery coating',
      'canker': 'open wound',
      
      // Treatment terms
      'prophylactic': 'preventive',
      'curative': 'healing',
      'systemic': 'whole plant treatment',
      'contact': 'surface treatment',
      'foliar': 'leaf spray',
      'soil drench': 'ground watering',
      'application': 'use',
      'dosage': 'amount to use',
      'frequency': 'how often',
      
      // Agricultural terms
      'cultivar': 'plant variety',
      'crop rotation': 'changing crops yearly',
      'companion planting': 'helpful plant neighbors',
      'integrated pest management': 'smart pest control',
      'biological control': 'natural pest control',
      'organic': 'natural',
      'synthetic': 'man-made',
      
      // Scientific terms
      'phytoplasma': 'plant bacteria',
      'virus': 'very small germ',
      'bacteria': 'tiny germ',
      'fungus': 'mold-like germ',
      'nematode': 'tiny worm',
      'vector': 'disease carrier',
      'spore': 'fungus seed',
      
      // Plant parts (technical)
      'foliage': 'leaves',
      'canopy': 'leaf cover',
      'tuber': 'underground stem',
      'rhizome': 'underground stem',
      'petiole': 'leaf stem',
      'stolon': 'runner',
      
      // Severity terms
      'severity': 'how bad it is',
      'infection': 'disease spread',
      'infestation': 'pest attack',
      'contamination': 'pollution',
      
      // Environmental terms
      'humidity': 'moisture in air',
      'temperature': 'heat level',
      'precipitation': 'rainfall',
      'irrigation': 'watering',
      'drainage': 'water flow',
    },
    
    // Add more languages as needed
    'hi': {
      'pathogen': 'रोग कीटाणु',
      'fungicide': 'फफूंद दवा',
      'pesticide': 'कीटनाशक',
      'lesion': 'संक्रमित धब्बा',
      'severity': 'गंभीरता',
    },
    
    'kn': {
      'pathogen': 'ರೋಗ ಕೀಟಾಣು',
      'fungicide': 'ಶಿಲೀಂಧ್ರ ಔಷಧ',
      'pesticide': 'ಕೀಟನಾಶಕ',
      'lesion': 'ಸೋಂಕಿತ ಕಲೆ',
      'severity': 'ತೀವ್ರತೆ',
    },
    
    'ta': {
      'pathogen': 'நோய் கிருமி',
      'fungicide': 'பூஞ்சை மருந்து',
      'pesticide': 'பூச்சிக்கொல்லி',
      'lesion': 'தொற்று புள்ளி',
      'severity': 'தீவிரம்',
    },
    
    'te': {
      'pathogen': 'వ్యాధి క్రిములు',
      'fungicide': 'శిలీంధ్ర ఔషధం',
      'pesticide': 'పురుగుమందు',
      'lesion': 'సోకిన మచ్చ',
      'severity': 'తీవ్రత',
    },
    
    'ml': {
      'pathogen': 'രോഗാണു',
      'fungicide': 'കുമിൾ മരുന്ന്',
      'pesticide': 'കീടനാശിനി',
      'lesion': 'രോഗബാധിത പാട്',
      'severity': 'തീവ്രത',
    },
  };

  /// Simplify technical text to farmer-friendly vocabulary
  /// Only applies transformation if simpleMode is enabled
  /// 
  /// [text] - The text to potentially simplify
  /// [language] - Target language code (default: 'en')
  /// [simpleMode] - Whether to apply simplification (default: false)
  /// 
  /// Returns: Original text if simpleMode is false, simplified text otherwise
  String simplify(String text, {String language = 'en', bool simpleMode = false}) {
    // If simple mode is not enabled, return original text
    if (!simpleMode) {
      return text;
    }

    // Get glossary for the specified language, fallback to English
    final glossary = _glossary[language] ?? _glossary['en'] ?? {};
    
    String result = text;
    
    // Replace each technical term with its simple equivalent
    // Use case-insensitive matching but preserve original case
    glossary.forEach((technical, simple) {
      // Create a regex for case-insensitive matching
      final pattern = RegExp(technical, caseSensitive: false);
      
      // Replace while trying to preserve the case of the first letter
      result = result.replaceAllMapped(pattern, (match) {
        final matched = match.group(0)!;
        // If the matched text starts with uppercase, capitalize the replacement
        if (matched[0] == matched[0].toUpperCase()) {
          return simple[0].toUpperCase() + simple.substring(1);
        }
        return simple;
      });
    });
    
    return result;
  }

  /// Get the simple version of a single term
  /// 
  /// [term] - Technical term to look up
  /// [language] - Target language code (default: 'en')
  /// 
  /// Returns: Simple term if found, original term otherwise
  String getTerm(String term, {String language = 'en'}) {
    final glossary = _glossary[language] ?? _glossary['en'] ?? {};
    return glossary[term.toLowerCase()] ?? term;
  }

  /// Check if a term has a simplified version
  /// 
  /// [term] - Term to check
  /// [language] - Target language code (default: 'en')
  /// 
  /// Returns: true if simplified version exists
  bool hasTerm(String term, {String language = 'en'}) {
    final glossary = _glossary[language] ?? _glossary['en'] ?? {};
    return glossary.containsKey(term.toLowerCase());
  }

  /// Get all available terms for a language
  /// 
  /// [language] - Target language code (default: 'en')
  /// 
  /// Returns: Map of technical → simple terms
  Map<String, String> getAllTerms({String language = 'en'}) {
    return Map.from(_glossary[language] ?? _glossary['en'] ?? {});
  }
}
