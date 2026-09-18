// Nomes de canal que a operação usa, em vez do nome da classe do Chatwoot.
const NOMES = {
  'Channel::WebWidget': 'Chat do site',
  'Channel::Api': 'API',
  'Channel::Email': 'E-mail',
  'Channel::Whatsapp': 'WhatsApp',
  'Channel::Sms': 'SMS',
  'Channel::TwilioSms': 'Twilio',
  'Channel::FacebookPage': 'Facebook',
  'Channel::Instagram': 'Instagram',
  'Channel::Telegram': 'Telegram',
  'Channel::Line': 'Line',
  'Channel::Voice': 'Voz',
  'Channel::Tiktok': 'TikTok',
};

export const nomeDoCanal = tipo =>
  NOMES[tipo] || String(tipo || '').replace('Channel::', '');

// Os canais que a conta usa de verdade, na ordem do nome.
export const canaisDaConta = inboxes =>
  [...new Set((inboxes || []).map(caixa => caixa.channel_type))]
    .map(tipo => ({ value: tipo, label: nomeDoCanal(tipo) }))
    .sort((um, outro) => um.label.localeCompare(outro.label));

// Um campo só para "que canais entram": o tipo inteiro (todo WhatsApp) ou um
// canal específico (o número StayCloud WPP), como *Canal é* e *Nome do canal é*
// da fila do Zendesk. Cada opção vira um token `tipo:` ou `canal:`.
const TIPO = 'tipo:';
const CANAL = 'canal:';
const TRABALHO = 'trabalho:';

// Primeiro os canais de trabalho ("Chat e WhatsApp"), que é como a operação
// nomeia o que um grupo atende; depois o tipo inteiro e cada canal.
export const opcoesDeCanais = (inboxes, rotuloDoTipo, filasDeCarga = []) => [
  ...filasDeCarga.map(fila => ({
    value: `${TRABALHO}${fila.key}`,
    label: fila.name,
  })),
  ...canaisDaConta(inboxes).flatMap(tipo => [
    { value: `${TIPO}${tipo.value}`, label: rotuloDoTipo(tipo.label) },
    ...(inboxes || [])
      .filter(canal => canal.channel_type === tipo.value)
      .map(canal => ({
        value: `${CANAL}${canal.id}`,
        label: `${tipo.label} · ${canal.name}`,
      })),
  ]),
];

export const separarCanais = tokens => ({
  load_queue_keys: (tokens || [])
    .filter(token => token.startsWith(TRABALHO))
    .map(token => token.slice(TRABALHO.length)),
  channel_types: (tokens || [])
    .filter(token => token.startsWith(TIPO))
    .map(token => token.slice(TIPO.length)),
  inbox_ids: (tokens || [])
    .filter(token => token.startsWith(CANAL))
    .map(token => Number(token.slice(CANAL.length))),
});

export const juntarCanais = (channelTypes, inboxIds, loadQueueKeys) => [
  ...(loadQueueKeys || []).map(chave => `${TRABALHO}${chave}`),
  ...(channelTypes || []).map(tipo => `${TIPO}${tipo}`),
  ...(inboxIds || []).map(id => `${CANAL}${id}`),
];
