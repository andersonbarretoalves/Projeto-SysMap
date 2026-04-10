public with sharing class ReceitaWSService {

    // @AuraEnabled permite que esse método seja chamado por LWC ou Aura
    @AuraEnabled
    public static Map<String, Object> buscarCNPJ(String cnpj) {

        // Cria o objeto responsável por enviar requisições HTTP
        Http http = new Http();

        // Cria o objeto de requisição (onde configuramos URL, método, etc.)
        HttpRequest req = new HttpRequest();

        // Define o endpoint da API (URL)
        // Aqui concatenamos o CNPJ informado na URL
        req.setEndpoint('https://www.receitaws.com.br/v1/cnpj/' + cnpj);

        // Define o método HTTP (GET = buscar dados)
        req.setMethod('GET');

        // (Opcional) Define um tempo máximo de espera (em milissegundos)
        req.setTimeout(5000);

        try {
            // Envia a requisição e recebe a resposta da API
            HttpResponse res = http.send(req);

            // Verifica se a resposta foi bem-sucedida (HTTP 200)
            if (res.getStatusCode() == 200) {

                // Converte o JSON (string) em um Map<String, Object>
                // deserializeUntyped permite trabalhar com JSON dinâmico
                return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            } else {

                // Caso a API retorne erro (ex: 400, 404, 500)
                // Lança um erro tratado para o front (LWC/Aura)
                throw new AuraHandledException(
                    'Erro ao consultar CNPJ. Status: ' + res.getStatusCode()
                );
            }

        } catch (Exception e) {

            // Captura qualquer erro (timeout, falha de conexão, etc.)
            // e envia uma mensagem amigável para o usuário
            throw new AuraHandledException(
                'Erro na integração com a ReceitaWS: ' + e.getMessage()
            );
        }
    }
}