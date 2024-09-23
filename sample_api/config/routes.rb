Rails.application.routes.draw do

  get 'health_check/healthcheck'
  namespace :api do
    namespace :v1 do
      resources :bands do
        resources :members
      end
    end

    namespace :v2 do
      resources :members
      resources :bands
    end
  end
end
