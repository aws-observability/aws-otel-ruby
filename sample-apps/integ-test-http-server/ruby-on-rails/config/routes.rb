Rails.application.routes.draw do
  root 'application#root'

  get '/test', to: 'application#test'
end
