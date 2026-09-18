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
