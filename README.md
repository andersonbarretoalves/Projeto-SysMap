# **Projeto-SysMap**

## 🧠 **Tecnologias utilizadas**

- Salesforce Apex
- Flow Builder
- Lightning Web Components (LWC)

## ⚙️ **Funcionalidades**

- Validação de dados (ex: CNPJ)
- Automação com Flow
- Integração entre Apex e Flow

## 🗂️ **Estrutura do Projeto**

- Apex Classes
- Flows
- LWCs

## 🎯 **Status**

🚧 Em desenvolvimento

## 👨‍💻 **Autor**

- Anderson Alves

---

### **1º Criação de uma Org especifica para a execução do Projeto.**

<img 
  src="./imagens/imagemDaOrg.png" 
  alt="Print da Org" 
  width="50%">

### **2º Criação de Um repositório GitHub com um arquivo Readme.md para a Documentação do projeto e versionamento.**

<img 
  src="./imagens/imagemDoGitHub.png" 
  alt="Print da Org" 
  width="50%">

### **3º Criado um resumo da Apresentação do Projeto.**

- Separado as informações sobre LWC, Flow e Apex para a execução do projeto.

- Apartir da criação do Documento foi solicitado ao ChatGPT a criação de um Checklist Interativo do Projeto.

<img 
  src="./imagens/CheckListInterativo.png" 
  alt="Print da Org" 
  width="50%">

### **4º Criação do perfil, configuração de Permissões.**

- Criação do perfil de Representante de Vendas.

  <img 
    src="./imagens/perfilPermission/representanteDeVendas.png" 
    alt="Print da Org" 
    width="49%">

- Permissão no Objeto Conta.

  <img 
    src="./imagens/perfilPermission/permissionObjetoAccount.png" 
    alt="Print da Org" 
    width="49%">

- Permissão no Objeto Contato.

  <img 
    src="./imagens/perfilPermission/permissionObjetoContact.png" 
    alt="Print da Org" 
    width="49%">

### **5º Restringir acesso ao processo de cadastro.**

### **6º Liberar API (ReceitaWS)**

- Nome: ReceitaWS
- URL: https://www.receitaws.com.br

<img 
  src="./imagens/remoteSiteSettings/receitaWS.png"
  alt="Print da Org" 
  width="50%">

### **7º Conexão da IDE com a org e Criação do projeto**

- Sequencia de passoas:

  1- Execute os comentos pelo Terminal (Ctrl + Shift + ").
  - Obs: utilizei o cmd no terminal para a execução dos Comandos
  - Obs: Caso o Comando sfdx não funcionar trocar por sf(sfdx por sf).

  2- sfdx auth:web:login -a andersonbarretodev@resourceful-badger-s0xeok.com
  - comando utilizado para conectar a IDE com a ORG.

  3- sfdx force:project:create -n Projeto-SysMap
  - comando utilizado para criação do projeto na IDE.

  4- sfdx config:set defaultusername=andersonbarretodev@resourceful-badger-s0xeok.com
  - Definir sua org como padrão.

  5- sfdx force:org:list
  - Verificar se o projeto está como Padão.

  <img 
  src="./imagens/conexãoOrgIDE/statusDosProjetos.png"
  alt="Print da Org" 
  width="48%">

  6- sf org login web --alias andersonbarretodev@resourceful-badger-s0xeok.com --set-default
  - Login já como padrão.

  <img 
  src="./imagens/conexãoOrgIDE/loginOrg.png"
  alt="Print da Org" 
  width="48%">

  7- sf org open
  - Abrir a Org pela IDE

### **8º Criando a Classe Apex Callout**

- Após criar o código, utilizei o ChatGPT para comentá-lo e sugerir melhorias, que foram aplicadas na versão final.

💡 O que foi melhorado nessa versão

    ✔ Comentários em todas as etapas

    ✔ Tratamento de erro com try/catch

    ✔ Timeout configurado

    ✔ Mensagens mais claras

    ✔ Código mais seguro


```
public with sharing class ReceitaWSService {

    // @AuraEnabled permite que esse método seja chamado por LWC ou Aura
    @AuraEnabled
    public static Map<String, Object> buscarCNPJ(String cnpj) {

        // Cria o objeto responsável por enviar requisições HTTP
        Http http = new Http();

        // Cria o objeto de requisição (onde configuramos URL, método, etc.)
        HttpRequest req = new HttpRequest();

        // Define o endpoint da API (URL)
        // Aqui concatenamos o CNPJ informado na URL
        req.setEndpoint('https://www.receitaws.com.br/v1/cnpj/' + cnpj);

        // Define o método HTTP (GET = buscar dados)
        req.setMethod('GET');

        // (Opcional) Define um tempo máximo de espera (em milissegundos)
        // Boa prática para evitar travamentos
        req.setTimeout(5000);

        try {
            // Envia a requisição e recebe a resposta da API
            HttpResponse res = http.send(req);

            // Verifica se a resposta foi bem-sucedida (HTTP 200)
            if (res.getStatusCode() == 200) {

                // Converte o JSON (string) em um Map<String, Object>
                // deserializeUntyped permite trabalhar com JSON dinâmico
                return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            } else {

                // Caso a API retorne erro (ex: 400, 404, 500)
                // Lança um erro tratado para o front (LWC/Aura)
                throw new AuraHandledException(
                    'Erro ao consultar CNPJ. Status: ' + res.getStatusCode()
                );
            }

        } catch (Exception e) {

            // Captura qualquer erro (timeout, falha de conexão, etc.)
            // e envia uma mensagem amigável para o usuário
            throw new AuraHandledException(
                'Erro na integração com a ReceitaWS: ' + e.getMessage()
            );
        }
    }
}
```