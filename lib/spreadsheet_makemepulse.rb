require "spreadsheet_makemepulse/version"

module SpreadsheetMakemepulse
  class Spreadsheet

    def self.load 
      require 'open-uri'
      require 'rubyXL'
      require 'json'

      config_file = Rails.root.join('config', "translations.yml")
      settings    = YAML.load_file(config_file) if File.exists?(config_file)

      files = settings['files']
      files.each do |target_file, url|

          target_file = target_file + ".yml" if target_file !~ /\.yml$/
          tmp_file = Rails.root.join('tmp', File.basename(target_file).gsub('.yml', '.xlsx'))
          FileUtils.mkdir_p(Rails.root.join('tmp')) unless File.exist?(Rails.root.join('tmp')) 


          puts "Download '#{url}' to '#{tmp_file}'"

          open(url) do |data|
              doc_data = data.read.force_encoding('UTF-8')
              File.open(tmp_file, 'w+') do |dst|
                  dst.write(doc_data)
              end
          end

          # doc_data = open(url).read.force_encoding('UTF-8')

          workbook = RubyXL::Parser.parse(tmp_file)

          tabs     = {}
          locales  = []

          for sheet in workbook.worksheets
              sheet_name = sheet.sheet_name.downcase
              locales  = []

              sheet.each_with_index { |row, rowIndex|

                  category = nil
                  key      = nil

                  row.cells.each_with_index { |cell,cellIndex|
                      #puts cell
                      next if !cell || cell.value.nil?
                      val = cell.value

                      if rowIndex == 0 && cellIndex > 2
                          val = val.downcase
                          tabs[val] = {} if tabs[val].nil?
                          tabs[val][sheet_name] = {}
                          locales.push(val)
                      end

                      if cellIndex == 0
                          category = val
                      end

                      if cellIndex == 1
                          if !val
                              next
                          end
                          key = val
                      end


                      if rowIndex != 0 && cellIndex > 2

                          loc = locales[cellIndex-3]
                          tabs[loc][sheet_name][category] = {} if tabs[loc][sheet_name][category].nil?
                          tabs[loc][sheet_name][category][key] = {} if tabs[loc][sheet_name][category][key].nil?
                          tabs[loc][sheet_name][category][key] = ( val.nil?  ? "" : val)
                      end
                  }
              }

          end

          for locale in locales

              output_file_path = Rails.root.join('config', 'locales', locale, "global.yml")
              FileUtils.mkdir_p File.dirname(output_file_path)

              File.open(output_file_path, 'w') do |file|
                  final_translation_hash = {locale => tabs[locale]}
                  file.puts YAML::dump(final_translation_hash)
              end
              puts "File for language '#{locale}' written to disc (#{output_file_path})"

              #JSON
              #output_file_path_json = Rails.root.join('public', 'locales', locale, "global.json")
              #FileUtils.mkdir_p File.dirname(output_file_path_json)

              #File.open(output_file_path_json, 'w') do |file|
              #    final_translation_hash = {locale => tabs[locale]}
              #    file.puts final_translation_hash.to_json
              #end
              #puts "File for language '#{locale}' written to disc (#{output_file_path})"



          end
      end


      I18n.backend.reload!

      output_restart_file_path = Rails.root.join('tmp', "restart.txt")

      %x(touch #{output_restart_file_path})
    end
  end
end


if defined?(Rails)
  class SpreadsheetMakemepulse::Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
    end
  end
end
