require 'bundler/setup'
require 'omniauth'
require 'sinatra'
require 'bootic_client'

class MiAplicacion < Sinatra::Base

  def initialize
    BooticClient.configure do |c|
      c.client_id     = ENV['BOOTIC_KEY']
      c.client_secret = ENV['BOOTIC_SECRET']
      c.logger        = Logger.new(STDOUT)
      # c.cache_store = Rails.cache
    end

    super
  end

  set :views, './views'
  set :sessions, true
  use OmniAuth::Builder do
    provider(:bootic, ENV['BOOTIC_KEY'], ENV['BOOTIC_SECRET'], { scope: 'public,admin' })
  end

  helpers do
    def current_shop
      @current_shop ||= root.shops.first
    end

    def current_user
      @current_user ||= User.new(session[:auth_info])
    end

    def account_root
      @account_root ||= client.from_hash(ACCOUNT_API)
    end

    def addons
      @addons ||= account_root.addons(account_id: current_shop.account_id)
    end

    def root
      @root ||= client.root
    end

    def client
      @client ||= BooticClient.client(:authorized, access_token: session[:access_token]) do |new_token|
        session[:access_token] = new_token
      end
    end

    def logged_in?
      !!session[:access_token]
    end
  end

  error do
    err = request.env['sinatra.error']
    logger.error err.message
    logger.error err.backtrace.first(3).join("\n")
    halt(500, err.message)
  end

  get '/auth/:provider/callback' do
    auth   = request.env['omniauth.auth']
    params = request.env['omniauth.params']

    # provider, uid = auth['provider'], auth['uid']
    # session[:user_id] = uid

    session[:auth_info]    = { name: auth['info']['name'], email: auth['info']['email'] }
    session[:access_token] = auth['credentials']['token'] or raise "No credentials/token!"

    url = session.delete(:return_to) || '/'
    redirect to(url)
  end

  get '/auth/failure' do
    redirect to('/login?message=failed')
  end

  helpers do

  end

  get '/' do
    erb :welcome
  end

  get '/admin' do
    if logged_in?
      erb :index
    else
      redirect to('/')
    end
  end

end