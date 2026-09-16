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

  it 'is idempotent' do
    2.times { described_class.new.perform }

    expect(InstallationConfig.where(name: 'INSTALLATION_NAME').count).to eq(1)
  end
end
