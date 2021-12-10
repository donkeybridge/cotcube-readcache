## 0.1.2 (December 10, 2021)
  - genericRoutes: Adding timestamp to logged output
  - models/<ENTITIES>: the reworked models are much smaller now :)
  - _models: the inheritance based design requires order while loading all models
  - models/readcache: adopting basis_entity design, most significantly changing :selector to :asset
  - basic_entity: Created new parent model for inheriting entities (changing the basic design), also changing the structure to Cotcube::ReadCache::Entities::<ENTITY>
  - adding new model: continuous
  - adding forced update option via url parameter
  - models/intra: fixed unknown duration '6_H' to 6.hours (as to_json translates it to seconds, and IBKR understand seconds to up to 1.day)
  - models readcache: added next_end_of(..., ...) and according legacy support
  - models/istencil: applied private attr_reader
  - models/intra: fixed problem that subtr. 2 datetimes results in rational
  - models/stencil: applied private attr_readers
  - added models/eods, providing a list of eods with either volume_part > 10% or oi_part > 10%
  - models/daily: modified default indicators
  - models/_template: updated to use private attr_reader
  - minor changes in models/daily and models/istencil
  - lib/models/intra: added based on tmpl
  - bin/passenger-app: added source ref (marvwhere)

## 0.1.1 (December 07, 2021)
  - models/readcache: added init-lambda for daily
  - model/daily: added deliver of daily bars
  - model/stencil: added delivery of eod_stencil
  - models/istencil: added delivery of intraday_stencil
  - models/symbols: applied template to symbols, delivering symbols and micros in a bunch
  - bin/cccache: convenience helper to test API via cmdline
  - models/keys: extending payload with currently supported classes
  - re-arranging bundling after rvm upgrade to mri 2.7.5
  - passenger-app: changing rvm path to 'default'
  - readcache: renaming created_at to modified_at
  - some modifications regarding Bundler
  - created basic readcache idea, including a template for models, basic model validation, and a keys model, that return the currently available keys of the cache
  - adding gemspec and according Gemfile

## 0.1.0 (December 06, 2021)
  - app.rb and the very basic genericRoutes.rb controller
  - adding basic passenger infrastructure

