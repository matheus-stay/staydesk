require 'rails_helper'

RSpec.describe AccountUser do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }

  it 'keeps the upstream permissions for a full agent' do
    expect(account_user.permissions).to eq(['agent'])
    expect(account_user.staydesk_light?).to be(false)
  end

  it 'adds the light permission when the StayDesk role is light' do
    Staydesk::AccountUserRole.create!(account_user: account_user, kind: 'light')

    expect(account_user.reload.permissions).to eq(%w[agent staydesk_light])
    expect(account_user.staydesk_light?).to be(true)
  end
end
