> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# fylr-custom-data-type-wikidata

This is a plugin for [fylr](https://docs.fylr.io/) with Custom Data Type `CustomDataTypeWikidata` for references to records of the [Wikidata (https://www.wikidata.org)](https://www.wikidata.org).

The Plugins uses the mechanisms from <https://www.wikidata.org/wiki/Wikidata:Data_access/en> for the communication with Wikidata.

Note: For technical reasons, the API requests run via a proxy at the central office of the joint library network ("Verbundzentrale des Gemeinsamen Bibliotheksverbundes").

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-wikidata/releases/latest/download/customDataTypeWikidata.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-wikidata/releases/).

## requirements
This plugin requires https://github.com/programmfabrik/fylr-plugin-commons-library. In order to use this Plugin, you need to add the [commons-library-plugin](https://github.com/programmfabrik/fylr-plugin-commons-library) to your pluginmanager.

## configuration

As defined in `manifest.master.yml` this datatype can be configured:

### Schema options
* institution
    * search institutions?
* person
    * search persons?
* place
    * search places?
* custom
    * search custom class?

### Mask options
* editordisplay: default or condensed (oneline)

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptFulltext
    * fulltext-string which contains: PrefLabels, AltLabels, HiddenLabels, Notations
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard
* facetTerm
    * custom facets, which support multilingual facetting
* frontendLanguage

## updater

Note: The automatic updater can be configured. Make sure to also activate the corresponding fylr service.


## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-wikidata>.