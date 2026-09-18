class CreateStaydeskCapacityRules < ActiveRecord::Migration[7.1]
  # A capacidade sai do status e vira regra atribuída ao agente, como no Zendesk.
  # O status passa a dizer só que canais de trabalho recebe.
  def up
    create_table :staydesk_capacity_rules do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :description
      t.jsonb :limits, null: false, default: {}
      t.boolean :is_default, null: false, default: false
      t.bigint :user_ids, array: true, null: false, default: []
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :staydesk_capacity_rules, [:account_id, :name], unique: true
    add_column :staydesk_agent_statuses, :work_channels, :string, array: true, null: false, default: []
    converter
    remove_column :staydesk_agent_statuses, :capacity
  end

  def down
    add_column :staydesk_agent_statuses, :capacity, :jsonb, null: false, default: {}
    remove_column :staydesk_agent_statuses, :work_channels
    drop_table :staydesk_capacity_rules
  end

  private

  # Cada status recebe os canais em que tinha limite acima de zero (ou nenhum
  # limite); a conta ganha uma regra padrão com o maior teto que os status tinham.
  def converter
    maximos = Hash.new { |hash, conta| hash[conta] = {} }
    select_all('SELECT id, account_id, capacity FROM staydesk_agent_statuses').each do |linha|
      capacidade = capacidade_de(linha)
      recebe = chaves_da_conta(linha['account_id']).select { |chave| capacidade[chave].nil? || capacidade[chave].to_i.positive? }
      execute "UPDATE staydesk_agent_statuses SET work_channels = #{lista(recebe)} WHERE id = #{linha['id']}"
      acumular_maximos(maximos[linha['account_id']], capacidade)
    end
    maximos.each { |conta, limites| criar_regra_padrao(conta, limites) }
  end

  def capacidade_de(linha)
    linha['capacity'].is_a?(String) ? JSON.parse(linha['capacity']) : (linha['capacity'] || {})
  end

  def chaves_da_conta(conta)
    @chaves ||= select_all('SELECT account_id, key FROM staydesk_load_queues ORDER BY position, id')
                .rows.group_by(&:first).transform_values { |linhas| linhas.map(&:last) }
    @chaves[conta] || %w[chat ticket]
  end

  def acumular_maximos(maximos, capacidade)
    capacidade.each do |chave, valor|
      maximos[chave] = [maximos[chave] || 0, valor.to_i].max if valor.to_i.positive?
    end
  end

  def criar_regra_padrao(conta, limites)
    execute 'INSERT INTO staydesk_capacity_rules (account_id, name, limits, is_default, created_at, updated_at) ' \
            "VALUES (#{conta}, 'Padrão', #{quote(limites.to_json)}, TRUE, NOW(), NOW())"
  end

  def lista(valores)
    "ARRAY[#{valores.map { |valor| quote(valor) }.join(', ')}]::varchar[]"
  end
end
