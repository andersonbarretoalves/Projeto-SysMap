/**
 * Classe de serviço para integração com a API ReceitaWS.
 * Permite a consulta de dados de CNPJ para componentes Lightning (LWC/Aura) e Fluxos (Flows).
*/
public with sharing class ReceitaWSService {

    /**
     * @description Realiza a chamada principal para a API da ReceitaWS.
     * @param cnpj String contendo o CNPJ a ser consultado (com ou sem máscara).
     * @return Map<String, Object> contendo os dados retornados pela API.
     * @throws AuraHandledException Exceção tratada para exibição no front-end.
    */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> buscarCNPJ(String cnpj) {

        // 1. Validação inicial: Verifica se o parâmetro está nulo ou vazio
        if (String.isBlank(cnpj)) {
            throw createAuraException('O CNPJ não pode estar vazio.');
        }

        // 2. Limpeza do dado: Remove caracteres especiais (pontos, barras, traços)
        String cleanCnpj = cnpj.replaceAll('[^0-9]', '');
        
        // 3. Validação de formato: Verifica tamanho e ignora sequências óbvias de teste
        if (cleanCnpj.length() != 14 ||
            cleanCnpj == '00000000000000' ||
            cleanCnpj == '11111111111111') {

            throw createAuraException('CNPJ inválido.');
        }

        // chamada HTTP só ocorre após validações de entrada
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
                throw createAuraException('Erro ao consultar CNPJ. Tente novamente.');
            }

            // Converte o corpo do JSON (String) em um Mapa de objetos
            Map<String, Object> result =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            // 5. Verificação de Consistência: Compara se o CNPJ retornado é o mesmo solicitado
            String cnpjRetornado = String.valueOf(result.get('cnpj')).replaceAll('[^0-9]', '');

            if (cnpjRetornado != cleanCnpj) {
                throw createAuraException('Erro: API retornou dados inconsistentes.');
            }

            // 6. Verificação de Erro no JSON: A API pode retornar status 200 mas com erro no corpo
            if (result.get('status') == 'ERROR') {
                throw createAuraException((String) result.get('message'));
            }

            // 7. Verificação de Existência: Garante que dados básicos foram encontrados
            if (result.get('nome') == null) {
                throw createAuraException('CNPJ não encontrado.');
            }

            return result;

        } catch (Exception e) {
            // Captura qualquer erro inesperado e repassa como AuraHandledException
            throw createAuraException(e.getMessage());
        }
    }


    /**
     * @description Método Invocável para ser utilizado em Salesforce Flows (Fluxos).
     * @param inputs Lista de inputs contendo o CNPJ (padrão para InvocableMethod).
     * @return List<RetornoCNPJ> Lista com os dados formatados para o Flow.
     */
    @InvocableMethod(label='Buscar CNPJ')
    public static List<RetornoCNPJ> buscarCNPJFlow(List<InputCNPJ> inputs) {

        List<RetornoCNPJ> lista = new List<RetornoCNPJ>();

        for (InputCNPJ input : inputs) {

            RetornoCNPJ r = new RetornoCNPJ();

            try {
                // Reaproveita a lógica do método principal para obter os dados
                Map<String, Object> result = buscarCNPJ(input.cnpj);

                // Mapeia os campos do Map para as variáveis do objeto de retorno
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
                // Caso ocorra erro, sinaliza ao Flow e envia a mensagem de erro
                r.erro = true;
                r.mensagemErro = e.getMessage();
            }

            lista.add(r);
        }

        return lista;
    }

    /**
     * @description Classe Wrapper para entrada de dados no Flow.
     */
    public class InputCNPJ {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    /**
     * @description Classe Wrapper para saída de dados no Flow.
     */
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

    /**
     * @description Método auxiliar para criar exceções que podem ser lidas pelo Lightning.
     * @param Mensagem de erro amigável.
     * @return AuraHandledException
     */
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}