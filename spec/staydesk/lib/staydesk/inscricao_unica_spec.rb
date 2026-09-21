require 'rails_helper'

# O despachante é carregado a cada `to_prepare` e é singleton: sem cuidado, o
# mesmo ouvinte fica inscrito duas vezes e todo evento roda em dobro — foi o que
# fez o cliente receber dois avisos de recebimento do mesmo ticket.
RSpec.describe Staydesk::InscricaoUnica do
  let(:dispatcher) { AsyncDispatcher.new }

  it 'subscribes each listener only once, no matter how many times it loads' do
    3.times { dispatcher.load_listeners }

    contagem = dispatcher.send(:local_registrations).map { |r| r.listener.class.name }.tally

    expect(contagem.values.uniq).to eq([1])
    expect(contagem).to include('AutomationRuleListener' => 1, 'Staydesk::SlaListener' => 1)
  end

  it 'keeps the sync dispatcher clean too' do
    sync = SyncDispatcher.new
    2.times { sync.load_listeners }

    expect(sync.send(:local_registrations).map { |r| r.listener.class.name }.tally.values.uniq).to eq([1])
  end

  it 'replaces the old subscription when the application reloads the listener class' do
    dispatcher.load_listeners
    primeiro = dispatcher.send(:local_registrations).find { |r| r.listener.instance_of?(AutomationRuleListener) }.listener
    outro = AutomationRuleListener.send(:new)
    allow(dispatcher).to receive(:listeners).and_return([outro])
    dispatcher.load_listeners

    inscritos = dispatcher.send(:local_registrations).select { |r| r.listener.instance_of?(AutomationRuleListener) }.map(&:listener)

    expect(inscritos).to eq([outro])
    expect(inscritos).not_to include(primeiro)
  end

  it 'delivers the event once per load' do
    recebidos = []
    ouvinte = Class.new do
      define_method(:conversation_created) { |_event| recebidos << :ok }
    end.new
    allow(dispatcher).to receive(:listeners).and_return([ouvinte])
    2.times { dispatcher.load_listeners }

    dispatcher.publish_event('conversation.created', Time.zone.now, {})

    expect(recebidos.size).to eq(1)
  end
end
