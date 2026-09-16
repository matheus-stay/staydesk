require 'rails_helper'

RSpec.describe StaydeskBoot do
  describe 'ChatwootApp.extensions' do
    it 'keeps enterprise when it is enabled' do
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)

      expect(ChatwootApp.extensions).to eq(%w[enterprise custom])
    end

    it 'drops enterprise when it is disabled' do
      with_modified_env DISABLE_ENTERPRISE: 'true' do
        expect(ChatwootApp.extensions).to eq(%w[custom])
      end
    end
  end
end
