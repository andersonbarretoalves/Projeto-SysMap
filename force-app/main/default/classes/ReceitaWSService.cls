public with sharing class ReceitaWSService {

    // ============================================
    // 🔹 MÉTODO PRINCIPAL (LWC / API)
    // ============================================
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

            Map<String, Object> result = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (result.get('status') == 'ERROR') {
                throw createAuraException((String) result.get('message'));
            }

            return result;

        } catch (Exception e) {
            throw createAuraException(e.getMessage());
        }
    }

    // ============================================
    // 🔥 NOVO: BUSCAR ACCOUNT POR CNPJ (LWC)
    // ============================================
    @AuraEnabled(cacheable=true)
    public static Account buscarPorCNPJ(String cnpj) {

        if (String.isBlank(cnpj)) {
            return null;
        }

        String cleanCnpj = cnpj.replaceAll('[^0-9]', '');

        List<Account> contas = [
            SELECT Id, Name, CNPJ__c
            FROM Account
            WHERE CNPJ__c != null
        ];

        for (Account acc : contas) {
            String accCnpj = acc.CNPJ__c != null 
                ? acc.CNPJ__c.replaceAll('[^0-9]', '') 
                : '';

            if (accCnpj == cleanCnpj) {
                return acc;
            }
        }

        return null;
    }

    // ============================================
    // 🔹 MÉTODO PARA FLOW
    // ============================================
    @InvocableMethod(label='Buscar CNPJ')
    public static List<RetornoCNPJ> buscarCNPJFlow(List<InputCNPJ> inputs) {

        List<RetornoCNPJ> lista = new List<RetornoCNPJ>();

        for (InputCNPJ input : inputs) {

            Map<String, Object> result = buscarCNPJ(input.cnpj);

            RetornoCNPJ r = new RetornoCNPJ();
            r.nome = (String) result.get('nome');
            r.logradouro = (String) result.get('logradouro');
            r.cidade = (String) result.get('municipio');
            r.uf = (String) result.get('uf');
            r.cep = (String) result.get('cep');
            r.telefone = (String) result.get('telefone');

            lista.add(r);
        }

        return lista;
    }

    // ============================================
    // 🔹 INPUT (FLOW)
    // ============================================
    public class InputCNPJ {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    // ============================================
    // 🔹 OUTPUT (FLOW)
    // ============================================
    public class RetornoCNPJ {

        @InvocableVariable
        public String nome;

        @InvocableVariable
        public String logradouro;

        @InvocableVariable
        public String cidade;

        @InvocableVariable
        public String uf;

        @InvocableVariable
        public String cep;

        @InvocableVariable
        public String telefone;
    }

    // ============================================
    // 🔹 TRATAMENTO DE ERRO PADRÃO
    // ============================================
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}