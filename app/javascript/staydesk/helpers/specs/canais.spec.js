import { describe, expect, it } from 'vitest';
import { juntarCanais, opcoesDeCanais, separarCanais } from '../canais';

const inboxes = [
  { id: 1, name: 'StayCloud WPP', channel_type: 'Channel::Whatsapp' },
  { id: 2, name: 'suporte@', channel_type: 'Channel::Email' },
  { id: 3, name: 'financeiro@', channel_type: 'Channel::Email' },
];

describe('canais num campo só', () => {
  it('lista o tipo inteiro e, embaixo, cada canal do tipo', () => {
    const opcoes = opcoesDeCanais(inboxes, nome => `Todo ${nome}`);
    expect(opcoes.map(o => o.label)).toEqual([
      'Todo E-mail',
      'E-mail · suporte@',
      'E-mail · financeiro@',
      'Todo WhatsApp',
      'WhatsApp · StayCloud WPP',
    ]);
  });

  it('põe os canais de trabalho na frente', () => {
    const opcoes = opcoesDeCanais(inboxes, nome => `Todo ${nome}`, [
      { key: 'chat', name: 'Chat e WhatsApp' },
    ]);
    expect(opcoes[0]).toEqual({
      value: 'trabalho:chat',
      label: 'Chat e WhatsApp',
    });
  });

  it('separa os tokens em canais de trabalho, tipos e canais e volta', () => {
    const tokens = ['trabalho:chat', 'tipo:Channel::Whatsapp', 'canal:3'];
    expect(separarCanais(tokens)).toEqual({
      load_queue_keys: ['chat'],
      channel_types: ['Channel::Whatsapp'],
      inbox_ids: [3],
    });
    expect(juntarCanais(['Channel::Whatsapp'], [3], ['chat'])).toEqual(tokens);
  });
});
