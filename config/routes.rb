Rails.application.routes.draw do

  root 'welcome#index'

  # static pages
  get 'faq' => 'static_pages#faq'
  get 'examples' => 'static_pages#examples'
  get 'how_it_works' => 'static_pages#how_it_works'

  # front page
  get 'welcome' => 'welcome#index'
  get 'welcome/run' => 'welcome#run'
  get 'welcome/clear' => 'welcome#clear'

  # sign up
  get 'signup' => 'users#new'
  resources :users

  # jobs
  resources :jobs
  post 'jobs/new_sequence_file' => 'sequence_files#create_for_jobform'
  post 'jobs/new_transcript_file' => 'transcript_files#create_for_jobform'
  get 'job/:id' => 'jobs#show'
  get 'jobs/:id' => 'jobs#show'
  get 'jobs/:id/orths' => 'jobs#orths'
  get 'jobs/:id/orths/cluster/:cluster' => 'jobs#orths_for_cluster', :constraints => { :cluster => /.*/ }
  get 'jobs/:id/clusters' => 'jobs#get_clusters', as: :clusters
  get 'jobs/:id/singletons' => 'jobs#get_singletons', as: :singletons
  get 'jobs/:id/tree.nwk' => 'jobs#get_tree', as: :tree
  get 'jobs/:id/tree/genes' => 'jobs#get_tree_genes', as: :tree_genes

  # uploaded files
  get 'user_files/index'
  get 'user_files/new'
  get 'user_files/create'
  get 'user_files/destroy'
  resources :user_files

  # session management
  get    'login'   => 'sessions#new'
  post   'login'   => 'sessions#create'
  delete 'logout'  => 'sessions#destroy'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
