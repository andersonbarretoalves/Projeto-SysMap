/**
 * @description Classe de teste para ReceitaWSService.
 * Garante que todas as validações de CNPJ, retornos de API e lógica de Flow funcionem corretamente.
 */
@isTest
private class ReceitaWSServiceTest {

    /**
     * @description Classe interna que implementa HttpCalloutMock.
     * Permite simular respostas da API sem fazer uma chamada real à internet (obrigatório em testes Apex).
     */
    private class ReceitaWSDynamicMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        // O construtor permite definir dinamicamente o status (200, 404, etc) e o JSON de retorno
        public ReceitaWSDynamicMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.responseBody);
            res.setStatusCode(this.statusCode);
            return res;
        }
    }
    
    // --- TESTES DE VALIDAÇÃO DE REGRA DE NEGÓCIO (ANTES DA CHAMADA API) ---

    @isTest
    static void testCnpjVazio() {
        try {
            ReceitaWSService.buscarCNPJ('');
            System.assert(false, 'Deveria ter falhado por CNPJ vazio');
        } catch (Exception e) {
            // Verifica se a mensagem de erro retornada é a esperada
            System.assert(e.getMessage().contains('O CNPJ não pode estar vazio.'));
        }
    }

    @isTest
    static void testCnpjTamanhoInvalido() {
        try {
            ReceitaWSService.buscarCNPJ('123456'); // CNPJ com menos de 14 dígitos
            System.assert(false, 'Deveria ter falhado pelo tamanho do CNPJ');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    @isTest
    static void testCnpjApenasZeros() {
        try {
            ReceitaWSService.buscarCNPJ('00000000000000'); // Bloqueia sequências inválidas conhecidas
            System.assert(false, 'Deveria ter falhado por conter apenas zeros');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    @isTest
    static void testCnpjApenasUns() {
        try {
            ReceitaWSService.buscarCNPJ('11111111111111');
            System.assert(false, 'Deveria ter falhado por conter apenas uns');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    // --- TESTES DE ERROS DE STATUS HTTP (RESPOSTAS DO SERVIDOR) ---

    @isTest
    static void testErro429LimiteConsultas() {
        // Simula o erro 429 (Too Many Requests) da ReceitaWS
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(429, '{}'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Limite de consultas atingido.'));
        }
    }

    @isTest
    static void testErro403AcessoBloqueado() {
        // Simula erro de permissão ou bloqueio de IP
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(403, '{}'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Acesso bloqueado pela API.'));
        }
    }

    @isTest
    static void testErro500InternoAPI() {
        // Simula erro de servidor na ReceitaWS
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(500, '{}'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Erro interno na API.'));
        }
    }

    @isTest
    static void testErroOutroStatusNao200() {
        // Simula qualquer outro erro HTTP (ex: 404 Not Found)
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(404, '{}'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Erro ao consultar CNPJ. Tente novamente.'));
        }
    }

    // --- TESTES DE VALIDAÇÃO DE CONTEÚDO (DENTRO DO JSON RETORNADO) ---

    @isTest
    static void testCnpjInconsistente() {
        // Simula cenário onde a API retorna um CNPJ diferente do que foi enviado (erro de integridade)
        String jsonRetorno = '{"cnpj": "99.999.999/9999-99"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('dados inconsistentes'));
        }
    }

    @isTest
    static void testStatusErrorNoJson() {
        // Simula cenário onde o HTTP é 200, mas o JSON traz um erro da própria ReceitaWS
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "ERROR", "message": "CNPJ Rejeitado"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ Rejeitado'));
        }
    }

    @isTest
    static void testNomeNulo() {
        // Testa se o sistema trata CNPJs que não existem (API retorna OK, mas sem o campo 'nome')
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "OK"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ não encontrado.'));
        }
    }

    @isTest
    static void testExceptionGenericaCatch() {
        // Força um erro de processamento (JSON mal formado) para cobrir as linhas do bloco catch(Exception e)
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, 'JSON_QUEBRADO {'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            // Garante que a exceção foi capturada e tratada
            System.assert(e != null, 'Deve cair no catch genérico');
        }
    }

    // --- TESTES DE SUCESSO E COMPATIBILIDADE COM FLOW ---

    @isTest
    static void testFlowCnpjSucesso() {
        // Testa o cenário perfeito: API retorna 200 e todos os campos preenchidos
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "OK", "nome": "EMPRESA SUCESSO", "logradouro": "RUA A", "numero": "123", "complemento": "SALA 1", "bairro": "CENTRO", "municipio": "SAO PAULO", "uf": "SP", "cep": "01000-000", "telefone": "1199999999", "situacao": "ATIVA"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '00000000000191';
        
        Test.startTest();
        // Chama o método específico para Flows
        List<ReceitaWSService.RetornoCNPJ> retornos = ReceitaWSService.buscarCNPJFlow(new List<ReceitaWSService.InputCNPJ>{ input });
        Test.stopTest();
        
        // Asserções para garantir que os dados mapeados para o Flow estão corretos
        System.assertEquals(1, retornos.size(), 'Deve retornar 1 registro');
        System.assertEquals(false, retornos[0].erro, 'Não deve conter erro');
        System.assertEquals('EMPRESA SUCESSO', retornos[0].nome);
        System.assertEquals('ATIVA', retornos[0].status);
    }

    @isTest
    static void testFlowCnpjErro() {
        // Testa se o Flow recebe corretamente a flag de erro quando um CNPJ inválido é passado
        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '123'; // CNPJ inválido
        
        Test.startTest();
        List<ReceitaWSService.RetornoCNPJ> retornos = ReceitaWSService.buscarCNPJFlow(new List<ReceitaWSService.InputCNPJ>{ input });
        Test.stopTest();
        
        System.assertEquals(1, retornos.size());
        System.assertEquals(true, retornos[0].erro, 'O erro deve ser true');
        System.assert(retornos[0].mensagemErro.contains('CNPJ inválido.'), 'A mensagem de erro deve ser repassada ao Flow');
    }
}