class MultilingualPage < Page

  description %{
    A multilingual page can have multiple slugs -- one in each supported language.
    This is it. no more. no less.
  }
  
  # TODO: support title, breadcrumb, description, keywords via multilingual_meta pagepart
  def slug
    if self.multilingual_slugs_by_language.blank? or Thread.current[:requested_language].blank?
      self.read_attribute(:slug)
    else
      self.multilingual_slugs_by_language[Thread.current[:requested_language]]
    end
  end
      
  def multilingual_slugs_by_language
    hash = {}
    (self.multilingual_slugs||[]).split(';').each do |part|
      language, slug = part.split('=')
      hash[language] = slug
    end
    return hash
  end

  def multilingual_slugs_by_slug
    hash = {}
    (self.multilingual_slugs||[]).split(';').each do |part|
      language, slug = part.split('=')
      hash[slug] = language
    end
    return hash
  end

end