module NonMultilingualPageExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :find_by_url, :language_param
      alias_method_chain :render, :language_detection
      alias_method_chain :headers, :language_detection
      alias_method_chain :response_code, :language_detection
      alias_method_chain :cache?, :language_detection
      alias_method_chain :process, :language_detection
    end
  end
  
  def find_by_url_with_language_param(url, live = true, clean = true)
    url = clean_url(url) if clean
    if url =~ %r{^#{ self.url }#{MultilingualPagesExtension::NON_MULTILINGUAL_ROUTE}(\w\w)\/$}
      Thread.current[:requested_language] = $1
      self
    else
      find_by_url_without_language_param(url, live, clean)
    end
  end
  
  def headers_with_language_detection
    needs_language_detection? ? { 'Location' => location, 'Vary' => "Accept-Language" } : headers_without_language_detection
  end
  
  def render_with_language_detection
    needs_language_detection? ? '<html><body>Redirecting...</body></html>' : render_without_language_detection
  end

  def response_code_with_language_detection
    needs_language_detection? ? 301 : response_code_without_language_detection
  end
  
  def cache_with_language_detection?
    needs_language_detection? ? false : cache_without_language_detection?
  end
  
  def process_with_language_detection(*args)
    returning(process_without_language_detection(*args)) do
      Thread.current[:requested_language] = nil
    end
  end
  
  private
  
  def needs_language_detection?
    MultilingualPagesExtension::USE_LANGUAGE_DETECTION and (not parent?) and Thread.current[:requested_language].nil?
  end
  
  def languages
    langs = (request.env["HTTP_ACCEPT_LANGUAGE"] || "").split(/[,\s]+/)
    langs_with_weights = langs.map do |ele|
      both = ele.split(/;q=/)
      lang = both[0].split('-').first
      weight = both[1] ? Float(both[1]) : 1
      [-weight, lang]
    end.sort_by(&:first).map(&:last)
  end

  def location
    language = languages.detect{|l| MultilingualPagesExtension::AVAILABLE_LANGUAGES.include?(l)} || MultilingualPagesExtension::DEFAULT_LANGUAGE
    path = clean_url("#{request.path}/#{MultilingualPagesExtension::NON_MULTILINGUAL_ROUTE}#{language}")
    "#{request.protocol}#{request.host_with_port}#{path}" << (request.query_string.blank? ? '' : "?#{request.query_string}")
  end  
  
end
