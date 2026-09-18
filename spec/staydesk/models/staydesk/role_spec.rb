require 'rails_helper'

RSpec.describe Staydesk::Role do
  let(:account) { create(:account) }

  it 'reads the catalog from the configuration file' do
    expect(described_class.permissions).to include('staydesk_settings_manage', 'staydesk_queues_manage')
    expect(described_class.permissions).to eq(described_class.permissions.uniq)
  end

  it 'refuses a permission that is not in the catalog' do
    role = described_class.new(account: account, name: 'Inventado', permissions: ['staydesk_voar'])

    expect(role).not_to be_valid
    expect(role.errors[:permissions].join).to include('staydesk_voar')
  end

  it 'opens an area to its own permission and to the general one' do
    expect(described_class.permissions_for_area(:filas)).to contain_exactly('staydesk_queues_manage',
                                                                           'staydesk_settings_manage')
  end

  describe 'a policy of that area' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:account_user) { account.account_users.find_by(user: agent) }
    let(:role) { described_class.create!(account: account, name: 'Coordenação', permissions: ['staydesk_queues_manage']) }

    it 'lets the role configure without making the person an administrator' do
      Staydesk::AccountUserRole.create!(account_user: account_user, staydesk_role: role, kind: 'full')

      politica = Staydesk::QueuePolicy.new({ user: agent, account: account, account_user: account_user.reload },
                                           Staydesk::Queue)

      expect(politica.create?).to be(true)
      expect(politica.update?).to be(true)
    end

    it 'keeps the door closed for an agent without the permission' do
      politica = Staydesk::QueuePolicy.new({ user: agent, account: account, account_user: account_user },
                                           Staydesk::Queue)

      expect(politica.create?).to be(false)
    end

    it 'does not let the permission of one area open another' do
      Staydesk::AccountUserRole.create!(account_user: account_user, staydesk_role: role, kind: 'full')

      politica = Staydesk::SlaPolicyPolicy.new({ user: agent, account: account, account_user: account_user.reload },
                                               Staydesk::SlaPolicy)

      expect(politica.create?).to be(false)
    end
  end
end
