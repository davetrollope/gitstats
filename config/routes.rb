Rails.application.routes.draw do
  get 'welcome/index'
  get 'pull_request/open'
  put 'pull_request/open/set_columns', to: 'pull_request#set_open_columns'
  get 'pull_request/closed'
  put 'pull_request/set_filters'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'welcome#index'
end
