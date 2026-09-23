public with sharing class VRT_LWC_RentalConsoleController {

    /**
     * 1. Obtener los alquileres de la Cuenta actual
     * Se usa @AuraEnabled(cacheable=true) porque es una lectura que se conectará con @wire en LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<VRT_Rental__c> getActiveRentals(Id accountId) {
        if (accountId == null) {
            return new List<VRT_Rental__c>();
        }

        return [
            SELECT Id, Name, VRT_LKP_Vehicle__r.Name, VRT_DAT_InitialDate__c, 
                   VRT_DAT_FinalDate__c, VRT_SEL_Status__c, VRT_DIV_TotalCost__c
            FROM VRT_Rental__c
            WHERE VRT_LKP_Account__c = :accountId
            AND (VRT_SEL_Status__c = 'Completado'
            OR VRT_SEL_Status__c = 'Reservado')
            ORDER BY VRT_DAT_InitialDate__c DESC
        ];
    }

    /**
     * 2. Simular el precio antes de guardar
     * NO lleva cacheable=true porque realiza un cálculo dinámico en función de las fechas seleccionadas.
     */
    @AuraEnabled
    public static Decimal simulateRentalPrice(Id vehicleId, Id accountId, Date startDate, Date endDate) {
        // Instanciamos un registro temporal en memoria (no se guarda en BBDD)
        VRT_Rental__c tempRental = new VRT_Rental__c(
            VRT_LKP_Vehicle__c = vehicleId,
            VRT_LKP_Account__c = accountId,
            VRT_DAT_InitialDate__c = startDate,
            VRT_DAT_FinalDate__c = endDate
        );

        // Reutilizamos el motor de precios que ya construí en el helper
        VRT_TRG_RentalHandlerHelper.calculatePricing(new List<VRT_Rental__c>{ tempRental });

        return tempRental.VRT_DIV_TotalCost__c;
    }

    /**
     * 3. Guardar el nuevo Alquiler desde la consola
     */
    @AuraEnabled
    public static VRT_Rental__c createRental(VRT_Rental__c newRental) {
        try {
            insert newRental;
            return newRental;
        } catch (Exception e) {
            // Re-lanzamos la excepción para que el LWC capture el error en el .catch()
            throw new AuraHandledException(e.getMessage());
        }
    }
}