class MultilingualPagesExtension < Radiant::Extension
  version '0.3'
  description 'Provides multilingual pages for Radiant. A multilingual page has one slug for every language.'
  url 'http://rocket-rentals.de'
  
  def activate
    MultilingualPage
    if Radiant::Config.table_exists?
      {:default_language => 'en', :non_multilingual_route => 'lang-', :meta_part_name => 'multilingual meta'}.each do |key,value|
        Radiant::Config["multilingual.#{key}"] = value unless Radiant::Config["multilingual.#{key}"]
        MultilingualPagesExtension.const_set(key.to_s.upcase, Radiant::Config["multilingual.#{key}"])
      end
    end
    admin.page.edit.add(:form, "multilingual_slugs", :before => 'edit_extended_metadata')
    Page.send(:include, NonMultilingualPageExtensions)

    [Page, MultilingualPage].each do |klass|
      klass.class_eval do
        include MultilingualPageTags
        has_many( :children, :class_name => 'Page', :foreign_key => 'parent_id' ) do 
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
    end
  end
  
  def deactivate
  end
end