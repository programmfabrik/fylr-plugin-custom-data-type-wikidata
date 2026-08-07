class WikidataUtil

  # from https://github.com/programmfabrik/coffeescript-ui/blob/fde25089327791d9aca540567bfa511e64958611/src/base/util.coffee#L506
  # has to be reused here, because cui not be used in updater
  @isEqual: (x, y, debug) ->
    #// if both are function
    if x instanceof Function
      if y instanceof Function
        return x.toString() == y.toString()
      return false

    if x == null or x == undefined or y == null or y == undefined
      return x == y

    if x == y or x.valueOf() == y.valueOf()
      return true

    # if one of them is date, they must had equal valueOf
    if x instanceof Date
      return false

    if y instanceof Date
      return false

    # if they are not function or strictly equal, they both need to be Objects
    if not (x instanceof Object)
      return false

    if not (y instanceof Object)
      return false

    p = Object.keys(x)
    if Object.keys(y).every( (i) -> return p.indexOf(i) != -1 )
      return p.every((i) =>
        eq = @isEqual(x[i], y[i], debug)
        if not eq
          if debug
            console.debug("X: ",x)
            console.debug("Differs to Y:", y)
            console.debug("Key differs: ", i)
            console.debug("Value X:", x[i])
            console.debug("Value Y:", y[i])
          return false
        else
          return true
      )
    else
      return false

  @getPreview: (result) ->
    # Start building the HTML
    html = '<article class="wikidataTooltip">'

    # Add the image section if it exists
    if result.image
      html += """
        <figure class="wikidataTooltip-image">
          <img src="#{result.image}" alt="Image">
        </figure>
      """

    # Add content for languages (excluding 'image' and 'uri')
    html += '<section class="wikidataTooltip-content">'

    for lang, content of result when not ["image", "uri"].includes(lang)
      continue unless content.label? # skip generating section for lang if it has no label

      # Decode aliases, label, and description
      aliasesString = if content.aliases?.length
        " (alias: #{content.aliases.join(', ')})"
      else ""

      # decode lang
      langDecoded = $$('base.culture.' + lang.replace(',', '-'))

      # Incrementally add a language entry
      html += """
        <section class="wikidataTooltip-entry">
          <h3 class="wikidataTooltip-lang">#{langDecoded}:</h3>
          <p class="wikidataTooltip-label"><b>#{content.label or ''}</b><br>#{content.description or ''}</p>
          <p class="wikidataTooltip-aliases">#{aliasesString}</p>
        </section>
      """

    # Close the content section
    html += '</section>'

    # Add the URI section if it exists
    if result.uri
      html += """
        <footer class="wikidataTooltip-uri">
          <a href="#{result.uri}" target="_blank" rel="noopener noreferrer">#{result.uri}</a>
        </footer>
      """

    # Close the outermost article
    html += '</article>'

    # Return the final HTML
    html

  ########################################################################
  # generates the fulltext for record
  ########################################################################
  @getAdditionalTextFromObject: (item, uiLang, dbLangsLong) ->
    #console.error("these is the item given to utilities.coffee"+ JSON.stringify(item))
    uri = "https://www.wikidata.org/entity/" + item.id

    facetTerm = {}
    _fulltext = { l10ntext: {}, text: null }
    _standard = { l10ntext: {} }

    dbLangsLong.forEach (lang) ->
      l = lang.split('-')[0] # wikidata just uses "en" instead of "en-US" instead of [0..1], use str before "-", if there is any
      label = item.labels?[l]?.value or null
      if ! label
        label = item.labels[Object.keys(item.labels)[0]].value

      description = item.descriptions?[l]?.value or null
      if ! description
        for descriptionKey, descriptionEntry of item.descriptions
          description = descriptionEntry.value
          break;

      facetTerm[lang] = [label, uri].join("@$@").trim()
      _fulltext.l10ntext[lang] = [description, label, uri].join(" ").trim()
      _standard.l10ntext[lang] = label.trim()
      if l == uiLang.split('-')[0] # just handle case where uiLang is "en" and also "en-US" for laziness
        _fulltext.text = [description, label, uri].join(" ").trim()

    {
      facetTerm: facetTerm,
      _fulltext: _fulltext,
      _standard: _standard
    }
