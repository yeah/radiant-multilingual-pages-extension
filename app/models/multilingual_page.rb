class MultilingualPage < Page

  description %{
    A multilingual page can have multiple slugs -- one in each supported language.
    This is it. no more. no less.
  }

  MULTILINGUAL_META_PART_NAME = 'multilingual meta'

  after_save :initialize_multilingual_meta_part
  
  def slug
    if self.multilingual_slugs_by_language.blank? or Thread.current[:requested_language].blank?
      self.read_attribute(:slug)
    else
      self.multilingual_slugs_by_language[Thread.current[:requested_language]]
    end
  end

  def title
    multilingual_meta(:title)
  end

  def breadcrumb
    multilingual_meta(:breadcrumb)
  end

  def description
    multilingual_meta(:description)
  end

  def keywords
    multilingual_meta(:keywords)
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
en:
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

end