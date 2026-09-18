// Cliente da API do StayDesk. Uma função só: o resto do servidor é tabela.
const semBarra = url => String(url || '').replace(/\/+$/, '');

export class Api {
  constructor({ url, token, accountId }) {
    this.url = semBarra(url);
    this.token = token;
    this.accountId = accountId;
  }

  static doAmbiente(env = process.env) {
    const faltando = ['STAYDESK_URL', 'STAYDESK_TOKEN', 'STAYDESK_ACCOUNT_ID'].filter(
      chave => !env[chave]
    );
    if (faltando.length) {
      throw new Error(
        `Faltam variáveis de ambiente: ${faltando.join(', ')}. Veja custom/mcp/README.md.`
      );
    }
    return new Api({
      url: env.STAYDESK_URL,
      token: env.STAYDESK_TOKEN,
      accountId: env.STAYDESK_ACCOUNT_ID,
    });
  }

  caminho(rota) {
    const comConta = rota.replace(':accountId', this.accountId);
    return `${this.url}/api/v1/accounts/${this.accountId}${comConta.startsWith('/') ? '' : '/'}${comConta}`;
  }

  async chamar({ metodo = 'GET', rota, query, corpo }) {
    const endereco = new URL(this.caminho(rota));
    Object.entries(query || {}).forEach(([chave, valor]) => {
      if (valor !== undefined && valor !== null && valor !== '') {
        endereco.searchParams.set(chave, valor);
      }
    });

    const resposta = await fetch(endereco, {
      method: metodo,
      headers: {
        api_access_token: this.token,
        'content-type': 'application/json',
        accept: 'application/json',
      },
      body: corpo ? JSON.stringify(corpo) : undefined,
    });

    const texto = await resposta.text();
    if (!resposta.ok) {
      throw new Error(`${metodo} ${endereco.pathname} devolveu ${resposta.status}: ${texto.slice(0, 400)}`);
    }
    if (!texto) return { ok: true };

    try {
      return JSON.parse(texto);
    } catch {
      return { texto };
    }
  }
}
