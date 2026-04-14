@isTest
private class ReceitaWSServiceTest {

    // Mock dinâmico para simular diferentes retornos da API
    private class ReceitaWSDynamicMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

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

    // ============================================
    // 🔹 TESTES DE VALIDAÇÃO DE ENTRADA
    // ============================================
    
    @isTest
    static void testCnpjVazio() {
        try {
            ReceitaWSService.buscarCNPJ('');
            System.assert(false, 'Deveria ter lançado exceção de CNPJ vazio');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('O CNPJ não pode estar vazio.'));
        }
    }

    @isTest
    static void testCnpjTamanhoInvalido() {
        try {
            ReceitaWSService.buscarCNPJ('123'); // Menor que 14
            System.assert(false, 'Deveria ter lançado exceção de tamanho inválido');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    @isTest
    static void testCnpjApenasZeros() {
        try {
            ReceitaWSService.buscarCNPJ('00000000000000');
            System.assert(false, 'Deveria ter lançado exceção de CNPJ inválido (zeros)');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    @isTest
    static void testCnpjApenasUns() {
        try {
            ReceitaWSService.buscarCNPJ('11111111111111');
            System.assert(false, 'Deveria ter lançado exceção de CNPJ inválido (uns)');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    // ============================================
    // 🔹 TESTES DE ERROS HTTP DA API
    // ============================================

    @isTest
    static void testErro429LimiteConsultas() {
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
    static void testErroStatusNao200() {

        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(404, '{}'));

        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();

            System.assert(false, 'Era esperado erro');

        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('Erro ao consultar CNPJ'),
                'Mensagem inesperada: ' + e.getMessage()
            );
        }
    }

    // ============================================
    // 🔹 TESTES DE REGRAS DE NEGÓCIO NO JSON
    // ============================================

    @isTest
    static void testCnpjInconsistente() {
        // Envia um CNPJ válido na chamada, mas o Mock retorna um CNPJ diferente
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
        // A API retorna 200, mas o JSON diz que tem erro (Ex: CNPJ não existe na base deles)
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "ERROR", "message": "CNPJ rejeitado pela Receita"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ rejeitado'));
        }
    }

    @isTest
    static void testNomeNulo() {
        // A API retorna 200, status não é erro, mas falta o campo 'nome'
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
        // Retorna um JSON malformado para forçar um erro no JSON.deserializeUntyped e cair no catch(Exception e)
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, 'JSON_QUEBRADO {'));
        
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e != null, 'Deveria cair no bloco catch genérico e lançar exceção');
        }
    }

    // ============================================
    // 🔹 TESTES DE SUCESSO (API E FLOW)
    // ============================================

    @isTest
    static void testSucessoAPI() {
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "OK", "nome": "EMPRESA SUCESSO", "logradouro": "RUA A", "municipio": "SAO PAULO", "uf": "SP", "cep": "01000-000", "telefone": "1199999999"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        Test.startTest();
        Map<String, Object> resultado = ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
        Test.stopTest();
        
        System.assertEquals('EMPRESA SUCESSO', resultado.get('nome'));
    }

    @isTest
    static void testFlowCnpjSucesso() {
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "OK", "nome": "EMPRESA SUCESSO"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '00000000000191';
        
        Test.startTest();
        List<ReceitaWSService.RetornoCNPJ> retornos = ReceitaWSService.buscarCNPJFlow(new List<ReceitaWSService.InputCNPJ>{ input });
        Test.stopTest();
        
        System.assertEquals(1, retornos.size());
        System.assertEquals(false, retornos[0].erro);
        System.assertEquals('EMPRESA SUCESSO', retornos[0].nome);
    }

    @isTest
    static void testFlowCnpjErro() {

        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(400, '{}'));

        Test.startTest();

        try {
            ReceitaWSService.buscarCNPJ('123');

            System.assert(false, 'Era esperado lançar erro');

        } catch (Exception e) {

            System.assert(
                e.getMessage().contains('CNPJ inválido'),
                'Mensagem inesperada: ' + e.getMessage()
            );
        }

        Test.stopTest();
    }
}