Rails.application.routes.draw do

  root "viewer#index"

  namespace :api do
    get "auth/token", to: "auth#token"

    resources :models, only: [:index, :create] do
      member do
        get :status
      end
    end
  end

end
