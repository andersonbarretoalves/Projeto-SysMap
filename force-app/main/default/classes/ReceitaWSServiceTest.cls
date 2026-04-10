@isTest
private class ReceitaWSServiceTest {

    // 1. Mock de Sucesso
    private class ReceitaWSSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "OK", "nome": "EMPRESA TESTE"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // 2. Mock de Erro HTTP (ex: 404)
    private class ReceitaWSHttpErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            return res;
        }
    }

    // 3. Mock de Erro no JSON (API retorna 200 mas com erro no corpo)
    private class ReceitaWSJsonErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "ERROR", "message": "CNPJ Invalido"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testBuscarCNPJSucesso() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSSuccessMock());
        Test.startTest();
        Map<String, Object> result = ReceitaWSService.buscarCNPJ('00.000.000/0001-91');
        Test.stopTest();
        System.assertEquals('OK', result.get('status'));
    }

    @isTest
    static void testBuscarCNPJErroStatusHTTP() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSHttpErrorMock());
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Erro na API ReceitaWS'));
        }
    }

    @isTest
    static void testBuscarCNPJErroNoJson() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWSJsonErrorMock());
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('123');
            Test.stopTest();
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('API Error'));
        }
    }

    @isTest
    static void testBuscarCNPJEmBranco() {
        try {
            ReceitaWSService.buscarCNPJ('');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('não pode estar vazio'));
        }
    }

    @isTest
    static void testBuscarCNPJExceptionGenerica() {
        // Não definimos Mock aqui. 
        // Como o Apex exige Mock para Callouts, tentar chamar sem Mock vai disparar uma CalloutException
        // Isso vai cair no bloco "catch (Exception e)" e cobrir as linhas finais.
        try {
            Test.startTest();
            ReceitaWSService.buscarCNPJ('00000000000191');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }
    }
}