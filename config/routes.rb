ActionController::Routing::Routes.draw do |map|
  map.resource :account, :controller => "users"
  map.resources :users
  map.resource :user_session
  map.resources :predictions, :controller => "predictable/championship/predictions", 
    :path_prefix => '/championship/:collection_type/:collection_id'
  map.championship_predictions "championship_predictions",
    :controller => "predictable/championship/predictions", :action => "new",
    :collection_type => "group", :collection_id => "A"
  map.root :controller => "user_sessions", :action => "new"
end
