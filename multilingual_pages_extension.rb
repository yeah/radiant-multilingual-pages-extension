class MultilingualPagesExtension < Radiant::Extension
  version "0.1"
  description "Provides multilingual pages for Radiant."
  url "http://rocket-rentals.de"
  
  def activate
    MultilingualPage
    admin.page.edit.add(:form, "multilingual_slugs", :before => 'edit_extended_metadata')
    MultilingualPage.send :include, MultilingualPageTags
    Page.send :include, MultilingualPageTags
    Page.class_eval do
      has_many( :children, :class_name => name, :foreign_key => 'parent_id' ) do 
        def find_by_slug(slug)
          if found = super(slug)
            return found 
          elsif pages = MultilingualPage.find(:all, :conditions => ['multilingual_slugs LIKE ? AND parent_id=?',"%#{slug}%", proxy_owner.id])
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
  
  def deactivate
  end
end