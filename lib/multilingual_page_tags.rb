module MultilingualPageTags
  include Radiant::Taggable
  
  desc %{
    Renders a string according to the current language.
    
    *Usage:*
    <pre><code><r:translate en="Welcome" de="Willkommen" /></code></pre>    
  }
  tag "translate" do |tag|
    tag.attr[Thread.current[:requested_language]||MultilingualPagesExtension::DEFAULT_LANGUAGE]
  end
    
  desc %{
    Expands if the current language matches the lang attribute.

    *Usage:*
    <pre><code><r:if_language lang="en"><p>This is an english paragraph.</p></r:if_language></code></pre>
    <pre><code><r:if_language lang="de"><p>Dies ist ein Absatz auf deutsch.</p></r:if_language></code></pre>
  }
  tag "if_language" do |tag|
    tag.expand if tag.attr['lang'] == (Thread.current[:requested_language]||MultilingualPagesExtension::DEFAULT_LANGUAGE)
  end
    
end