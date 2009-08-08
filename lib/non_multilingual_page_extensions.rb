module NonMultilingualPageExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :find_by_url, :language_param
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
  
end
