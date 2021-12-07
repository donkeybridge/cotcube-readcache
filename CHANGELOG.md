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

