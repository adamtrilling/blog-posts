Rails.application.routes.draw do
  resources :items do
    get :mark_completed, on: :member
  end
end
