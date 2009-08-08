namespace :radiant do
  namespace :extensions do
    namespace :multilingual_pages do
      
      desc "Single task to install and update the Multilingual Pages extension"
      task :install => [:environment, :migrate]
      
      desc "Runs the migration of the Comments extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          MultilingualPagesExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          MultilingualPagesExtension.migrator.migrate
        end
      end
            
    end
  end
end