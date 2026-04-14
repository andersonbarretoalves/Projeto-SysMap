public with sharing class ReceitaWSService {

    // ============================================
    // 🔹 MÉTODO PRINCIPAL (API)
    // ============================================
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> buscarCNPJ(String cnpj) {

        if (String.isBlank(cnpj)) {
            throw createAuraException('O CNPJ não pode estar vazio.');
        }

        String cleanCnpj = cnpj.replaceAll('[^0-9]', '');

        if (cleanCnpj.length() != 14 ||
            cleanCnpj == '00000000000000' ||
            cleanCnpj == '11111111111111') {

            throw createAuraException('CNPJ inválido.');
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.receitaws.com.br/v1/cnpj/' + cleanCnpj);
        req.setMethod('GET');
        req.setTimeout(120000);

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 429) {
                throw createAuraException('Limite de consultas atingido.');
            }

            if (res.getStatusCode() == 403) {
                throw createAuraException('Acesso bloqueado pela API.');
            }

            if (res.getStatusCode() == 500) {
                throw createAuraException('Erro interno na API.');
            }

            if (res.getStatusCode() != 200) {
                throw createAuraException(
                    'Erro na API (' + res.getStatusCode() + ')'
                );
            }

            Map<String, Object> result =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            // valida se a API retornou o CNPJ correto
            String cnpjRetornado = String.valueOf(result.get('cnpj')).replaceAll('[^0-9]', '');

            if (cnpjRetornado != cleanCnpj) {
                throw createAuraException('Erro: API retornou dados inconsistentes.');
            }

            if (result.get('status') == 'ERROR') {
                throw createAuraException((String) result.get('message'));
            }

            if (result.get('nome') == null) {
                throw createAuraException('CNPJ não encontrado.');
            }

            return result;

        } catch (Exception e) {
            throw createAuraException(e.getMessage());
        }
    }

    // ============================================
    // 🔹 MÉTODO PARA FLOW
    // ============================================
    @InvocableMethod(label='Buscar CNPJ')
    public static List<RetornoCNPJ> buscarCNPJFlow(List<InputCNPJ> inputs) {

        List<RetornoCNPJ> lista = new List<RetornoCNPJ>();

        for (InputCNPJ input : inputs) {

            RetornoCNPJ r = new RetornoCNPJ();

            try {
                Map<String, Object> result = buscarCNPJ(input.cnpj);

                r.nome = (String) result.get('nome');
                r.logradouro = (String) result.get('logradouro');
                r.numero = (String) result.get('numero');
                r.complemento = (String) result.get('complemento');
                r.bairro = (String) result.get('bairro');
                r.cidade = (String) result.get('municipio');
                r.uf = (String) result.get('uf');
                r.cep = (String) result.get('cep');
                r.telefone = (String) result.get('telefone');
                
                r.status = (String) result.get('situacao');

                r.erro = false;

            } catch (Exception e) {
                r.erro = true;
                r.mensagemErro = e.getMessage();
            }

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
        public String numero;

        @InvocableVariable
        public String complemento;

        @InvocableVariable
        public String bairro;

        @InvocableVariable
        public String cidade;

        @InvocableVariable
        public String uf;

        @InvocableVariable
        public String cep;

        @InvocableVariable
        public String telefone;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public Boolean erro;

        @InvocableVariable
        public String mensagemErro;
    }

    // ============================================
    // 🔹 TRATAMENTO DE ERRO
    // ============================================
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}