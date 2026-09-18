# StayDesk: todo agente já está em todos os canais (Staydesk::ChannelMembership),
# então `create(:inbox_member)` de um vínculo que já existe devolve o que está lá
# em vez de falhar na unicidade. Vale para os specs do upstream também.
FactoryBot.modify do
  factory :inbox_member do
    initialize_with { InboxMember.find_or_initialize_by(inbox: inbox, user: user) }
  end
end
