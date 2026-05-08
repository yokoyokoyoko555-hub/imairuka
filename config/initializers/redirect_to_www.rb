class RedirectToWww
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    if request.host == 'imairuka.com'
      [301, { 'Location' => "https://www.imairuka.com#{request.fullpath}", 'Content-Type' => 'text/html' }, []]
    else
      @app.call(env)
    end
  end
end

Rails.application.config.middleware.use RedirectToWww if Rails.env.production? 