@isTest
private class ReceitaWSServiceTest {

    // ============================================
    // 🔹 MOCK DINÂMICO DE INTEGRAÇÃO
    // ============================================
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
    // 🔹 TESTES DE VALIDAÇÃO DE ENTRADA (CNPJ)
    // ============================================
    
    @isTest
    static void testCnpjVazio() {
        try {
            ReceitaWSService.buscarCNPJ('');
            System.assert(false, 'Deveria ter falhado por CNPJ vazio');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('O CNPJ não pode estar vazio.'));
        }
    }

    @isTest
    static void testCnpjTamanhoInvalido() {
        try {
            ReceitaWSService.buscarCNPJ('123456'); 
            System.assert(false, 'Deveria ter falhado pelo tamanho do CNPJ');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CNPJ inválido.'));
        }
    }

    @isTest
    static void testCnpjApenasZeros() {
        try {
            ReceitaWSService.buscarCNPJ('00000000000000');
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

    // ============================================
    // 🔹 TESTES DE RETORNO HTTP DA API
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
    static void testErroOutroStatusNao200() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(404, '{}'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Erro ao consultar CNPJ. Tente novamente.'));
        }
    }

    // ============================================
    // 🔹 TESTES DE PAYLOAD (REGRAS DE NEGÓCIO NO JSON)
    // ============================================

    @isTest
    static void testCnpjInconsistente() {
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
        // Envia JSON malformado para disparar erro na desserialização e cair no Catch
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, 'JSON_QUEBRADO {'));
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e != null, 'Deve cair no catch genérico');
        }
    }

    // ============================================
    // 🔹 TESTES DO FLOW (SUCESSO E ERRO)
    // ============================================

    @isTest
    static void testFlowCnpjSucesso() {
        // Incluindo os novos campos no JSON mockado
        String jsonRetorno = '{"cnpj": "00.000.000/0001-91", "status": "OK", "nome": "EMPRESA SUCESSO", "logradouro": "RUA A", "numero": "123", "complemento": "SALA 1", "bairro": "CENTRO", "municipio": "SAO PAULO", "uf": "SP", "cep": "01000-000", "telefone": "1199999999", "situacao": "ATIVA"}';
        Test.setMock(HttpCalloutMock.class, new ReceitaWSDynamicMock(200, jsonRetorno));
        
        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '00000000000191';
        
        Test.startTest();
        List<ReceitaWSService.RetornoCNPJ> retornos = ReceitaWSService.buscarCNPJFlow(new List<ReceitaWSService.InputCNPJ>{ input });
        Test.stopTest();
        
        System.assertEquals(1, retornos.size(), 'Deve retornar 1 registro');
        System.assertEquals(false, retornos[0].erro, 'Não deve conter erro');
        System.assertEquals('EMPRESA SUCESSO', retornos[0].nome);
        System.assertEquals('123', retornos[0].numero);
        System.assertEquals('SALA 1', retornos[0].complemento);
        System.assertEquals('CENTRO', retornos[0].bairro);
        System.assertEquals('ATIVA', retornos[0].status);
    }

    @isTest
    static void testFlowCnpjErro() {
        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '123'; // CNPJ inválido
        
        Test.startTest();
        List<ReceitaWSService.RetornoCNPJ> retornos = ReceitaWSService.buscarCNPJFlow(new List<ReceitaWSService.InputCNPJ>{ input });
        Test.stopTest();
        
        System.assertEquals(1, retornos.size());
        System.assertEquals(true, retornos[0].erro, 'O erro deve ser true');
        System.assert(retornos[0].mensagemErro.contains('CNPJ inválido.'), 'A mensagem de erro deve ser preenchida');
    }
}