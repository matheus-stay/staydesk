# frozen_string_literal: true

# Rotas da camada StayDesk. O Rails carrega este arquivo junto com config/routes.rb
# porque config/application.rb o adiciona em config.paths['config/routes.rb'].
# Toda rota nossa fica sob /api/v1/accounts/:account_id/staydesk/.
Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          namespace :staydesk do
            resource :ping, only: [:show], controller: 'ping'
            resource :workspace, only: [:show], controller: 'workspace'
            resources :agent_roles, only: [:index, :update], param: :user_id
            resources :roles, only: [:index, :create, :update, :destroy]
            resources :impersonations, only: [:index, :create]
            resources :offers, only: [:index] do
              member do
                post :accept
                post :decline
              end
            end
            resources :queues, only: [:index, :create, :update, :destroy] do
              collection do
                put :reorder
              end
            end
            resources :events, only: [:index]
            resources :calendars, only: [:index, :show, :create, :update, :destroy]
            resources :sla_policies, only: [:index, :show, :create, :update, :destroy] do
              collection do
                put :reorder
              end
            end
            resources :applied_slas, only: [:index]
            resources :agent_statuses, only: [:index, :create, :update, :destroy]
            resources :agent_status_periods, only: [:index, :create]
            resources :agent_loads, only: [:index]
            resources :distribution_checks, only: [:index]
            resources :load_queues, only: [:index, :create, :update, :destroy]
            resources :capacity_rules, only: [:index, :create, :update, :destroy]
            resource :config_import, only: [:create], controller: 'config_imports'
            resources :kpis, only: [:index]
            resources :api_tokens, only: [:index, :create, :update, :destroy]
            resources :ticket_fields, only: [:index]
            resource :api_reference, only: [:show], controller: 'api_reference'
            resources :offer_stats, only: [:index]
            resources :ticket_statuses, only: [:index, :create, :update, :destroy] do
              collection do
                put :reorder
              end
            end
            resources :conversations, only: [] do
              resource :ticket_fields, only: [:show, :update], controller: 'ticket_fields'
              resource :sla, only: [:show], controller: 'conversation_slas'
              resource :ticket_status, only: [:create], controller: 'conversation_ticket_statuses'
            end
            resources :team_workspaces, only: [:index, :show, :update], param: :team_id do
              collection do
                get :schema
              end
            end
            resources :team_views, only: [:index, :show, :create, :update, :destroy] do
              collection do
                get :counts
              end
              member do
                get :conversations
              end
            end
          end
        end
      end
    end
  end

  # Fachada com os caminhos e formatos da API do Zendesk que o dashboard consome
  # (SPEC-17): a URL base é /staydesk/zendesk e o resto é igual ao Zendesk.
  scope '/staydesk/zendesk/api/v2', module: 'staydesk/zendesk', as: 'staydesk_zendesk', defaults: { format: 'json' } do
    get 'incremental/tickets/cursor', to: 'tickets#incremental'
    get 'incremental/ticket_metric_events', to: 'metric_events#incremental'
    get 'satisfaction_ratings', to: 'satisfaction_ratings#index'
    get 'users/search', to: 'users#search'
    get 'users/:id/tickets/requested', to: 'tickets#requested'
    get 'users', to: 'users#index'
    get 'groups', to: 'groups#index'
    get 'ticket_fields/:id', to: 'ticket_fields#show'
    get 'ticket_fields', to: 'ticket_fields#index'
    get 'agent_availabilities/agent_statuses', to: 'agent_availabilities#statuses'
    get 'agent_availabilities', to: 'agent_availabilities#index'
    get 'tickets/:id/comments', to: 'tickets#comments'
    put 'tickets/:id/tags', to: 'tickets#set_tags'
    post 'tickets/:id/tags', to: 'tickets#add_tags'
    get 'tickets/:id', to: 'tickets#show'
    put 'tickets/:id', to: 'tickets#update'
    post 'uploads', to: 'uploads#create'
  end
end
