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
  
  desc %{
    Renders a list of links to versions of the page in other available languages. Links can have three states:

    * @current@ specifies the state of the link when this language is currently selected
    * @available@ specifies the state of the link when this page is translated and available in this language
    * @unavailable@ specifies the state of the link when this page is not translated in this language
    
    The @between@ tag specifies what should be inserted in between each of the links.

    *Usage (sample with flag icons):*

<pre><code>
<r:language_selection>
  <r:current>
    <img src="/images/flags/<r:language />.png" />
  </r:current>
  <r:available>
    <a href="<r:url />" title="<r:title />"><img src="/images/flags/<r:language />-inactive.png" /></a>
  </r:available>
  <r:unavailable>
    <img src="/images/flags/<r:language />-strikethrough.png" />
  </r:unavailable>
  <r:between>&nbsp;</r:between>
</r:language_selection>
</code></pre>
    
    *Usage (sample with select box):*

<pre><code>
<select onchange="location.href=this.value;">
  <r:language_selection>
    <r:current>
      <option selected="selected" value="<r:url />"><r:language_name /></option>
    </r:current>
    <r:available>
      <option value="<r:url />"><r:language_name /></option>
    </r:available>
    <r:unavailable>
      <option disabled="disabled" value="<r:url />"><r:language_name /></option>
    </r:unavailable>
  </r:language_selection>
</select>
</code></pre>

  }
  tag 'language_selection' do |tag|
    page = tag.locals.page
    hash = tag.locals.language_selection = {}
    tag.expand
    raise TagError.new("`navigation' tag must include an `available' tag") unless hash.has_key? :available
    result = []
        
    MultilingualPagesExtension::AVAILABLE_LANGUAGES.split(',').each do |language|
      hash[:title] = page.is_a?(MultilingualPage) ? page.multilingual_meta(:title, language) : page.title
      hash[:language] = language
      hash[:language_name] = MultilingualPagesExtension::LANGUAGE_NAMES[language]||language
      url = page.is_a?(MultilingualPage) ? page.url(language) : "#{page.url}#{MultilingualPagesExtension::NON_MULTILINGUAL_ROUTE}#{language}"
      hash[:url] = relative_url_for(url, tag.globals.page.request)
      
      if (Thread.current[:requested_language]||MultilingualPagesExtension::DEFAULT_LANGUAGE) == language
        result << hash[:current].call
      elsif page.is_a?(MultilingualPage) and not page.languages.include?(language)
        result << hash[:unavailable].call
      else
        result << hash[:available].call
      end
    end
    
    between = hash.has_key?(:between) ? hash[:between].call : ' '
    result.reject { |i| i.blank? }.join(between)
  end
  [:current, :available, :unavailable, :between].each do |symbol|
    tag "language_selection:#{symbol}" do |tag|
      hash = tag.locals.language_selection
      hash[symbol] = tag.block
    end
  end
  [:title, :language, :language_name, :url].each do |symbol|
    tag "language_selection:#{symbol}" do |tag|
      hash = tag.locals.language_selection
      hash[symbol]
    end
  end
  
    
end