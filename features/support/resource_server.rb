require 'sinatra/base'

class ResourceServer < Sinatra::Base
  get '/features/:feature' do
    send_file options.root + "/features/#{params[:feature]}"
  end
end
