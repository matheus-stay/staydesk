require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ChatwootHub).to receive(:sync_with_hub).and_return({ 'version' => '1.2.3' })
  end

  it 'does not call the hub when telemetry is disabled' do
    with_modified_env DISABLE_TELEMETRY: 'true' do
      job
    end

    expect(ChatwootHub).not_to have_received(:sync_with_hub)
  end

  it 'still calls the hub when telemetry is enabled' do
    with_modified_env DISABLE_TELEMETRY: nil do
      job
    end

    expect(ChatwootHub).to have_received(:sync_with_hub)
  end
end
