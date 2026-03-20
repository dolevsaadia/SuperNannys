/// Complete list of Israeli cities for autocomplete search.
class IsraeliCities {
  static const List<String> all = [
    'Jerusalem', 'Tel Aviv', 'Haifa', 'Rishon LeZion', 'Petah Tikva',
    'Ashdod', 'Netanya', 'Beer Sheva', 'Bnei Brak', 'Holon',
    'Ramat Gan', 'Rehovot', 'Ashkelon', 'Bat Yam', 'Herzliya',
    'Kfar Saba', 'Modi\'in', 'Hadera', 'Nazareth', 'Lod',
    'Ramla', 'Ra\'anana', 'Givatayim', 'Hod HaSharon', 'Kiryat Ata',
    'Nahariya', 'Acre', 'Kiryat Gat', 'Eilat', 'Kiryat Motzkin',
    'Rosh HaAyin', 'Afula', 'Nes Ziona', 'Kiryat Yam', 'Carmiel',
    'Tiberias', 'Yavne', 'Or Yehuda', 'Kiryat Bialik', 'Kiryat Ono',
    'Ma\'ale Adumim', 'Or Akiva', 'Yokneam', 'Sderot', 'Arad',
    'Migdal HaEmek', 'Dimona', 'Kiryat Shmona', 'Netivot', 'Ofakim',
    'Sakhnin', 'Tirat Carmel', 'Beit She\'an', 'Beit Shemesh', 'Modi\'in Illit',
    'Nof HaGalil', 'Rahat', 'Ariel', 'Shoham', 'Zichron Ya\'akov',
    'Caesarea', 'Pardes Hanna', 'Gedera', 'Gan Yavne', 'Givat Shmuel',
    'Savyon', 'Mevaseret Zion', 'Even Yehuda', 'Kadima-Zoran', 'Kfar Yona',
    'Nesher', 'Daliyat al-Karmel', 'Jisr az-Zarqa', 'Tamra', 'Umm al-Fahm',
    'Baqa al-Gharbiyye', 'Shfar\'am', 'Kafr Qasim', 'Tayibe', 'Tira',
    'Qalansawe', 'Kafr Kanna', 'Arraba', 'Deir al-Asad', 'Maghar',
    'Iksal', 'Yarka', 'Jatt', 'Beit Jann', 'Peki\'in',
    'Daliat al-Karmel', 'Isfiya', 'Fureidis', 'Abu Ghosh', 'Ein Rafa',
    'Kiryat Malachi', 'Kiryat Tivon', 'Kiryat Ekron',
  ];

