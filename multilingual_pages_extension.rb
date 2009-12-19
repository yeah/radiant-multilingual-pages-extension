class MultilingualPagesExtension < Radiant::Extension
  version '0.5'
  description 'Provides multilingual pages for Radiant. A multilingual page has one slug for every language.'
  url 'http://github.com/yeah/radiant-multilingual-pages-extension/tree/master'
  
  def activate
    
    # load the new page model class
    MultilingualPage
    
    # get config from database or initialize defaults
    if Radiant::Config.table_exists?
      {:default_language => 'en', 
       :non_multilingual_route => 'lang-', 
       :meta_part_name => 'multilingual meta', 
       :available_languages => 'en',
       :use_language_detection => true}.each do |key,value|
        Radiant::Config["multilingual.#{key}"] = value unless Radiant::Config["multilingual.#{key}"]
        value = Radiant::Config["multilingual.#{key}"].blank? ? Radiant::Config["multilingual.#{key}"] : YAML.load(Radiant::Config["multilingual.#{key}"])
        MultilingualPagesExtension.const_set(key.to_s.upcase, value)
      end
    end
    
    # adapt page edit admin ui
    admin.page.edit.add(:extended_metadata, "multilingual_slugs", :before => 'edit_extended_metadata')

    # enable tags in regular and multilingual pages
    MultilingualPage.send(:include, MultilingualPageTags)
    Page.send(:include, MultilingualPageTags)

    # redefine find_by_slug for children collection on pages (for discovery using multilingual slugs)
    Page.class_eval do
      include MultilingualPageTags
      has_many( :children, :class_name => name, :foreign_key => 'parent_id' ) do 
        def find_by_slug(slug)
          if page = super(slug)
            return page 
          elsif pages = find(:all, :conditions => ['multilingual_slugs LIKE ? AND parent_id=?',"%#{slug}%", proxy_owner.id])
            pages.each do |page|
              if language = page.multilingual_slugs_by_slug[slug]
                Thread.current[:requested_language] = language
                return page
              end
            end
          end
          return nil
        end
      end
    end
    
    # enable handling for non multilingual pages (for dicsovery using .../lang-<your lang> style routes)
    Page.send(:include, NonMultilingualPageExtensions)
    
  end
  
  def deactivate
  end
  
  LANGUAGE_NAMES = {
    'aa' => 'Afaraf',
    'ab' => 'Аҧсуа',
    'ae' => 'avesta',
    'af' => 'Afrikaans',
    'ak' => 'Akan',
    'am' => 'አማርኛ',
    'an' => 'Aragonés',
    'ar' => 'العربية',
    'as' => 'অসমীয়া',
    'av' => 'авар мацӀ, магӀарул мацӀ',
    'ay' => 'aymar aru',
    'az' => 'azərbaycan dili',
    'ba' => 'башҡорт теле',
    'be' => 'Беларуская',
    'bg' => 'български език',
    'bh' => 'भोजपुरी',
    'bi' => 'Bislama',
    'bm' => 'bamanankan',
    'bn' => 'বাংলা',
    'bo' => 'བོད་ཡིག',
    'br' => 'brezhoneg',
    'bs' => 'bosanski jezik',
    'ca' => 'Català',
    'ce' => 'нохчийн мотт',
    'ch' => 'Chamoru',
    'co' => 'corsu, lingua corsa',
    'cr' => 'ᓀᐦᐃᔭᐍᐏᐣ',
    'cs' => 'česky, čeština',
    'cu' => 'ѩзыкъ словѣньскъ',
    'cv' => 'чӑваш чӗлхи',
    'cy' => 'Cymraeg',
    'da' => 'dansk',
    'de' => 'Deutsch',
    'dv' => 'ދިވެހި',
    'dz' => 'རྫོང་ཁ',
    'ee' => 'Ɛʋɛgbɛ',
    'el' => 'Ελληνικά',
    'en' => 'English',
    'eo' => 'Esperanto',
    'es' => 'español, castellano',
    'et' => 'eesti, eesti keel',
    'eu' => 'euskara, euskera',
    'fa' => 'فارسی',
    'ff' => 'Fulfulde',
    'fi' => 'suomi, suomen kieli',
    'fj' => 'vosa Vakaviti',
    'fo' => 'føroyskt',
    'fr' => 'français, langue française',
    'fy' => 'Frysk',
    'ga' => 'Gaeilge',
    'gd' => 'Gàidhlig',
    'gl' => 'Galego',
    'gn' => 'Avañe\'ẽ',
    'gu' => 'ગુજરાતી',
    'gv' => 'Gaelg, Gailck',
    'ha' => 'هَوُسَ',
    'he' => 'עברית',
    'hi' => 'हिन्दी, हिंदी',
    'ho' => 'Hiri Motu',
    'hr' => 'Hrvatski',
    'ht' => 'Kreyòl ayisyen',
    'hu' => 'Magyar',
    'hy' => 'Հայերեն',
    'hz' => 'Otjiherero',
    'ia' => 'Interlingua',
    'id' => 'Bahasa Indonesia',
    'ie' => 'Interlingue',
    'ig' => 'Igbo',
    'ii' => 'ꆇꉙ',
    'ik' => 'Iñupiaq, Iñupiatun',
    'io' => 'Ido',
    'is' => 'Íslenska',
    'it' => 'Italiano',
    'iu' => 'ᐃᓄᒃᑎᑐᑦ',
    'ja' => '日本語 (にほんご／にっぽんご)',
    'jv' => 'basa Jawa',
    'ka' => 'ქართული',
    'kg' => 'KiKongo',
    'ki' => 'Gĩkũyũ',
    'kj' => 'Kuanyama',
    'kk' => 'Қазақ тілі',
    'kl' => 'kalaallisut, kalaallit oqaasii',
    'km' => 'ភាសាខ្មែរ',
    'kn' => 'ಕನ್ನಡ',
    'ko' => '한국어 (韓國語), 조선말 (朝鮮語)',
    'kr' => 'Kanuri',
    'ks' => 'कश्मीरी, كشميري‎',
    'ku' => 'Kurdî, كوردی‎',
    'kv' => 'коми кыв',
    'kw' => 'Kernewek',
    'ky' => 'кыргыз тили',
    'la' => 'latine, lingua latina',
    'lb' => 'Lëtzebuergesch',
    'lg' => 'Luganda',
    'li' => 'Limburgs',
    'ln' => 'Lingála',
    'lo' => 'ພາສາລາວ',
    'lt' => 'lietuvių kalba',
    'lv' => 'latviešu valoda',
    'mg' => 'Malagasy fiteny',
    'mh' => 'Kajin M̧ajeļ',
    'mi' => 'te reo Māori',
    'mk' => 'македонски јазик',
    'ml' => 'മലയാളം',
    'mn' => 'Монгол',
    'mr' => 'मराठी',
    'ms' => 'bahasa Melayu, بهاس ملايو‎',
    'mt' => 'Malti',
    'my' => 'ဗမာစာ',
    'na' => 'Ekakairũ Naoero',
    'nb' => 'Norsk bokmål',
    'nd' => 'isiNdebele',
    'ne' => 'नेपाली',
    'ng' => 'Owambo',
    'nl' => 'Nederlands',
    'nn' => 'Norsk nynorsk',
    'no' => 'Norsk',
    'nr' => 'isiNdebele',
    'nv' => 'Diné bizaad, Dinékʼehǰí',
    'ny' => 'chiCheŵa, chinyanja',
    'oc' => 'Occitan',
    'oj' => 'ᐊᓂᔑᓈᐯᒧᐎᓐ',
    'om' => 'Afaan Oromoo',
    'or' => 'ଓଡ଼ିଆ',
    'os' => 'Ирон æвзаг',
    'pa' => 'ਪੰਜਾਬੀ, پنجابی‎',
    'pi' => 'पाऴि',
    'pl' => 'polski',
    'ps' => 'پښتو',
    'pt' => 'Português',
    'qu' => 'Runa Simi, Kichwa',
    'rm' => 'rumantsch grischun',
    'rn' => 'kiRundi',
    'ro' => 'română',
    'ru' => 'русский язык',
    'rw' => 'Ikinyarwanda',
    'sa' => 'संस्कृतम्',
    'sc' => 'sardu',
    'sd' => 'सिन्धी, سنڌي، سندھی‎',
    'se' => 'Davvisámegiella',
    'sg' => 'yângâ tî sängö',
    'si' => 'සිංහල',
    'sk' => 'slovenčina',
    'sl' => 'slovenščina',
    'sm' => 'gagana fa\'a Samoa',
    'sn' => 'chiShona',
    'so' => 'Soomaaliga, af Soomaali',
    'sq' => 'Shqip',
    'sr' => 'српски језик',
    'ss' => 'SiSwati',
    'st' => 'Sesotho',
    'su' => 'Basa Sunda',
    'sv' => 'svenska',
    'sw' => 'Kiswahili',
    'ta' => 'தமிழ்',
    'te' => 'తెలుగు',
    'tg' => 'тоҷикӣ, toğikī, تاجیکی‎',
    'th' => 'ไทย',
    'ti' => 'ትግርኛ',
    'tk' => 'Türkmen, Түркмен',
    'tl' => 'Tagalog',
    'tn' => 'Setswana',
    'to' => 'faka Tonga',
    'tr' => 'Türkçe',
    'ts' => 'Xitsonga',
    'tt' => 'татарча, tatarça, تاتارچا‎',
    'tw' => 'Twi',
    'ty' => 'Reo Mā`ohi',
    'ug' => 'Uyƣurqə, ئۇيغۇرچە‎',
    'uk' => 'Українська',
    'ur' => 'اردو',
    'uz' => 'O\'zbek, Ўзбек, أۇزبېك‎',
    've' => 'Tshivenḓa',
    'vi' => 'Tiếng Việt',
    'vo' => 'Volapük',
    'wa' => 'Walon',
    'wo' => 'Wollof',
    'xh' => 'isiXhosa',
    'yi' => 'ייִדיש',
    'yo' => 'Yorùbá',
    'za' => 'Saɯ cueŋƅ, Saw cuengh',
    'zh' => '中文 (Zhōngwén), 汉语, 漢語',
    'zu' => 'isiZulu'
  }
end
