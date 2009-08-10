class MultilingualPage < Page

  description 'Provides multilingual pages for Radiant. A multilingual page has one slug for every language.'

  after_save :initialize_multilingual_meta_part
  after_save :update_languages_in_config
  
  def slug(language=nil)
    language ||= Thread.current[:requested_language]
    self.multilingual_slugs_by_language[language||MultilingualPagesExtension::DEFAULT_LANGUAGE]||self.read_attribute(:slug)
  end
  
  def url(language=nil)
    if language.nil?
      super()
    elsif parent? and parent.is_a?(MultilingualPage)
      parent.child_url(self,language)
    elsif parent?
      parent.child_url(self).gsub("/#{slug}/","/#{slug(language)}/")
    else
      clean_url(slug(language))
    end
  end
  
  def child_url(child, language=nil)
    if language.nil?
      super(child)
    else
      clean_url(url(language) + '/' + child.slug(language))
    end
  end
  

  def title ; multilingual_meta(:title) ; end
  def breadcrumb ; multilingual_meta(:breadcrumb) ; end
  def description ; multilingual_meta(:description) ; end
  def keywords ; multilingual_meta(:keywords) ; end
            
  def languages
    ([MultilingualPagesExtension::DEFAULT_LANGUAGE] + self.multilingual_slugs_by_language.keys).uniq
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

  def multilingual_meta(attr,language=nil)
    language ||= Thread.current[:requested_language]
    if language and 
      part = parts.detect{|part| part.name == MultilingualPagesExtension::META_PART_NAME} and
      meta = YAML.load(part.content)[language]

      meta[attr.to_s]
    else 
      read_attribute(attr.to_sym)
    end
  end

  private

  def initialize_multilingual_meta_part
    unless parts.any? { |part| part.name == MultilingualPagesExtension::META_PART_NAME }
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
      parts.create(:name => MultilingualPagesExtension::META_PART_NAME, :content => content) 
    end
  end
  
  def update_languages_in_config
    languages.each do |language|
      unless MultilingualPagesExtension::AVAILABLE_LANGUAGES.split(',').include?(language)
        Radiant::Config['multilingual.available_languages'] += ",#{language}"
        MultilingualPagesExtension.const_set('AVAILABLE_LANGUAGES', Radiant::Config['multilingual.available_languages'])
      end
    end
  end

end