public with sharing class VRT_CLS_UpdateFeeName {
    public static void UpdateFeeName(List<VRT_Fee__c> newFees) {

        for (VRT_Fee__c fee : newFees) {
            String OriginalName = fee.Name;

            // Tipo_de_vehiculo__c and Temporada__c are picklist fields. Precio_por_dia__c is a currency field. Name is a text field.
            fee.Name = fee.Tipo_de_vehiculo__c + ' - ' +
                        fee.Temporada__c + ' - ' +
                        String.valueOf(fee.Precio_por_dia__c) + '€';

            if (OriginalName != fee.Name) {
                System.debug('Updated Fee Name from: ' + OriginalName + ' to: ' + fee.Name);
            }
        }
    }
}