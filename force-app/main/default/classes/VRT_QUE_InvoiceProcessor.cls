public with sharing class VRT_QUE_InvoiceProcessor implements Queueable, Database.AllowsCallouts {

    private Set<Id> rentalIds;

    public VRT_QUE_InvoiceProcessor(Set<Id> rentalIds) {
        this.rentalIds = rentalIds;
    }

    public void execute(QueueableContext context) {
        if (this.rentalIds == null || this.rentalIds.isEmpty()) {
            return;
        }

        List<VRT_Log__c> logsToInsert = new List<VRT_Log__c>();

        try {
            // 1. PREVENCIÓN DE DUPLICADOS:
            // Buscamos si alguno de estos alquileres ya dispone de una factura previa
            List<VRT_Invoice__c> existingInvoices = [
                SELECT Id, VRT_LKP_Rental__c 
                FROM VRT_Invoice__c 
                WHERE VRT_LKP_Rental__c IN :this.rentalIds
            ];

            Set<Id> alreadyInvoicedRentalIds = new Set<Id>();
            for (VRT_Invoice__c inv : existingInvoices) {
                alreadyInvoicedRentalIds.add(inv.VRT_LKP_Rental__c);
            }

            // 2. CONSULTAR ALQUILERES PENDIENTES DE FACTURAR (Excluyendo los ya facturados)
            List<VRT_Rental__c> rentalsToProcess = [
                SELECT Id, Name, VRT_DIV_TotalCost__c, VRT_LKP_Account__c,
                       VRT_LKP_Account__r.VRT_TXT_Email__c, VRT_LKP_Account__r.Name
                FROM VRT_Rental__c
                WHERE Id IN :this.rentalIds 
                  AND Id NOT IN :alreadyInvoicedRentalIds
            ];

            // Si todos ya tenían factura, registramos log informativo y salimos
            if (rentalsToProcess.isEmpty()) {
                logsToInsert.add(new VRT_Log__c(
                    VRT_TXT_ProcessName__c = 'Invoice Async Processing',
                    VRT_TXT_Message__c = 'Proceso omitido: Los alquileres seleccionados ya contaban con factura registrada.',
                    VRT_DAT_LogDate__c = Datetime.now()
                ));
                insert logsToInsert;
                return;
            }

            List<VRT_Invoice__c> newInvoices = new List<VRT_Invoice__c>();
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

            // 3. GENERAR FACTURAS Y PREPARAR NOTIFICACIONES
            for (VRT_Rental__c r : rentalsToProcess) {
                // Generar objeto Factura
                VRT_Invoice__c inv = new VRT_Invoice__c(
                    VRT_LKP_Rental__c = r.Id,
                    VRT_LKP_Account__c = r.VRT_LKP_Account__c,
                    VRT_DIV_Amount__c = r.VRT_DIV_TotalCost__c,
                    VRT_DAT_IssueDate__c = Date.today(),
                    VRT_SEL_Status__c = 'Emitida'
                );
                newInvoices.add(inv);

                // Preparar notificación por correo
                if (r.VRT_LKP_Account__r != null && String.isNotBlank(r.VRT_LKP_Account__r.VRT_TXT_Email__c)) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new List<String>{ r.VRT_LKP_Account__r.VRT_TXT_Email__c });
                    email.setSubject('Factura emitida para su alquiler - ' + r.Name);
                    email.setPlainTextBody(
                        'Estimado/a ' + r.VRT_LKP_Account__r.Name + ',\n\n' +
                        'Su alquiler ' + r.Name + ' ha sido completado. Se ha generado la factura correspondiente por un importe de ' +
                        r.VRT_DIV_TotalCost__c + ' €.\n\nGracias por su confianza.'
                    );
                    emailsToSend.add(email);
                }

                // Log de éxito individual
                logsToInsert.add(new VRT_Log__c(
                    VRT_TXT_ProcessName__c = 'Invoice Async Processing',
                    VRT_TXT_Message__c = 'Éxito: Factura generada y notificación enviada para ' + r.Name,
                    VRT_DAT_LogDate__c = Datetime.now(),
                    VRT_LKP_Rental__c = r.Id
                ));
            }

            // Inserciones y envíos masivos (Bulkified)
            if (!newInvoices.isEmpty()) {
                insert newInvoices;
            }

            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }

            if (!logsToInsert.isEmpty()) {
                insert logsToInsert;
            }

        } catch (Exception e) {
            // 4. REGISTRO DE ERRORES EN CASO DE FALLO (Requisito de trazabilidad)
            VRT_Log__c errorLog = new VRT_Log__c(
                VRT_TXT_ProcessName__c = 'Invoice Async Processing',
                VRT_TXT_Message__c = 'ERROR en facturación asíncrona: ' + e.getMessage() + ' | Línea: ' + e.getLineNumber(),
                VRT_DAT_LogDate__c = Datetime.now()
            );
            insert errorLog;
        }
    }
}