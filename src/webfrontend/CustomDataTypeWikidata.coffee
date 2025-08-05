class CustomDataTypeWikidata extends CustomDataTypeWithCommonsAsPlugin

  #######################################################################  
  # return the prefix for localization for this data type.  
  # Note: This function is supposed to be deprecated, but is still used   
  # internally and has to be used here as a workaround because the   
  # default generates incorrect prefixes for camelCase class names 
  getL10NPrefix: ->
    'custom.data.type.wikidata'

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-wikidata.wikidata"


  #######################################################################
  # configure used facet
  getFacet: (opts) ->
    opts.field = @
    new CustomDataTypeWikidataFacet(opts)


  #######################################################################
  # overwrite getCustomSchemaSettings
  getCustomSchemaSettings: ->
    @ColumnSchema?.custom_settings || {}


  #######################################################################
  # overwrite getCustomSchemaSettings
  name: (opts = {}) ->
    @ColumnSchema?.name || (opts.callfrompoolmanager && opts.name || "noNameSet")


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: -> $$("custom.data.type.wikidata.name")


  #######################################################################
  # get Languages
  getFrontendLanguage: ->
    ez5.loca.getLanguage()
  getDatabaseLanguagesLong: ->
    ez5.loca.getLanguageControl().getLanguages()
  getDatabaseLanguages: ->
    @getDatabaseLanguagesLong().map((lang) -> lang.split('-')[0])


   #######################################################################
  # returns markup to display in expert search
  #   use same uix as in plugin itself
  #######################################################################
  renderSearchInput: (data) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form

      form.DOM

  #######################################################################
  # make searchfilter for expert-search
  getSearchFilter: (data, key=@name()) ->

    that = @

    if data[@name()] == undefined || data[@name()] == {} || data[@name()] == null
      return

    # search for empty values
    if data[key+":unset"]
      filter =
        type: "in"
        fields: [ @fullName()+".conceptName" ]
        in: [ null ]
      filter._unnest = true
      filter._unset_filter = true
      return filter

    else if data[key+":has_value"]
      return @getHasValueFilter(data, key)

    # find all records which have the uri as conceptURI
    filter = null
    if data[@name()]?.conceptURI
        filter =
            type: "complex"
            search: [
                type: "in"
                mode: "token"
                bool: "must",
                phrase: false
                fields: [@path() + '.' + @name() + ".conceptURI" ]
                in: [data[@name()].conceptURI]
            ]

    filter


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, input_searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) =>

    if ! opts.detailed_data_xhr
      opts.detailed_data_xhr = { 'xhr' : undefined }

    # show loader
    suggest_Menu.setItemList(items: [
        text: $$('custom.data.type.wikidata.modal.form.loadingSuggestions')
        icon_left: new CUI.Icon(class: "fa-spinner fa-spin")
        disabled: true
    ])

    # Limiting search logic
    limit = @getCustomSchemaSettings() || ""
    filter = ""
    if limit.person?.value || limit.place?.value || limit.institution?.value || limit.custom?.value
      filter += " haswbstatement:"
      # Add filters based on conditions
      filters = []
      filters.push "P31=Q5" if limit.person?.value
      filters.push "P131" if limit.place?.value
      filters.push "P31=Q43229|P31=Q4671277|P31=Q31855" if limit.institution?.value # institution nicht einheitlich in Wikidata
      filters.push limit.custom.value if limit.custom?.value
      filter += filters.join "|"

    resultsN = cdata?.countOfSuggestions || 20 # default value 20

    delayMillisseconds = 50
    setTimeout ( =>

      suggest_Menu.show()

      # Logic: make first request getting just the selected urls,
      firstSearchUrl = 'https://www.wikidata.org/w/api.php?action=query&list=search&srsearch=' + input_searchstring + filter + "&origin=*&format=json&srlimit=" + resultsN

      # run autocomplete-search via xhr
      if searchsuggest_xhr?.opts
          # abort eventually running request
          searchsuggest_xhr.xhr.abort()

      searchsuggest_xhr = new CUI.XHR(url: firstSearchUrl)
      searchsuggest_xhr.start().done (suggestResult) =>

        # abort eventually running data request
        if opts.detailed_data_xhr?.opts
            opts.detailed_data_xhr.abort()

        selectedItems = suggestResult.query.search.map (item) => item.title

        # Keine Treffer gefunden..
        if selectedItems.length == 0          
          itemList = items: [
              text: $$('custom.data.type.wikidata.modal.form.popup.suggest.nohit')
              value: undefined
            ]
          suggest_Menu.setItemList(itemList).show()

        # Treffer gefunden..
        if selectedItems.length > 0
          # then make second search without filter, to get the full information
          searchUrl = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&props=labels|descriptions&origin=*&formatversion=2&ids=' + selectedItems.join("|")
          # Make request, after aborting any running request
          opts.detailed_data_xhr = new CUI.XHR url: searchUrl
          opts.detailed_data_xhr.start().done (response) =>
            menuItems = Object.values(response.entities).map (item) =>
              uiLang = @getFrontendLanguage()[0..1]
              dbLangsLong = @getDatabaseLanguagesLong()
              uri = "https://www.wikidata.org/entity/" + item.id
              label = item.labels[uiLang]?.value || ""
              # fallback if no label is found
              if label == ''
                if item.labels['de']?.value
                  label = item.labels['de'].value
                else if item.labels['en']?.value
                  label = item.labels['en'].value
                else 
                  label = item.labels[Object.keys(item.labels)[0]].value

              description = item.descriptions[uiLang]?.value || ""

              additionalData = WikidataUtil.getAdditionalTextFromObject(item, uiLang, dbLangsLong)

              # fill suggest_Menu, returning object
              {
                text: label ? "#{label}#{": " if description}#{description}" : description or ""
                value: label
                uri: uri
                id: item.id
                _fulltext: additionalData._fulltext
                _standard: additionalData._standard
                facetTerm: additionalData.facetTerm
                tooltip:
                  markdown: true
                  placement: "ne"
                  content: (tooltip) =>
                    @__getAdditionalTooltipInfo(uri, tooltip)
                    new CUI.Label(icon: "spinner", text: $$('custom.data.type.wikidata.modal.form.popup.loadingstring'))
              }

            # Construct the item LIst
            itemList =
              onClick: (ev2, btn) =>
                # hier sehr umständlich, desc von geklicktem Element extrahiert und damit in array gesucht
                item = menuItems.find (item) -> item.text == btn.getOpt("text")
                cdata.conceptURI = item.uri
                cdata.conceptName = item.text
                cdata.facetTerm = item.facetTerm
                cdata._fulltext = item._fulltext
                cdata._standard = item._standard
                cdata.frontendLanguage = @getFrontendLanguage()[0..1]
                @__updateResult(cdata, layout, opts)
              items: menuItems

            suggest_Menu.setItemList(itemList).show()

    ), delayMillisseconds


  #######################################################################
  # show tooltip with loader and then additional info (for extended mode)
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr={xhr: undefined}) =>
    uri = decodeURIComponent(uri)
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: "https://jsontojsonp.gbv.de/?url=" + encodeURIComponent(uri))
    extendedInfo_xhr.xhr.start().done (data) =>
      item = data?.entities?[uri.split('/').pop()] || ""
      result = {image: ""}
      for lang in @getDatabaseLanguagesLong()
        l = lang[0..1]
        result[lang] =
          aliases: (item.aliases?[l] || []).map (alias) -> alias.value
          label: item.labels[l]?.value
          description: item.descriptions[l]?.value
      result.uri = uri

      filename = item.claims?.P18?[0]?.mainsnak?.datavalue?.value || ""
      filename = filename.replace(/\s/g, "_")
      if filename
        # define md5 function in js
        `function MD5(r) {
          var o, e, n,
            f = [-680876936, -389564586, 606105819, -1044525330, -176418897, 1200080426, -1473231341, -45705983, 1770035416, -1958414417, -42063, -1990404162, 1804603682, -40341101, -1502002290, 1236535329, -165796510, -1069501632, 643717713, -373897302, -701558691, 38016083, -660478335, -405537848, 568446438, -1019803690, -187363961, 1163531501, -1444681467, -51403784, 1735328473, -1926607734, -378558, -2022574463, 1839030562, -35309556, -1530992060, 1272893353, -155497632, -1094730640, 681279174, -358537222, -722521979, 76029189, -640364487, -421815835, 530742520, -995338651, -198630844, 1126891415, -1416354905, -57434055, 1700485571, -1894986606, -1051523, -2054922799, 1873313359, -30611744, -1560198380, 1309151649, -145523070, -1120210379, 718787259, -343485551],
            t = [o = 1732584193, e = 4023233417, ~o, ~e], c = [], a = unescape(encodeURI(r)) + "\u0080", d = a.length;
          for (r = --d / 4 + 2 | 15, c[--r] = 8 * d; ~d;) c[d >> 2] |= a.charCodeAt(d) << 8 * d--;
          for (i = a = 0; i < r; i += 16) {
            for (d = t; 64 > a; d = [n = d[3], o + ((n = d[0] + [o & e | ~o & n, n & o | ~n & e, o ^ e ^ n, e ^ (o | ~n)][d = a >> 4] + f[a] + ~~c[i | 15 & [a, 5 * a + 1, 3 * a + 5, 7 * a][d]]) << (d = [7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21][4 * d + a++ % 4]) | n >>> -d), o, e]) o = 0 | d[1],
              e = d[2];
            for (a = 4; a;) t[--a] += d[a];
          }
          for (r = ""; 32 > a;) r += (t[a >> 3] >> 4 * (1 ^ a++) & 15).toString(16);
          return r;
        }`
        # Generate MD5 hash of the filename
        hash = MD5(filename)
        result["image"] = "https://upload.wikimedia.org/wikipedia/commons/" + hash[0] + "/" + hash[0..1] + "/" + filename

      if result
        tooltip.DOM.innerHTML = WikidataUtil.getPreview(result)
      else
        tooltip.DOM.innerHTML = '<div class="wikidataTooltip" style="padding: 10px">' + $$('custom.data.type.wikidata.modal.form.popup.no_information_found') + '</div>'
      tooltip.autoSize()
    return


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->

    custom_settings = @getCustomSchemaSettings()
    # Dynamically build the dropDownSearchOptions by iterating over custom_settings
    dropDownSearchOptions = []

    for key, setting of custom_settings
      if key is 'custom' # limiting on custom not possible
        continue
      if setting?.value
        # Capitalize the key and add it as the text
        dropDownSearchOptions.push({ value: key, text: key.charAt(0).toUpperCase() + key.slice(1) })

    formFields = [
      {
        type: CUI.Select
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.wikidata.modal.form.text.type')
        options: dropDownSearchOptions
        name: 'wikidataSelectType'
        class: 'commonPlugin_Select'
      }
      {
        type: CUI.Select
        undo_and_changed_support: false
        class: 'commonPlugin_Select'
        form:
            label: $$('custom.data.type.wikidata.modal.form.text.count')
        options: ( {value: v, text: "#{v} Vorschläge"} for v in [10, 20, 50] )
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Input
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.wikidata.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.wikidata.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
        class: 'commonPlugin_Input'
      }
    ]
    # Remove the first field (wikidataSelectType) if dropDownSearchOptions is empty
    formFields.shift() if dropDownSearchOptions.length == 0
    formFields

  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
      activeOptions = []
      activeOptions.push "🙂" if custom_settings.person?.value
      activeOptions.push "🗺️" if custom_settings.place?.value
      activeOptions.push "🏦" if custom_settings.institution?.value
      activeOptions.push custom_settings.custom?.value if custom_settings.custom?.value
      if activeOptions.length > 0
       ["limit: #{activeOptions.join(', ')}"]
      else
       ['Ohne Optionen']

  #######################################################################
  # renders the "resultmask" (outside popover)
  __renderButtonByData: (cdata) =>
    uri = cdata?.conceptURI?.trim() or ''
    name = cdata?.conceptName?.trim() or ''
    if !uri && !name
      new CUI.EmptyLabel(text: $$("custom.data.type.wikidata.edit.no_entry")).DOM
    else if !uri || !name
      new CUI.EmptyLabel(text: $$("custom.data.type.wikidata.edit.no_valid_entry")).DOM

    # output Button with Name of picked entry and URI
    new CUI.HorizontalLayout
      maximize: false
      left:
        content:
          new CUI.Label
            centered: false
            text: name
      center:
        content:
          new CUI.ButtonHref
            appearance: "link"
            href: uri
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) =>
                @__getAdditionalTooltipInfo(uri, tooltip)
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.wikidata.modal.form.popup.loadingstring'))
      right: null
    .DOM

CustomDataType.register(CustomDataTypeWikidata)
