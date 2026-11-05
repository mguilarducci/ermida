Rails.application.routes.draw do
  if Rails.env.development?
    mount Rails::Hyperdrive::Engine => "/_hyperdrive"
    # Development tools. Mission Control and PgHero stay out of production until the app has an admin login.
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount PgHero::Engine, at: "/pghero"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Lookbook::Engine, at: "/lookbook"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :businesses
  resource :session, only: %i[new destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up", to: "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
