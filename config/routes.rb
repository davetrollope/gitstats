Rails.application.routes.draw do
  get 'welcome/index'
  get 'pull_request/open'
  get 'pull_request/closed'
  put 'pull_request/set_filters'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'welcome#index'
end
