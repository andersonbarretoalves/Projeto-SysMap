import { LightningElement } from 'lwc';
import buscarCNPJ from '@salesforce/apex/ReceitaWSService.buscarCNPJ';
import buscarPorCNPJ from '@salesforce/apex/ReceitaWSService.buscarPorCNPJ';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

export default class ConsultaCnpj extends LightningElement {

    cnpj = '';
    nome = '';
    logradouro = '';
    cidade = '';
    uf = '';
    cep = '';
    telefone = '';

    // 🔹 Captura CNPJ
    handleCnpj(event) {
        this.cnpj = event.target.value;
    }

    // 🔹 Captura os demais campos
    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    // 🔹 Busca os dados do CNPJ
    async buscar() {
        try {
            const result = await buscarCNPJ({ cnpj: this.cnpj });

            this.nome = result.nome;
            this.logradouro = result.logradouro;
            this.cidade = result.municipio;
            this.uf = result.uf;
            this.cep = result.cep;
            this.telefone = result.telefone;

        } catch (error) {
            this.showToast('Erro', error.body.message, 'error');
        }
    }

    // 🔹 Salva os dados na conta
    async salvar() {
        try {

             // Limpa CNPJ (remove máscara)
            const cleanCnpj = this.cnpj.replace(/\D/g, '');

            //  Busca se já existe
            const existing = await buscarPorCNPJ({ cnpj: cleanCnpj });
        
            const fields = {
                Name: this.nome,
                BillingStreet: this.logradouro,
                BillingCity: this.cidade,
                BillingState: this.uf,
                BillingPostalCode: this.cep,
                Phone: this.telefone,
                CNPJ__c: cleanCnpj,

                //  Data de atualização da Receita
                Ultima_Atualizacao_Receita__c: new Date().toISOString()
            };

            //  SE EXISTE → UPDATE
            if (existing && existing.Id) {

                await updateRecord({
                    fields: {
                        Id: existing.Id,
                        Name: this.nome,
                        BillingStreet: this.logradouro,
                        BillingCity: this.cidade,
                        BillingState: this.uf,
                        BillingPostalCode: this.cep,
                        Phone: this.telefone,
            
                        Ultima_Atualizacao_Receita__c: new Date().toISOString()
                    }
                });
                // 🔹 Mostra a mensagem de sucesso
                this.showToast('Sucesso', 'Conta atualizada!', 'success');
            }
            // 🔵 SE NÃO → CREATE
            else {
                await createRecord({
                    apiName: 'Account',
                    fields: {
                        Name: this.nome,
                        BillingStreet: this.logradouro,
                        BillingCity: this.cidade,
                        BillingState: this.uf,
                        BillingPostalCode: this.cep,
                        Phone: this.telefone,
                        CNPJ__c: cleanCnpj,
                        Ultima_Atualizacao_Receita__c: new Date().toISOString()
                    }
                });

                // 🔹 Mostra a mensagem de sucesso
                this.showToast('Sucesso', 'Conta criada!', 'success');

            }
          
          // 🔹 Mostra a mensagem de erro
        }
        catch (error) {
            console.error('ERRO RAW:', error);
            console.error('ERRO JSON:', JSON.stringify(error));

            let msg = 'Erro ao salvar';

            if (error?.body?.output?.errors?.length) {
                msg = error.body.output.errors.map(e => e.message).join(', ');
            } else if (error?.body?.output?.fieldErrors) {
                const fe = error.body.output.fieldErrors;
                msg = Object.keys(fe)
                    .map(f => fe[f].map(e => `${f}: ${e.message}`).join(', '))
                    .join(' | ');
            } else if (Array.isArray(error?.body)) {
                msg = error.body.map(e => e.message).join(', ');
            } else if (error?.body?.message) {
                msg = error.body.message;
            }

            this.showToast('Erro', msg, 'error');
        }
    }

    //  Mostra a mensagem de sucesso ou erro
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}