@isTest
public class VRT_CLS_CheckVehicleRevision_Test {

    @isTest
    static void testBatchRevision() {
        // 1. Preparación de datos (Data Setup)
        List<VRT_Vehicle__c> vehicles = new List<VRT_Vehicle__c>();

        VRT_Vehicle__c inspectionCar = new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_TXT_LicensePlate__c = 'inspect',
            VRT_DAT_ManufacturedYear__c = Date.today().addYears(-5),
            VRT_FLG_NeedsInspection__c = false,
            VRT_NUM_Passengers__c = 4,
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_Brand__c = 'Dacia',
            VRT_TXT_Model__c = 'Sandero'
        );
        vehicles.add(inspectionCar);

        VRT_Vehicle__c newCar = new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_TXT_LicensePlate__c = 'noInspe',
            VRT_DAT_ManufacturedYear__c = Date.today().addYears(-2),
            VRT_FLG_NeedsInspection__c = false,
            VRT_NUM_Passengers__c = 4,
            VRT_SEL_EnergyType__c = 'Eléctrico',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_Brand__c = 'Peugeot',
            VRT_TXT_Model__c = 'e-208'
        );
        vehicles.add(newCar);

        VRT_Vehicle__c inspectionBike = new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Moto',
            VRT_TXT_LicensePlate__c = 'inspect',
            VRT_DAT_ManufacturedYear__c = Date.today().addYears(-4),
            VRT_FLG_NeedsInspection__c = false,
            VRT_NUM_Passengers__c = 2,
            VRT_SEL_EnergyType__c = 'Diesel',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_Brand__c = 'Kawasaki',
            VRT_TXT_Model__c = 'Ninja'
        );
        vehicles.add(inspectionBike);

        VRT_Vehicle__c newBike = new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Moto',
            VRT_TXT_LicensePlate__c = 'noInspe',
            VRT_DAT_ManufacturedYear__c = Date.today().addYears(-2),
            VRT_FLG_NeedsInspection__c = false,
            VRT_NUM_Passengers__c = 2,
            VRT_SEL_EnergyType__c = 'Híbrido',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_Brand__c = 'BMW',
            VRT_TXT_Model__c = 'CE 02'
        );
        vehicles.add(newBike);

        insert vehicles;

        // 2. Ejecución
        // Todo proceso asíncrono debe ir entre startTest y stopTest
        Test.startTest();
        VRT_CLS_CheckVehicleRevision batch = new VRT_CLS_CheckVehicleRevision();
        Database.executeBatch(batch);
        Test.stopTest(); // Aquí es donde Salesforce fuerza la ejecución del Batch

        // 3. Verificación (Asserts)
        // Volvemos a consultar el registro para ver si el Batch lo cambió
        VRT_Vehicle__c[] UpdatedOldVehicles = [
            SELECT VRT_FLG_NeedsInspection__c, VRT_TXT_Brand__c, VRT_TXT_Model__c
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'inspect'];

        VRT_Vehicle__c[] UpdatedNewVehicles = [
            SELECT VRT_FLG_NeedsInspection__c, VRT_TXT_Brand__c, VRT_TXT_Model__c
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'noInspe'];

        // Comprobamos que el booleano ahora es true
       for (VRT_Vehicle__c vehicle : UpdatedOldVehicles) {
        Assert.areEqual(true, vehicle.VRT_FLG_NeedsInspection__c, vehicle.VRT_TXT_Brand__c + ' ' + vehicle.VRT_TXT_Model__c + ' DEBERÍA necesitar inspección');
       }

        // Comprobamos que el booleano sigue siendo false
       for (VRT_Vehicle__c vehicle : UpdatedNewVehicles) {
        Assert.areEqual(false, vehicle.VRT_FLG_NeedsInspection__c, vehicle.VRT_TXT_Brand__c + ' ' + vehicle.VRT_TXT_Model__c + ' NO debería necesitar inspección');
       }
    }
}