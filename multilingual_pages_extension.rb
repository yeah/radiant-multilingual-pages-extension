class MultilingualPagesExtension < Radiant::Extension
  version '0.5'
  description 'Provides multilingual pages for Radiant. A multilingual page has one slug for every language.'
  url 'http://rocket-rentals.de'
  
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
    admin.page.edit.add(:form, "multilingual_slugs", :before => 'edit_extended_metadata')

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
                page.requested_language = language
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
  
  # TODO: Get an official, complete list...
  LANGUAGE_NAMES = {
    'en' => 'English',
    'de' => 'Deutsch',
    'fr' => 'Français',
    'es' => 'Espagnol',
    'it' => 'Italiano'
    # more...
  }
end