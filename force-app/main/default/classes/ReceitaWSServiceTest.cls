@isTest
public class ReceitaWSServiceTest {

    // ============================
    // MOCK SUCESSO
    // ============================
    class MockSucesso implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"nome":"Empresa Teste","municipio":"Rio de Janeiro","uf":"RJ"}');
            return res;
        }
    }

    // ============================
    // MOCK ERRO HTTP
    // ============================
    class MockErroHttp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Erro interno');
            return res;
        }
    }

    // ============================
    // MOCK ERRO API (status ERROR)
    // ============================
    class MockErroAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ERROR","message":"CNPJ inválido"}');
            return res;
        }
    }

    // ============================
    // TESTE SUCESSO
    // ============================
    @isTest
    static void testBuscarCNPJ_Sucesso() {

        Test.setMock(HttpCalloutMock.class, new MockSucesso());

        Test.startTest();

        Map<String, Object> result = ReceitaWSService.buscarCNPJ('12345678000100');

        Test.stopTest();

        System.assertEquals('Empresa Teste', result.get('nome'));
        System.assertEquals('Rio de Janeiro', result.get('municipio'));
        System.assertEquals('RJ', result.get('uf'));
    }

    // ============================
    // TESTE ERRO HTTP
    // ============================
    @isTest
    static void testBuscarCNPJ_ErroHttp() {

        Test.setMock(HttpCalloutMock.class, new MockErroHttp());

        Test.startTest();

        try {
            ReceitaWSService.buscarCNPJ('12345678000100');
            System.assert(false, 'Era esperado erro HTTP');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Erro na API ReceitaWS'));
        }

        Test.stopTest();
    }

    // ============================
    // TESTE ERRO API
    // ============================
    @isTest
    static void testBuscarCNPJ_ErroAPI() {

        Test.setMock(HttpCalloutMock.class, new MockErroAPI());

        Test.startTest();

        try {
            ReceitaWSService.buscarCNPJ('12345678000100');
            System.assert(false, 'Era esperado erro da API');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('CNPJ inválido'));
        }

        Test.stopTest();
    }

    // ============================
    // TESTE CNPJ VAZIO
    // ============================
    @isTest
    static void testBuscarCNPJ_CnpjVazio() {

        Test.startTest();

        try {
            ReceitaWSService.buscarCNPJ('');
            System.assert(false, 'Era esperado erro de CNPJ vazio');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('CNPJ não pode estar vazio'));
        }

        Test.stopTest();
    }

    // ============================
    // TESTE MÉTODO FLOW
    // ============================
    @isTest
    static void testBuscarCNPJFlow() {

        Test.setMock(HttpCalloutMock.class, new MockSucesso());

        ReceitaWSService.InputCNPJ input = new ReceitaWSService.InputCNPJ();
        input.cnpj = '12345678000100';

        List<ReceitaWSService.InputCNPJ> inputs = new List<ReceitaWSService.InputCNPJ>{ input };

        Test.startTest();

        List<ReceitaWSService.RetornoCNPJ> result = ReceitaWSService.buscarCNPJFlow(inputs);

        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Empresa Teste', result[0].nome);
        System.assertEquals('Rio de Janeiro', result[0].cidade);
        System.assertEquals('RJ', result[0].uf);
    }
}