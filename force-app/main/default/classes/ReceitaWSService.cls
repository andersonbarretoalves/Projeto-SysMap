public with sharing class ReceitaWSService {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> buscarCNPJ(String cnpj) {
        // Limpa o CNPJ (remove caracteres não numéricos)
        if (String.isBlank(cnpj)) {
            throw createAuraException('O CNPJ não pode estar vazio.');
        }
        
        String cleanCnpj = cnpj.replaceAll('[^0-9]', '');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.receitaws.com.br/v1/cnpj/' + cleanCnpj);
        req.setMethod('GET');
        req.setTimeout(120000); // Aumentado para o limite do Apex se necessário

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                throw createAuraException('Erro na API ReceitaWS. Status: ' + res.getStatusCode() + ' - ' + res.getStatus());
            }

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // A API do ReceitaWS retorna status: "ERROR" dentro do JSON em alguns casos (ex: CNPJ inválido)
            if (result.get('status') == 'ERROR') {
                throw createAuraException('API Error: ' + (String)result.get('message'));
            }

            return result;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw createAuraException('Erro inesperado na integração: ' + e.getMessage());
        }
    }

    // Helper para garantir que a mensagem chegue ao front-end
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message); // Necessário para testes e exibição correta
        return e;
    }
}