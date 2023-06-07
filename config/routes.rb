require 'sidekiq/web'

Rails.application.routes.draw do

  root 'welcome#index'

  # static pages
  get 'faq' => 'static_pages#faq'
  get 'survey2018' => 'static_pages#survey2018'
  get 'examples' => 'static_pages#examples'
  get 'getting_started' => 'static_pages#how_it_works'

  # front page
  get 'welcome' => 'welcome#index'
  get 'welcome/run' => 'welcome#run'
  get 'welcome/clear' => 'welcome#clear'

  # jobs
  resources :jobs
  post 'jobs/new_sequence_file' => 'sequence_files#create_for_jobform'
  post 'jobs/new_transcript_file' => 'transcript_files#create_for_jobform'
  get 'find' => 'jobs#show', as: :job_find
  get 'job/:id' => 'jobs#show'
  get 'jobs/:id' => 'jobs#show'
  get 'jobs/:id/orths' => 'jobs#orths'
  get 'jobs/:id/orths/cluster/:cluster' => 'jobs#orths_for_cluster', :constraints => { :cluster => /.*/ }
  get 'jobs/:id/clusters' => 'jobs#get_clusters', as: :clusters
  get 'jobs/:id/singletons' => 'jobs#get_singletons', as: :singletons
  get 'jobs/:id/tree.nwk' => 'jobs#get_tree', as: :tree
  get 'jobs/:id/report.html' => 'jobs#get_report', as: :report
  get 'jobs/:id/tree/genes' => 'jobs#get_tree_genes', as: :tree_genes
  get 'jobs/:id/plots.zip' => 'jobs#get_all_synteny_images', as: :all_synteny_images
  get 'jobs/:id/all_results.zip' => 'jobs#get_all_result_files', as: :all_result_files

  # references
  get 'references' => 'references#index'

  resources :jobs do
    get :restart, on: :member 
  end

  # uploaded files
  get 'user_files/new'
  get 'user_files/create'
  resources :user_files

  # session management
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  delete 'logout'  => 'sessions#destroy'

  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end

end
