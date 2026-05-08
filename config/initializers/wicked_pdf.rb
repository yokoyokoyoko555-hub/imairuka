# frozen_string_literal: true

WickedPdf.configure do |config|
  wkhtmltopdf_candidates = [
    ENV["WKHTMLTOPDF_PATH"],
    "/app/.apt/usr/bin/wkhtmltopdf",
    "/app/bin/wkhtmltopdf",
    "/usr/local/bin/wkhtmltopdf",
    "/opt/homebrew/bin/wkhtmltopdf",
    "/usr/bin/wkhtmltopdf"
  ].compact

  config.exe_path = wkhtmltopdf_candidates.find { |path| File.exist?(path) }

  config.page_size = "A4"
  config.orientation = "portrait"
  config.margin = {
    top: 15,
    bottom: 15,
    left: 10,
    right: 10
  }

  config.default_font = "Noto Sans JP"
  config.disable_smart_shrinking = true
  config.print_media_type = true
  config.no_pdf_compression = false
  config.enable_local_file_access = true

  config.wkhtmltopdf = [
    "--default-font", "Noto Sans JP",
    "--encoding", "UTF-8",
    "--no-stop-slow-scripts",
    "--javascript-delay", "1000",
    "--load-error-handling", "ignore",
    "--load-media-error-handling", "ignore"
  ]
end
