module Lopata
  module DownloadDir
    RELATIVE_PATH = File.join('.', 'tmp', 'target')

    extend self

    def path
      @path ||= File.absolute_path(RELATIVE_PATH)
    end

    def empty!
      FileUtils.rm Dir.glob(File.join(path, '*'))
    end

    def ensure_exist
      FileUtils::mkdir_p path unless Dir.exist?(path)
    end

    def has_file?(file_name)
      require 'timeout'
      target_file = filepath(file_name)
      Timeout.timeout(10) do
        sleep 0.1 until File.exist?(target_file)
        true
      end
    rescue Timeout::Error
      false
    end

    def filepath(name)
      File.join(path, name)
    end

    def init_capybara
      target_path = path
      target_path = target_path.gsub('/', '\\') if Gem.win_platform?

      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.folderList'] = 2
      profile['browser.download.manager.showWhenStarting'] = false
      ensure_exist
      profile['browser.download.dir'] = target_path
      profile['browser.download.downloadDir'] = target_path
      profile['browser.download.defaultFolder'] = target_path
      profile['browser.helperApps.alwaysAsk.force'] = false
      profile['browser.download.useDownloadDir'] = true
      profile['browser.helperApps.neverAsk.saveToDisk'] =
        %w{
            application/octet-stream
            application/msword
            application/pdf
            application/x-pdf
            application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
            application/vnd.ms-excel
            application/xml
          }.join(', ')
      profile['pdfjs.disabled'] = true
      profile['plugin.scan.Acrobat'] = "99.0"
      profile['plugin.scan.plid.all'] = false

      Capybara.register_driver :selenium_with_download do |app|
        Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
      end

      Capybara.default_driver = :selenium_with_download
      # Capybara.default_max_wait_time = 10
    end
  end
end