  /// Hebrew names mapped to English for search
  static const Map<String, String> hebrewToEnglish = {
    'ירושלים': 'Jerusalem',
    'תל אביב': 'Tel Aviv',
    'חיפה': 'Haifa',
    'ראשון לציון': 'Rishon LeZion',
    'פתח תקווה': 'Petah Tikva',
    'אשדוד': 'Ashdod',
    'נתניה': 'Netanya',
    'באר שבע': 'Beer Sheva',
    'בני ברק': 'Bnei Brak',
    'חולון': 'Holon',
    'רמת גן': 'Ramat Gan',
    'רחובות': 'Rehovot',
    'אשקלון': 'Ashkelon',
    'בת ים': 'Bat Yam',
    'הרצליה': 'Herzliya',
    'כפר סבא': 'Kfar Saba',
    'מודיעין': 'Modi\'in',
    'חדרה': 'Hadera',
    'נצרת': 'Nazareth',
    'לוד': 'Lod',
    'רמלה': 'Ramla',
    'רעננה': 'Ra\'anana',
    'גבעתיים': 'Givatayim',
    'הוד השרון': 'Hod HaSharon',
    'קריית אתא': 'Kiryat Ata',
    'נהריה': 'Nahariya',
    'עכו': 'Acre',
    'קריית גת': 'Kiryat Gat',
    'אילת': 'Eilat',
    'קריית מוצקין': 'Kiryat Motzkin',
    'ראש העין': 'Rosh HaAyin',
    'עפולה': 'Afula',
    'נס ציונה': 'Nes Ziona',
    'קריית ים': 'Kiryat Yam',
    'כרמיאל': 'Carmiel',
    'טבריה': 'Tiberias',
    'יבנה': 'Yavne',
    'אור יהודה': 'Or Yehuda',
    'קריית ביאליק': 'Kiryat Bialik',
    'קריית אונו': 'Kiryat Ono',
    'מעלה אדומים': 'Ma\'ale Adumim',
    'אור עקיבא': 'Or Akiva',
    'יקנעם': 'Yokneam',
    'שדרות': 'Sderot',
    'ערד': 'Arad',
    'מגדל העמק': 'Migdal HaEmek',
    'דימונה': 'Dimona',
    'קריית שמונה': 'Kiryat Shmona',
    'נתיבות': 'Netivot',
    'אופקים': 'Ofakim',
    'סכנין': 'Sakhnin',
    'טירת כרמל': 'Tirat Carmel',
    'בית שאן': 'Beit She\'an',
    'בית שמש': 'Beit Shemesh',
    'מודיעין עילית': 'Modi\'in Illit',
    'נוף הגליל': 'Nof HaGalil',
    'רהט': 'Rahat',
    'אריאל': 'Ariel',
    'שוהם': 'Shoham',
    'זכרון יעקב': 'Zichron Ya\'akov',
    'קיסריה': 'Caesarea',
    'פרדס חנה': 'Pardes Hanna',
    'גדרה': 'Gedera',
    'גן יבנה': 'Gan Yavne',
    'גבעת שמואל': 'Givat Shmuel',
    'כפר יונה': 'Kfar Yona',
    'נשר': 'Nesher',
    'טמרה': 'Tamra',
    'אום אל פחם': 'Umm al-Fahm',
    'טייבה': 'Tayibe',
    'טירה': 'Tira',
    'קלנסווה': 'Qalansawe',
    'כפר קאסם': 'Kafr Qasim',
    'שפרעם': 'Shfar\'am',
    'כפר כנא': 'Kafr Kanna',
    'עראבה': 'Arraba',
    'דיר אל אסד': 'Deir al-Asad',
    'מגאר': 'Maghar',
    'יאט': 'Jatt',
    'בית ג\'ן': 'Beit Jann',
    'אבו גוש': 'Abu Ghosh',
    'קריית מלאכי': 'Kiryat Malachi',
    'קריית טבעון': 'Kiryat Tivon',
  };

  /// Reverse map: English to Hebrew
  static final Map<String, String> englishToHebrew = {
    for (final e in hebrewToEnglish.entries) e.value: e.key,
  };

  /// Get the Hebrew name for a city (for backend search — DB stores Hebrew)
  static String? getHebrewName(String englishOrHebrew) {
    // Already Hebrew?
    if (hebrewToEnglish.containsKey(englishOrHebrew)) return englishOrHebrew;
    // English → Hebrew
    return englishToHebrew[englishOrHebrew];
  }

  /// Search cities by query (supports Hebrew and English).
  /// Returns display names (English) but each result can be mapped to Hebrew via [getHebrewName].
  static List<String> search(String query) {
    if (query.isEmpty) return all.take(20).toList();
    final q = query.toLowerCase();

    // Check Hebrew input first
    final hebrewMatches = hebrewToEnglish.entries
        .where((e) => e.key.contains(query))
        .map((e) => e.value)
        .toList();
    if (hebrewMatches.isNotEmpty) return hebrewMatches;

    // English search
    return all.where((city) => city.toLowerCase().contains(q)).toList();
  }

  /// Convert a city name to the backend search value.
  /// The DB stores Hebrew names, so we convert English → Hebrew when possible.
  static String toBackendQuery(String city) {
    return getHebrewName(city) ?? city;
  }
}
