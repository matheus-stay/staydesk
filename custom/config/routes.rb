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
end
