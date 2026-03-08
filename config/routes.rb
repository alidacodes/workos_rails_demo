Rails.application.routes.draw do
  root "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # authentication
  get "login", to: "sessions#create", as: :login
  get "auth/callback", to: "sessions#callback"
  get "logout", to: "sessions#destroy", as: :logout

  # directories
  resources :directories, only: [:index, :show], param: :id 
end
