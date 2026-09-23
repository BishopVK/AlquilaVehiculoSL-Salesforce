public with sharing class VRT_LWC_FleetSearchController {

    /**
     * 1. Recuperar la flota de vehículos con todos los campos necesarios utilizando el texto recibido
     * Se usa @AuraEnabled(cacheable=true) porque es una lectura que se conectará con @wire en LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<VRT_Vehicle__c> getFleetSearched(String searchTerm) {
        if (searchTerm == null || searchTerm.trim() == '' || searchTerm.length() < 2) {
            return new List<VRT_Vehicle__c>();
        }

        String searchPattern = '%' + searchTerm + '%';

        return [
            SELECT Id, Name, VRT_SEL_VehicleType__c, VRT_TXT_Brand__c, VRT_TXT_Model__c, VRT_TXT_LicensePlate__c, VRT_SEL_Status__c
            FROM VRT_Vehicle__c
            WHERE (
                VRT_TXT_Brand__c LIKE :searchPattern
                OR VRT_TXT_Model__c LIKE :searchPattern
                OR VRT_TXT_LicensePlate__c LIKE :searchPattern
            )
            ORDER BY Name ASC
            LIMIT 50
        ];
    }
}