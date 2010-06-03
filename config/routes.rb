ActionController::Routing::Routes.draw do |map|
  map.accept_invitation '/accept/invitation/:contest/contest/:contest_instance/:invite_code', :controller => 'participants', :action => 'create'
  map.resource :account, :controller => "users"
  map.resources :users
#  map.signin "login", :controller => "user_sessions", :action => "new"
  map.signout "signout", :controller => "user_sessions", :action => "destroy"
  map.addrpxauth "addrpxauth", :controller => "users", :action => "addrpxauth", :method => :post
  map.sign_in_options 'account/edit/sign-in-options', :controller => "users", :action => "sign_in_options", :method => :get
  map.resources :user_sessions
#  map.resource :user_session
  map.resources :password_resets
  map.resources :predictions,
    :path_prefix => '/:contest/:aggregate_root_type/:aggregate_root_id'
  map.championship_predictions "championship/group/A",
    :controller => "predictions", :action => "new",
    :contest => "championship", :aggregate_root_type => "group", :aggregate_root_id => "A"
  map.resources :contests, :path_prefix => '/:contest/:role' do |contests|
    contests.resources :invitations
    contests.resources :participants
    contests.resource :score_table
  end
  map.resources :invitations, :path_prefix => '/:contest',
    :collection => {:pending => :get, :accepted => :get}
  map.home ':action', :controller => 'home', :action => /about|rules|terms|privacy|contact/
  map.root :controller => "user_sessions", :action => "new"
  map.catch_all '*url', :controller => "rescue"
end
