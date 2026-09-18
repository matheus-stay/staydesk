require 'rails_helper'

RSpec.describe Staydesk::SetupService do
  let!(:account) { create(:account) }

  it 'writes the StayDesk branding into the installation config' do
    described_class.new.perform

    expect(GlobalConfig.get_value('INSTALLATION_NAME')).to eq('StayDesk')
    expect(GlobalConfig.get_value('BRAND_NAME')).to eq('StayDesk')
    expect(InstallationConfig.find_by(name: 'BRAND_URL')).to have_attributes(locked: false, value: described_class::BRAND_URL)
  end

  it 'enables disable_branding on every account' do
    described_class.new.perform

    expect(account.reload.feature_enabled?('disable_branding')).to be(true)
  end

  it 'turns off the features the operation does not use, in the account and for new accounts' do
    InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
                      .update!(value: [{ 'name' => 'campaigns', 'enabled' => true },
                                       { 'name' => 'help_center', 'enabled' => true },
                                       { 'name' => 'macros', 'enabled' => true }], locked: true)

    described_class.new.perform

    expect(account.reload.feature_enabled?('campaigns')).to be(false)
    expect(account.feature_enabled?('help_center')).to be(false)

    padrao = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').value
    expect(padrao.find { |f| f['name'] == 'campaigns' }['enabled']).to be(false)
    expect(padrao.find { |f| f['name'] == 'help_center' }['enabled']).to be(false)
    expect(padrao.find { |f| f['name'] == 'macros' }['enabled']).to be(true)
  end

  it 'keeps campaigns and the help center out of the default menu' do
    expect(Staydesk::WorkspaceResolver::PRODUCT_DEFAULT['menu']).not_to include('Campaigns', 'Portals')
  end

  it 'is idempotent' do
    2.times { described_class.new.perform }

    expect(InstallationConfig.where(name: 'INSTALLATION_NAME').count).to eq(1)
  end
end
