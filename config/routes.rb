Rails.application.routes.draw do
  devise_for :users,
    path: "auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions: "auth/sessions",
      registrations: "auth/registrations",
      omniauth_callbacks: "auth/omniauth_callbacks"
    }

  namespace :api do
    namespace :v1 do
      resources :spaces do
        resources :memberships, only: [:create, :destroy],
          controller: "space_memberships"
        resources :boxes, only: [:index, :create]
        resources :tags, only: [:index, :create]
      end

      resources :boxes, only: [:show, :update, :destroy] do
        resources :items, only: [:index, :create]
        collection do
          get "scan/:qr_token", to: "boxes#scan", as: :scan
        end
      end

      resources :items, only: [:show, :update, :destroy]
      resources :tags,  only: [:update, :destroy]

      get "search", to: "search#index"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
