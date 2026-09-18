class IndicTransliteration {
  // Check if a string contains any Indic Unicode script (Devanagari to Malayalam: 0x0900 - 0x0D7F)
  static bool containsIndic(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // All Indian Brahmi-derived scripts: 0x0900 (Devanagari) to 0x0D7F (Malayalam)
      if (code >= 0x0900 && code <= 0x0D7F) {
        return true;
      }
    }
    return false;
  }

  // --- Devanagari (Hindi, Marathi, Bhojpuri, Sanskrit, Nepali) ---
  static const Map<String, String> _devaVowels = {
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo',
    'ऋ': 'ri', 'ॠ': 'ree', 'ऌ': 'li', 'ॡ': 'lee',
    'ऍ': 'e', 'ऎ': 'e', 'ए': 'e', 'ऐ': 'ai', 'ऑ': 'o', 'ऒ': 'o',
    'ओ': 'o', 'औ': 'au',
  };
  static const Map<String, String> _devaMatras = {
    'ा': 'aa', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo',
    'ृ': 'ri', 'ॄ': 'ree', 'ॢ': 'li', 'ॣ': 'lee',
    'ॅ': 'e', 'ॆ': 'e', 'े': 'e', 'ै': 'ai',
    'ॉ': 'o', 'ॊ': 'o', 'ो': 'o', 'ौ': 'au',
  };
  static const Map<String, String> _devaConsonants = {
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
    'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
    'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
    'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v',
    'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
    'ळ': 'l', 'क़': 'q', 'ख़': 'kh', 'ग़': 'gh', 'ज़': 'z',
    'ड़': 'r', 'ढ़': 'rh', 'फ़': 'f', 'य़': 'y',
  };

  // --- Gurmukhi (Punjabi) ---
  static const Map<String, String> _gurmukhiVowels = {
    'ਅ': 'a', 'ਆ': 'aa', 'ਇ': 'i', 'ਈ': 'ee', 'ਉ': 'u', 'ਊ': 'oo',
    'ਏ': 'e', 'ਐ': 'ai', 'ਓ': 'o', 'ਔ': 'au',
    'ੳ': 'u', 'ੲ': 'i', 'ੴ': 'ik onkar',
  };
  static const Map<String, String> _gurmukhiMatras = {
    'ਾ': 'aa', 'ਿ': 'i', 'ੀ': 'ee', 'ੁ': 'u', 'ੂ': 'oo',
    'ੇ': 'e', 'ੈ': 'ai', 'ੋ': 'o', 'ੌ': 'au',
  };
  static const Map<String, String> _gurmukhiConsonants = {
    'ਕ': 'k', 'ਖ': 'kh', 'ਗ': 'g', 'ਘ': 'gh', 'ਙ': 'ng',
    'ਚ': 'ch', 'ਛ': 'chh', 'ਜ': 'j', 'ਝ': 'jh', 'ਞ': 'ny',
    'ਟ': 't', 'ਠ': 'th', 'ਡ': 'd', 'ਢ': 'dh', 'ਣ': 'n',
    'ਤ': 't', 'ਥ': 'th', 'ਦ': 'd', 'ਧ': 'dh', 'ਨ': 'n',
    'ਪ': 'p', 'ਫ': 'ph', 'ਬ': 'b', 'ਭ': 'bh', 'ਮ': 'm',
    'ਯ': 'y', 'ਰ': 'r', 'ਲ': 'l', 'ਵ': 'v', 'ੜ': 'r',
    'ਸ': 's', 'ਹ': 'h',
    'ਸ਼': 'sh', 'ਖ਼': 'kh', 'ਗ਼': 'gh', 'ਜ਼': 'z', 'ਫ਼': 'f', 'ਲ਼': 'l',
  };

  // --- Bengali & Assamese ---
  static const Map<String, String> _bengaliVowels = {
    'অ': 'o', 'আ': 'aa', 'ই': 'i', 'ঈ': 'ee', 'উ': 'u', 'ঊ': 'oo',
    'ঋ': 'ri', 'এ': 'e', 'ঐ': 'oi', 'ও': 'o', 'ঔ': 'ou',
  };
  static const Map<String, String> _bengaliMatras = {
    'া': 'aa', 'ি': 'i', 'ী': 'ee', 'ু': 'u', 'ূ': 'oo',
    'ৃ': 'ri', 'ে': 'e', 'ৈ': 'oi', 'ো': 'o', 'ৌ': 'ou',
  };
  static const Map<String, String> _bengaliConsonants = {
    'ক': 'k', 'খ': 'kh', 'গ': 'g', 'ঘ': 'gh', 'ঙ': 'ng',
    'চ': 'ch', 'ছ': 'chh', 'জ': 'j', 'ঝ': 'jh', 'ঞ': 'ny',
    'ট': 't', 'ঠ': 'th', 'ড': 'd', 'ढ': 'dh', 'ণ': 'n',
    'ত': 't', 'থ': 'th', 'দ': 'd', 'ਧ': 'dh', 'ন': 'n',
    'প': 'p', 'ফ': 'ph', 'ব': 'b', 'ভ': 'bh', 'ম': 'm',
    'য': 'j', 'র': 'r', 'ল': 'l', 'শ': 'sh', 'ষ': 'sh',
    'স': 's', 'হ': 'h', 'ড়': 'r', 'ঢ়': 'rh', 'য়': 'y',
  };

  // --- Gujarati ---
  static const Map<String, String> _gujaratiVowels = {
    'અ': 'a', 'આ': 'aa', 'ઇ': 'i', 'ઈ': 'ee', 'ઉ': 'u', 'ઊ': 'oo',
    'ઋ': 'ri', 'એ': 'e', 'ઐ': 'ai', 'ઓ': 'o', 'ઔ': 'au',
  };
  static const Map<String, String> _gujaratiMatras = {
    'ા': 'aa', 'િ': 'i', 'ી': 'ee', 'ુ': 'u', 'ૂ': 'oo',
    'ૃ': 'ri', 'ે': 'e', 'ૈ': 'ai', 'ો': 'o', 'ૌ': 'au',
  };
  static const Map<String, String> _gujaratiConsonants = {
    'ક': 'k', 'ખ': 'kh', 'ગ': 'g', 'ઘ': 'gh', 'ઙ': 'ng',
    'ચ': 'ch', 'છ': 'chh', 'જ': 'j', 'ઝ': 'jh', 'ઞ': 'ny',
    'ટ': 't', 'ઠ': 'th', 'ડ': 'd', 'ઢ': 'dh', 'ણ': 'n',
    'ત': 't', 'થ': 'th', 'દ': 'd', 'ધ': 'dh', 'ન': 'n',
    'પ': 'p', 'ફ': 'ph', 'બ': 'b', 'ભ': 'bh', 'મ': 'm',
    'ય': 'y', 'ર': 'r', 'લ': 'l', 'ળ': 'l', 'વ': 'v',
    'શ': 'sh', 'ષ': 'sh', 'સ': 's', 'હ': 'h',
  };

  // --- Odia ---
  static const Map<String, String> _odiaVowels = {
    'ଅ': 'a', 'ଆ': 'aa', 'ଇ': 'i', 'ଈ': 'ee', 'ଉ': 'u', 'ଊ': 'oo',
    'ଋ': 'ri', 'ଏ': 'e', 'ଐ': 'ai', 'ଓ': 'o', 'ଔ': 'au',
  };
  static const Map<String, String> _odiaMatras = {
    'ା': 'aa', 'ି': 'i', 'ୀ': 'ee', 'ୁ': 'u', 'ୂ': 'oo',
    'ୃ': 'ri', 'େ': 'e', 'ୈ': 'ai', 'ୋ': 'o', 'ୌ': 'au',
  };
  static const Map<String, String> _odiaConsonants = {
    'କ': 'k', 'ଖ': 'kh', 'ଗ': 'g', 'ଘ': 'gh', 'ଙ': 'ng',
    'ଚ': 'ch', 'ଛ': 'chh', 'ଜ': 'j', 'ଝ': 'jh', 'ଞ': 'ny',
    'ଟ': 't', 'ଠ': 'th', 'ଡ': 'd', 'ଢ': 'dh', 'ଣ': 'n',
    'ତ': 't', 'ଥ': 'th', 'ଦ': 'd', 'ଧ': 'dh', 'ନ': 'n',
    'ପ': 'p', 'ଫ': 'ph', 'ବ': 'b', 'ଭ': 'bh', 'ମ': 'm',
    'ଯ': 'j', 'ୟ': 'y', 'ର': 'r', 'ଳ': 'l', 'ଲ': 'l',
    'ଶ': 'sh', 'ଷ': 'sh', 'ସ': 's', 'ହ': 'h', 'ଡ଼': 'r', 'ଢ଼': 'rh',
  };

  // --- Telugu ---
  static const Map<String, String> _teluguVowels = {
    'అ': 'a', 'ఆ': 'aa', 'ఇ': 'i', 'ఈ': 'ee', 'ఉ': 'u', 'ఊ': 'oo',
    'ఋ': 'ri', 'ౠ': 'ree', 'ఎ': 'e', 'ఏ': 'ee', 'ఐ': 'ai',
    'ఒ': 'o', 'ఓ': 'oo', 'ఔ': 'au',
  };
  static const Map<String, String> _teluguMatras = {
    'ా': 'aa', 'ి': 'i', 'ీ': 'ee', 'ు': 'u', 'ూ': 'oo',
    'ృ': 'ri', 'ౄ': 'ree', 'ె': 'e', 'ే': 'ee', 'ై': 'ai',
    'ొ': 'o', 'ో': 'oo', 'ౌ': 'au',
  };
  static const Map<String, String> _teluguConsonants = {
    'క': 'k', 'ఖ': 'kh', 'గ': 'g', 'ఘ': 'gh', 'ఙ': 'ng',
    'చ': 'ch', 'ఛ': 'chh', 'జ': 'j', 'ఝ': 'jh', 'ఞ': 'ny',
    'ట': 't', 'ఠ': 'th', 'డ': 'd', 'ఢ': 'dh', 'ణ': 'n',
    'త': 't', 'థ': 'th', 'ద': 'd', 'ధ': 'dh', 'న': 'n',
    'ప': 'p', 'ఫ': 'ph', 'బ': 'b', 'భ': 'bh', 'మ': 'm',
    'య': 'y', 'ర': 'r', 'ల': 'l', 'వ': 'v', 'శ': 'sh',
    'ష': 'sh', 'స': 's', 'హ': 'h', 'ళ': 'l', 'ఱ': 'r',
  };

  // --- Kannada ---
  static const Map<String, String> _kannadaVowels = {
    'ಅ': 'a', 'ಆ': 'aa', 'ಇ': 'i', 'ಈ': 'ee', 'ಉ': 'u', 'ಊ': 'oo',
    'ಋ': 'ri', 'ಎ': 'e', 'ಏ': 'ee', 'ಐ': 'ai',
    'ಒ': 'o', 'ಓ': 'oo', 'ಔ': 'au',
  };
  static const Map<String, String> _kannadaMatras = {
    'ಾ': 'aa', 'ಿ': 'i', 'ೀ': 'ee', 'ು': 'u', 'ೂ': 'oo',
    'ೃ': 'ri', 'ೆ': 'e', 'ೇ': 'ee', 'ೈ': 'ai',
    'ೊ': 'o', 'ೋ': 'oo', 'ೌ': 'au',
  };
  static const Map<String, String> _kannadaConsonants = {
    'ಕ': 'k', 'ಖ': 'kh', 'ಗ': 'g', 'ಘ': 'gh', 'ಙ': 'ng',
    'ಚ': 'ch', 'ಛ': 'chh', 'ಜ': 'j', 'ಝ': 'jh', 'ಞ': 'ny',
    'ಟ': 't', 'ಠ': 'th', 'ಡ': 'd', 'ಢ': 'dh', 'ಣ': 'n',
    'ತ': 't', 'ಥ': 'th', 'ದ': 'd', 'ಧ': 'dh', 'ನ': 'n',
    'ಪ': 'p', 'ಫ': 'ph', 'ಬ': 'b', 'ಭ': 'bh', 'ಮ': 'm',
    'ಯ': 'y', 'ರ': 'r', 'ಲ': 'l', 'ವ': 'v', 'ಶ': 'sh',
    'ಷ': 'sh', 'ಸ': 's', 'ಹ': 'h', 'ಳ': 'l', 'ಱ': 'r', '಴': 'zh',
  };

  // --- Tamil ---
  static const Map<String, String> _tamilVowels = {
    'அ': 'a', 'ஆ': 'aa', 'இ': 'i', 'ஈ': 'ee', 'உ': 'u', 'ஊ': 'oo',
    'எ': 'e', 'ஏ': 'ee', 'ஐ': 'ai', 'ஒ': 'o', 'ஓ': 'oo', 'ஔ': 'au',
  };
  static const Map<String, String> _tamilMatras = {
    'ா': 'aa', 'ி': 'i', 'ீ': 'ee', 'ு': 'u', 'ூ': 'oo',
    'ெ': 'e', 'ே': 'ee', 'ை': 'ai', 'ொ': 'o', 'ோ': 'oo', 'ௌ': 'au',
  };
  static const Map<String, String> _tamilConsonants = {
    'க': 'k', 'ங': 'ng', 'ச': 's', 'ஞ': 'ny', 'ட': 't', 'ண': 'n',
    'த': 'th', 'ந': 'n', 'ப': 'p', 'ம': 'm', 'ய': 'y', 'ர': 'r',
    'ல': 'l', 'வ': 'v', 'ழ': 'zh', 'ள': 'l', 'ற': 'r', 'ன': 'n',
    'ஜ': 'j', 'ஷ': 'sh', 'ஸ': 's', 'ஹ': 'h',
  };

  // --- Malayalam ---
  static const Map<String, String> _malayalamVowels = {
    'അ': 'a', 'ആ': 'aa', 'ഇ': 'i', 'ഈ': 'ee', 'ഉ': 'u', 'ഊ': 'oo',
    'ഋ': 'ri', 'എ': 'e', 'ഏ': 'ee', 'ഐ': 'ai', 'ഒ': 'o', 'ഓ': 'oo', 'ഔ': 'au',
  };
  static const Map<String, String> _malayalamMatras = {
    'ാ': 'aa', 'ി': 'i', 'ീ': 'ee', 'ു': 'u', 'ൂ': 'oo',
    'ൃ': 'ri', 'െ': 'e', 'േ': 'ee', 'ൈ': 'ai', 'ൊ': 'o', 'ോ': 'oo', 'ൌ': 'au', 'ൗ': 'au',
  };
  static const Map<String, String> _malayalamConsonants = {
    'ക': 'k', 'ഖ': 'kh', 'ഗ': 'g', 'ഘ': 'gh', 'ങ': 'ng',
    'ച': 'ch', 'ഛ': 'chh', 'ജ': 'j', 'ഝ': 'jh', 'ഞ': 'ny',
    'ട': 't', 'ഠ': 'th', 'ഡ': 'd', 'ഢ': 'dh', 'ണ': 'n',
    'ത': 'th', 'ഥ': 'th', 'ദ': 'd', 'ധ': 'dh', 'ന': 'n',
    'പ': 'p', 'ഫ': 'ph', 'ബ': 'b', 'ഭ': 'bh', 'മ': 'm',
    'യ': 'y', 'ര': 'r', 'ല': 'l', 'വ': 'v', 'ശ': 'sh',
    'ഷ': 'sh', 'സ': 's', 'ഹ': 'h', 'ള': 'l', 'ഴ': 'zh', 'റ': 'r',
  };
  static const Map<String, String> _malayalamChillus = {
    'ൺ': 'n', 'ൻ': 'n', 'ർ': 'r', 'ൽ': 'l', 'ൾ': 'l', 'ൿ': 'k',
  };

  // Sanitize stray/broken combining characters attached to Latin/English text (e.g. fiिtoor -> fitoor)
  static String sanitizeBrokenCombiningMarks(String text) {
    // 1. Remove zero-width non-joiners/joiners around Latin letters
    var result = text.replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]+(?=[a-zA-Z\s])'), '');

    // 2. Fix patterns where Latin letters are immediately followed by Indic combining vowel marks
    result = result.replaceAllMapped(RegExp(r'([a-zA-Z])([\u0901-\u0903\u093E-\u094F\u0981-\u0983\u09BE-\u09CD\u0A01-\u0A03\u0A3E-\u0A4D\u0A81-\u0A83\u0ABE-\u0ACD\u0B01-\u0B03\u0B3E-\u0B4D\u0B82\u0BBE-\u0BCD\u0C00-\u0C03\u0C3E-\u0C4D\u0C81-\u0C83\u0CBE-\u0CCD\u0D01-\u0D03\u0D3E-\u0D4D]+)'), (m) {
      final prevChar = m.group(1)!;
      final mark = m.group(2)!;
      if ((prevChar.toLowerCase() == 'i' && (mark == 'ि' || mark == 'ി' || mark == 'ি' || mark == 'ਿ' || mark == 'િ' || mark == 'ి' || mark == 'ಿ' || mark == 'ி')) ||
          (prevChar.toLowerCase() == 'a' && (mark == 'ा' || mark == 'ാ' || mark == 'া' || mark == 'ਾ' || mark == 'ા' || mark == 'ా' || mark == 'ಾ' || mark == 'ா')) ||
          (prevChar.toLowerCase() == 'u' && (mark == 'ु' || mark == 'ു' || mark == 'ু' || mark == 'ੁ' || mark == 'ુ' || mark == 'ు' || mark == 'ੁ' || mark == 'ு')) ||
          (prevChar.toLowerCase() == 'e' && (mark == 'े' || mark == 'െ' || mark == 'ে' || mark == 'ੇ' || mark == 'ે' || mark == 'ె' || mark == 'ೆ' || mark == 'ெ')) ||
          (prevChar.toLowerCase() == 'o' && (mark == 'ो' || mark == 'ൊ' || mark == 'ো' || mark == 'ੋ' || mark == 'ો' || mark == 'ొ' || mark == 'ೊ' || mark == 'ொ'))) {
        return prevChar;
      }
      return prevChar;
    });

    // 3. Normalize common Romanized Hindi typos / glitch patterns
    result = result.replaceAll(RegExp(r'\busee\b', caseSensitive: false), 'usi');
    result = result.replaceAll(RegExp(r'\bkee\b', caseSensitive: false), 'ki');
    result = result.replaceAll(RegExp(r'\bteree\b', caseSensitive: false), 'teri');
    result = result.replaceAll(RegExp(r'\bmeree\b', caseSensitive: false), 'meri');

    return result;
  }

  static String transliterateLine(String line) {
    var text = sanitizeBrokenCombiningMarks(line);
    if (!containsIndic(text)) return text;

    final runes = text.runes.toList();
    final buffer = StringBuffer();
    int i = 0;

    while (i < runes.length) {
      final char = String.fromCharCode(runes[i]);
      final code = runes[i];

      // If it's outside Indic range (0x0900 - 0x0D7F), append as-is
      if (code < 0x0900 || code > 0x0D7F) {
        if (code != 0x200C && code != 0x200D && code != 0xFEFF) {
          buffer.write(char);
        }
        i++;
        continue;
      }

      // --- Devanagari (0x0900 - 0x097F) ---
      if (code >= 0x0900 && code <= 0x097F) {
        if (i + 1 < runes.length && String.fromCharCode(runes[i + 1]) == '़') {
          final combined = '$char\u093C';
          if (_devaConsonants.containsKey(combined)) {
            i = _processConsonant(runes, i + 1, _devaConsonants[combined]!, buffer, 'deva', '्', _devaMatras);
            continue;
          }
        }
        if (_devaVowels.containsKey(char)) {
          buffer.write(_devaVowels[char]);
          i++;
        } else if (_devaConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _devaConsonants[char]!, buffer, 'deva', '्', _devaMatras);
        } else if (char == 'ं' || char == 'ँ') {
          buffer.write('n');
          i++;
        } else if (char == 'ः') {
          buffer.write('h');
          i++;
        } else if (char == '्') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Bengali & Assamese (0x0980 - 0x09FF) ---
      else if (code >= 0x0980 && code <= 0x09FF) {
        if (_bengaliVowels.containsKey(char)) {
          buffer.write(_bengaliVowels[char]);
          i++;
        } else if (_bengaliConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _bengaliConsonants[char]!, buffer, 'bengali', '্', _bengaliMatras);
        } else if (char == 'ং' || char == 'ঁ') {
          buffer.write('ng');
          i++;
        } else if (char == 'ঃ') {
          buffer.write('h');
          i++;
        } else if (char == '্') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Gurmukhi / Punjabi (0x0A00 - 0x0A7F) ---
      else if (code >= 0x0A00 && code <= 0x0A7F) {
        if (i + 1 < runes.length && String.fromCharCode(runes[i + 1]) == '਼') {
          final combined = '$char\u0A3C';
          if (_gurmukhiConsonants.containsKey(combined)) {
            i = _processConsonant(runes, i + 1, _gurmukhiConsonants[combined]!, buffer, 'gurmukhi', '੍', _gurmukhiMatras);
            continue;
          }
        }
        if (_gurmukhiVowels.containsKey(char)) {
          buffer.write(_gurmukhiVowels[char]);
          i++;
        } else if (_gurmukhiConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _gurmukhiConsonants[char]!, buffer, 'gurmukhi', '੍', _gurmukhiMatras);
        } else if (char == 'ਂ' || char == 'ੰ') {
          buffer.write('n');
          i++;
        } else if (char == 'ੱ' || char == '੍') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Gujarati (0x0A80 - 0x0AFF) ---
      else if (code >= 0x0A80 && code <= 0x0AFF) {
        if (_gujaratiVowels.containsKey(char)) {
          buffer.write(_gujaratiVowels[char]);
          i++;
        } else if (_gujaratiConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _gujaratiConsonants[char]!, buffer, 'gujarati', '્', _gujaratiMatras);
        } else if (char == 'ં' || char == 'ઁ') {
          buffer.write('n');
          i++;
        } else if (char == 'ઃ') {
          buffer.write('h');
          i++;
        } else if (char == '્') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Odia (0x0B00 - 0x0B7F) ---
      else if (code >= 0x0B00 && code <= 0x0B7F) {
        if (_odiaVowels.containsKey(char)) {
          buffer.write(_odiaVowels[char]);
          i++;
        } else if (_odiaConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _odiaConsonants[char]!, buffer, 'odia', '୍', _odiaMatras);
        } else if (char == 'ଂ' || char == 'ଁ') {
          buffer.write('n');
          i++;
        } else if (char == 'ଃ') {
          buffer.write('h');
          i++;
        } else if (char == '୍') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Tamil (0x0B80 - 0x0BFF) ---
      else if (code >= 0x0B80 && code <= 0x0BFF) {
        if (_tamilVowels.containsKey(char)) {
          buffer.write(_tamilVowels[char]);
          i++;
        } else if (_tamilConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _tamilConsonants[char]!, buffer, 'tamil', '்', _tamilMatras);
        } else if (char == 'ஃ') {
          buffer.write('k');
          i++;
        } else if (char == '்') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Telugu (0x0C00 - 0x0C7F) ---
      else if (code >= 0x0C00 && code <= 0x0C7F) {
        if (_teluguVowels.containsKey(char)) {
          buffer.write(_teluguVowels[char]);
          i++;
        } else if (_teluguConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _teluguConsonants[char]!, buffer, 'telugu', '్', _teluguMatras);
        } else if (char == 'ం' || char == 'ఁ') {
          buffer.write('n');
          i++;
        } else if (char == 'ః') {
          buffer.write('h');
          i++;
        } else if (char == '్') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Kannada (0x0C80 - 0x0CFF) ---
      else if (code >= 0x0C80 && code <= 0x0CFF) {
        if (_kannadaVowels.containsKey(char)) {
          buffer.write(_kannadaVowels[char]);
          i++;
        } else if (_kannadaConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _kannadaConsonants[char]!, buffer, 'kannada', '್', _kannadaMatras);
        } else if (char == 'ಂ' || char == 'ಁ') {
          buffer.write('n');
          i++;
        } else if (char == 'ಃ') {
          buffer.write('h');
          i++;
        } else if (char == '್') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      }
      // --- Malayalam (0x0D00 - 0x0D7F) ---
      else if (code >= 0x0D00 && code <= 0x0D7F) {
        if (_malayalamChillus.containsKey(char)) {
          buffer.write(_malayalamChillus[char]);
          int nextIdx = i + 1;
          while (nextIdx < runes.length && (runes[nextIdx] == 0x200D || runes[nextIdx] == 0x200C)) {
            nextIdx++;
          }
          if (nextIdx < runes.length && String.fromCharCode(runes[nextIdx]) == '്') {
            nextIdx++;
          }
          i = nextIdx;
          continue;
        }

        if (_malayalamVowels.containsKey(char)) {
          buffer.write(_malayalamVowels[char]);
          i++;
        } else if (_malayalamConsonants.containsKey(char)) {
          i = _processConsonant(runes, i, _malayalamConsonants[char]!, buffer, 'malayalam', '്', _malayalamMatras);
        } else if (char == 'ം') {
          buffer.write('m');
          i++;
        } else if (char == 'ഃ') {
          buffer.write('h');
          i++;
        } else if (char == '്') {
          i++;
        } else {
          buffer.write(char);
          i++;
        }
      } else {
        buffer.write(char);
        i++;
      }
    }

    return buffer.toString();
  }

  static int _processConsonant(
    List<int> runes,
    int index,
    String romanConsonant,
    StringBuffer buffer,
    String script,
    String viramaChar,
    Map<String, String> matras,
  ) {
    buffer.write(romanConsonant);
    int nextIndex = index + 1;

    // Skip zero-width joiners / non-joiners
    while (nextIndex < runes.length &&
        (runes[nextIndex] == 0x200C || runes[nextIndex] == 0x200D || runes[nextIndex] == 0xFEFF)) {
      nextIndex++;
    }

    if (nextIndex >= runes.length) {
      if (script == 'malayalam' || script == 'tamil' || script == 'telugu' || script == 'kannada') {
        buffer.write('a');
      }
      return nextIndex;
    }

    final nextChar = String.fromCharCode(runes[nextIndex]);

    // Check if next character is a Virama (Halant)
    if (nextChar == viramaChar ||
        nextChar == '്' || nextChar == '्' || nextChar == '্' ||
        nextChar == '੍' || nextChar == '્' || nextChar == '୍' ||
        nextChar == '்' || nextChar == '్' || nextChar == '್') {
      return nextIndex + 1;
    }

    // Check if next character is a Matra (dependent vowel)
    if (matras.containsKey(nextChar)) {
      buffer.write(matras[nextChar]);
      return nextIndex + 1;
    }

    // If next character is whitespace or punctuation
    if (nextChar == ' ' ||
        nextChar == '\n' ||
        nextChar == '\r' ||
        nextChar == '\t' ||
        nextChar == ',' ||
        nextChar == '.' ||
        nextChar == '!' ||
        nextChar == '?' ||
        nextChar == '-' ||
        nextChar == '"' ||
        nextChar == '\'' ||
        nextChar == ']' ||
        nextChar == ')' ||
        nextChar == '(' ||
        nextChar == '[') {
      if (script == 'malayalam' || script == 'tamil' || script == 'telugu' || script == 'kannada') {
        buffer.write('a');
      }
      return nextIndex;
    }

    // If next character is a Latin letter
    final nextCode = runes[nextIndex];
    if ((nextCode >= 65 && nextCode <= 90) || (nextCode >= 97 && nextCode <= 122)) {
      return nextIndex;
    }

    // In the middle of a word with another consonant following, add inherent vowel 'a'
    buffer.write('a');
    return nextIndex;
  }

  static String transliterateLyrics(String lyrics) {
    if (lyrics.isEmpty) return lyrics;

    final lines = lyrics.split('\n');
    final processed = <String>[];

    final lrcTimeRegex = RegExp(r'^(\[\d{2}:\d{2}\.\d{2,3}\])(.*)$');

    for (final line in lines) {
      final match = lrcTimeRegex.firstMatch(line);
      if (match != null) {
        final timeTag = match.group(1)!;
        final textPart = match.group(2)!;
        processed.add('$timeTag${transliterateLine(textPart)}');
      } else {
        processed.add(transliterateLine(line));
      }
    }

    return processed.join('\n');
  }
}
