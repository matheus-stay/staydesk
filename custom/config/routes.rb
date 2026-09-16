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
