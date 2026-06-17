@isTest
private class VRT_CLS_TestFeeName_Test {
    @isTest
    static void TestFeeName() {
        // Create test data
        List<VRT_Fee__c> testFees = new List<VRT_Fee__c>();
        testFees.add(new VRT_Fee__c(Tipo_de_vehiculo__c = 'Coche', Temporada__c = 'Alta', Precio_por_dia__c = 80));
        testFees.add(new VRT_Fee__c(Tipo_de_vehiculo__c = 'Moto', Temporada__c = 'Media', Precio_por_dia__c = 30));

        // Insert test data
        insert testFees;

        // Update the test data to trigger the UpdateFeeName logic
       /*  for (VRT_Fee__c fee : testFees) {
            fee.Precio_por_dia__c += 10; // Change the price to trigger the update
        }
        update testFees; */

        // Verify that the names have been updated correctly
        for (VRT_Fee__c fee : [SELECT Name, Tipo_de_vehiculo__c, Temporada__c, Precio_por_dia__c FROM VRT_Fee__c WHERE Id IN :testFees]) {
            String expectedName = fee.Tipo_de_vehiculo__c + ' - ' + fee.Temporada__c + ' - ' + String.valueOf(fee.Precio_por_dia__c) + '€';
            System.assertEquals(expectedName, fee.Name, 'Fee name was not updated correctly.');
        }
    }
}