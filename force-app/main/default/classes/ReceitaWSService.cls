public with sharing class ReceitaWSService {

    // 🔹 MÉTODO ORIGINAL (mantém para LWC)
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> buscarCNPJ(String cnpj) {
        if (String.isBlank(cnpj)) {
            throw createAuraException('O CNPJ não pode estar vazio.');
        }

        String cleanCnpj = cnpj.replaceAll('[^0-9]', '');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.receitaws.com.br/v1/cnpj/' + cleanCnpj);
        req.setMethod('GET');
        req.setTimeout(120000);

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                throw createAuraException('Erro na API ReceitaWS.');
            }

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (result.get('status') == 'ERROR') {
                throw createAuraException((String) result.get('message'));
            }

            return result;

        } catch (Exception e) {
            throw createAuraException(e.getMessage());
        }
    }

    // 🔥 MÉTODO PARA FLOW (NOVO)
    @InvocableMethod(label='Buscar CNPJ')
    public static List<RetornoCNPJ> buscarCNPJFlow(List<InputCNPJ> inputs) {

        List<RetornoCNPJ> lista = new List<RetornoCNPJ>();

        for (InputCNPJ input : inputs) {

            Map<String, Object> result = buscarCNPJ(input.cnpj);

            RetornoCNPJ r = new RetornoCNPJ();
            r.nome = (String) result.get('nome');
            r.cidade = (String) result.get('municipio');
            r.uf = (String) result.get('uf');

            lista.add(r);
        }

        return lista;
    }

    // 🔹 INPUT (Flow)
    public class InputCNPJ {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    // 🔹 OUTPUT (Flow)
    public class RetornoCNPJ {
        @InvocableVariable
        public String nome;

        @InvocableVariable
        public String cidade;

        @InvocableVariable
        public String uf;
    }

    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}