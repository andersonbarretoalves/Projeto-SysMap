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

  3- sfdx force:project:create -n CadastroDeClientes
  - comando utilizado para criação do projeto na IDE.

  4- cd CadastroDeClientes
  - Comando para entrar na pasta do projeto.

  5- sfdx config:set defaultusername=andersonbarretodev@resourceful-badger-s0xeok.com
  - Definir sua org como padrão.

  6- sfdx force:org:list
  - Verificar se o projeto está como Padão.

  <img 
  src="./imagens/conexãoOrgIDE/statusDosProjetos.png"
  alt="Print da Org" 
  width="48%">

  7- sf org login web --alias andersonbarretodev@resourceful-badger-s0xeok.com --set-default
  - Login já como padrão.

  <img 
  src="./imagens/conexãoOrgIDE/loginOrg.png"
  alt="Print da Org" 
  width="48%">

  8- sf org open
  - Abrir a Org pela IDE
