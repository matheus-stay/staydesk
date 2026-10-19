// O assunto que a lista mostra, como no Zendesk: ticket (e-mail e API) mostra
// o assunto do chamado; chat e WhatsApp mostram "Chat com <cliente>". Nunca a
// última mensagem, que muda a cada resposta e não diz do que se trata.
const CANAIS_DE_TICKET = ['Channel::Email', 'Channel::Api'];

export const assuntoDaConversa = (conversa, t) => {
  if (!conversa) return '';
  const canal = conversa.meta?.channel || conversa.channel;
  if (CANAIS_DE_TICKET.includes(canal)) {
    return (
      conversa.additional_attributes?.mail_subject ||
      conversa.custom_attributes?.assunto ||
      t('STAYDESK.SUBJECT.NONE')
    );
  }
  const nome =
    conversa.meta?.sender?.name || t('STAYDESK.SUBJECT.UNKNOWN_CONTACT');
  return t('STAYDESK.SUBJECT.CHAT_WITH', { name: nome });
};
