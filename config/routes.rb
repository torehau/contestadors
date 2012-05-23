Contestadors::Application.routes.draw do
  match '/accept/invitation/:contest/contest/:contest_instance/:invite_code' => 'participants#create', :as => :accept_invitation
  resource :account, :controller => "users"
  resources :users
  match 'signout' => 'user_sessions#destroy', :as => :signout
  match 'addrpxauth' => 'users#addrpxauth', :as => :addrpxauth, :method => :post
  match 'account/edit/sign-in-options' => 'users#sign_in_options', :as => :sign_in_options, :method => :get
  resources :user_sessions
  resources :password_resets
  resources :tournaments do
    collection do
      get :completed
      get :upcoming
    end
    post 'select', :on => :member
  end
  scope '/:contest/:aggregate_root_type/:aggregate_root_id' do
    resources :predictions do
      put '/' => :create, :on => :collection
      collection do
        post :rearrange
      end
    end
  end
  match 'euro/group/A' => 'predictions#new', :as => :championship_predictions, :contest => 'euro', :aggregate_root_type => 'group', :aggregate_root_id => 'A'
  match '/your/:contest/:aggregate_root_type/:aggregate_root_id/predictions' => 'predictions#show', :as => :user_predictions, :method => :get
  scope '/:contest/:role' do
    resources :contests do
      resources :invitations do
        collection do
          scope '/:uuid' do
            get :copy
          end
        end
      end
      resources :participants
      resource :score_table
    end
  end

  match '/:contest/:role/contests/:id/upcoming' => 'contests#upcoming_events', :as => :upcoming_events
  match '/:contest/:role/contests/:id/latest' => 'contests#latest_results', :as => :latest_results
  scope '/:contest' do
    resources :rules do
      collection do
        get :predictions
        get :prediction_contests
        get :score_calculations
      end
    end
    resources :invitations do
      collection do
        get :pending
        get :accepted
      end
    end
  end

  match '/:contest/:role/:contest_id/participant-predictions' => 'participants#show', :as => :participant_predictions
  match ':action' => 'home#(?-mix:about|terms|privacy|contact|faq)', :as => :home
  root :to => 'user_sessions#new'
  match '*url' => 'rescue#index', :as => :catch_all
end


#ActionController::Routing::Routes.draw do |map|
#  map.accept_invitation '/accept/invitation/:contest/contest/:contest_instance/:invite_code', :controller => 'participants', :action => 'create'
#  map.resource :account, :controller => "users"
#  map.resources :users
##  map.signin "login", :controller => "user_sessions", :action => "new"
#  map.signout "signout", :controller => "user_sessions", :action => "destroy"
#  map.addrpxauth "addrpxauth", :controller => "users", :action => "addrpxauth", :method => :post
#  map.sign_in_options 'account/edit/sign-in-options', :controller => "users", :action => "sign_in_options", :method => :get
#  map.resources :user_sessions
##  map.resource :user_session
#  map.resources :password_resets
#  map.resources :predictions,
#    :path_prefix => '/:contest/:aggregate_root_type/:aggregate_root_id'
#  map.championship_predictions "championship/group/A",
#    :controller => "predictions", :action => "new",
#    :contest => "championship", :aggregate_root_type => "group", :aggregate_root_id => "A"
#  map.user_predictions '/your/:contest/:aggregate_root_type/:aggregate_root_id/predictions', :controller => "predictions", :action => "show", :method => :get
#  map.resources :contests, :path_prefix => '/:contest/:role' do |contests|
#    contests.resources :invitations
#    contests.resources :participants
#    contests.resource :score_table
#  end
#  map.upcoming_events '/:contest/:role/contests/:id/upcoming', :controller => "contests", :action => "upcoming_events"
#  map.latest_results '/:contest/:role/contests/:id/latest', :controller => "contests", :action => "latest_results"
#  map.resources :invitations, :path_prefix => '/:contest',
#    :collection => {:pending => :get, :accepted => :get}
#  map.participant_predictions '/:contest/:role/:contest_id/participant-predictions', :controller => "participants", :action => "show"
#  map.home ':action', :controller => 'home', :action => /about|rules|terms|privacy|contact|faq/
#  map.root :controller => "user_sessions", :action => "new"
#  map.catch_all '*url', :controller => "rescue"
#end
