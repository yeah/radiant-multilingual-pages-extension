class MultilingualPage < Page

  description 'Provides multilingual pages for Radiant. A multilingual page has one slug for every language.'

  MULTILINGUAL_META_PART_NAME = 'multilingual meta'

  after_save :initialize_multilingual_meta_part
  
  # we only redefine this for multilingual root pages,
  # the real multilingual discovery stuff happens in 
  # redefined Page -> children -> find_by_slug()...
  def find_by_url(orig_url, live = true, clean = true)
    return nil if virtual?
    url = clean_url(orig_url) if clean
    if (!parent?) and (language=multilingual_slugs_by_slug[url.gsub('/','')]) and (not live or published?)
      Thread.current[:requested_language] = language
      self
    else      
      super(orig_url, live, clean)
    end
  end
  
  def child_url(child)
    if parent?
      super(child)
    else
      clean_url(read_attribute(:slug) + '/' + child.slug)
    end
  end
  
  
  def slug
    if Thread.current[:requested_language].blank? or self.multilingual_slugs_by_language[Thread.current[:requested_language]].blank?
      self.read_attribute(:slug)
    else
      self.multilingual_slugs_by_language[Thread.current[:requested_language]]
    end
  end

  def title ; multilingual_meta(:title) ; end
  def breadcrumb ; multilingual_meta(:breadcrumb) ; end
  def description ; multilingual_meta(:description) ; end
  def keywords ; multilingual_meta(:keywords) ; end
            
  def languages ; self.multilingual_slugs_by_language.keys ; end

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

  private

  def initialize_multilingual_meta_part
    unless parts.any? { |part| part.name == MULTILINGUAL_META_PART_NAME }
      content = %{
#{MultilingualPagesExtension::DEFAULT_LANGUAGE}:
  title: #{read_attribute(:title)}
  breadcrumb: #{read_attribute(:breadcrumb)}
  description: #{read_attribute(:description)}
  keywords: #{read_attribute(:keywords)}
      }
      multilingual_slugs_by_language.each_pair do |language, slug|
        content << %{
#{language}:
  title: #{slug.underscore.humanize}        
  breadcrumb: #{slug.underscore.humanize}
  description: #{slug.underscore.humanize}
  keywords: #{slug.split(/\W/).join(', ')}
        }
      end
      parts.create(:name => MULTILINGUAL_META_PART_NAME, :content => content) 
    end
  end

  def multilingual_meta(attr)
    if Thread.current[:requested_language] and 
      part = parts.detect{|part| part.name == MULTILINGUAL_META_PART_NAME} and
      meta = YAML.load(part.content)[Thread.current[:requested_language]]

      meta[attr.to_s]
    else 
      read_attribute(attr.to_sym)
    end
  end

end