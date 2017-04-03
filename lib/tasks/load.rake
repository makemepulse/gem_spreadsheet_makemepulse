require 'rake'

namespace :spreadsheet do

  desc "Download translations from Google Spreadsheet and save them to YAML files."
  task load: :environment do
    raise "'Rails' not found! Tasks can only run within a Rails application!" if !defined?(Rails)

    SpreadsheetMakemepulse::Spreadsheet.load()

  end
end