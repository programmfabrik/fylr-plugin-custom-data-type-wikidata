ZIP_NAME ?= "customDataTypeWikidata.zip"
PLUGIN_NAME = "custom-data-type-wikidata"

# coffescript-files to compile
COFFEE_FILES = CustomDataTypeWikidata.coffee \
	CustomDataTypeWikidataFacet.coffee \
	wikidataUtilities.coffee

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build ## build all

build: clean buildinfojson ## clean, compile, copy files to build folder
                 ## install needed node-module
				npm install --save node-fetch

				mkdir -p build
				mkdir -p build/$(PLUGIN_NAME)
				mkdir -p build/$(PLUGIN_NAME)/webfrontend
				mkdir -p build/$(PLUGIN_NAME)/updater
				mkdir -p build/$(PLUGIN_NAME)/l10n

				cp build-info.json build/$(PLUGIN_NAME)/build-info.json # build-info

				mkdir -p src/tmp # build code from coffee

				cp src/webfrontend/*.coffee src/tmp
				cd src/tmp && coffee -b --compile ${COFFEE_FILES} # bare-parameter is obligatory!

				cat src/tmp/CustomDataTypeWikidata.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeWikidata.js
				cat src/tmp/CustomDataTypeWikidataFacet.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeWikidata.js
				cat src/tmp/wikidataUtilities.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeWikidata.js

				cp src/updater/wikidataUpdater.js build/$(PLUGIN_NAME)/updater/wikidataUpdater.js # build updater
				cat src/tmp/wikidataUtilities.js >> build/$(PLUGIN_NAME)/updater/wikidataUpdater.js
				cp package.json build/$(PLUGIN_NAME)/package.json
				cp -r node_modules build/$(PLUGIN_NAME)/
				rm -rf src/tmp # clean tmp

				cp l10n/customDataTypeWikidata.csv build/$(PLUGIN_NAME)/l10n/customDataTypeWikidata.csv # copy l10n

				cp src/webfrontend/css/main.css build/$(PLUGIN_NAME)/webfrontend/customDataTypeWikidata.css # copy css
				cp manifest.master.yml build/$(PLUGIN_NAME)/manifest.yml # copy manifest

clean: ## clean
				rm -rf build

zip: build ## build zip file
			cd build && zip ${ZIP_NAME} -r $(PLUGIN_NAME)/

buildinfojson:
	repo=`git remote get-url origin | sed -e 's/\.git$$//' -e 's#.*[/\\]##'` ;\
	rev=`git show --no-patch --format=%H` ;\
	lastchanged=`git show --no-patch --format=%ad --date=format:%Y-%m-%dT%T%z` ;\
	builddate=`date +"%Y-%m-%dT%T%z"` ;\
	echo '{' > build-info.json ;\
	echo '  "repository": "'$$repo'",' >> build-info.json ;\
	echo '  "rev": "'$$rev'",' >> build-info.json ;\
	echo '  "lastchanged": "'$$lastchanged'",' >> build-info.json ;\
	echo '  "builddate": "'$$builddate'"' >> build-info.json ;\
	echo '}' >> build-info.json
