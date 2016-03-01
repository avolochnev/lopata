module Lopata
  module DownloadDir
    RELATIVE_PATH = './tmp/target'

    extend self

    def path
      @path ||= File.absolute_path(RELATIVE_PATH).gsub("/", '\\')
    end

    def empty!
      FileUtils.rm Dir.glob("#{RELATIVE_PATH}/*")
    end

    def ensure_exist
      FileUtils::mkdir_p RELATIVE_PATH unless Dir.exist?(RELATIVE_PATH)
    end

    def has_file?(file_name)
      require 'timeout'
      target_file = File.join(RELATIVE_PATH, file_name)
      Timeout.timeout(10) do
        sleep 0.1 until File.exist?(target_file)
        true
      end
    rescue Timeout::Error
      false
    end

    def init_capybara
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.folderList'] = 2
      profile['browser.download.manager.showWhenStarting'] = false
      ensure_exist
      profile['browser.download.dir'] = path
      profile['browser.download.downloadDir'] = path
      profile['browser.download.defaultFolder'] = path
      profile['browser.helperApps.alwaysAsk.force'] = false
      profile['browser.download.useDownloadDir'] = true
      profile['browser.helperApps.neverAsk.saveToDisk'] =
         "application/octet-stream, application/msword, application/pdf, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

      Capybara.register_driver :selenium_with_download do |app|
        Capybara::Selenium::Driver.new(
           app,
           {:browser => :firefox, :profile => profile}
        )
      end

      Capybara.default_driver = :selenium_with_download
      # Capybara.default_max_wait_time = 10
    end
  end
end