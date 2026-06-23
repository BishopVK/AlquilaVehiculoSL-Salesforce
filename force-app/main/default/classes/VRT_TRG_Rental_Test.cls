@isTest
public class VRT_TRG_Rental_Test {

    @testSetup
    static void setup() {
        // Creating and inserting account sObject
        Account acct = new Account(
            Name = 'Testing Account',
            Phone = '630 123 456',
            NumberOfEmployees = 25);
        insert acct;

        // Creating vehicles and adding to vehicles list
        List<VRT_Vehicle__c> vehicles = new List<VRT_Vehicle__c>();

        // Vehicle 1
        vehicles.add(new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_NUM_Passengers__c = 5,
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_RE',
            VRT_TXT_Brand__c = 'Dacia',
            VRT_TXT_Model__c = 'Sandero',
            VRT_NUM_Usage__c = 0,
            VRT_NUM_Mileage__c = 0
        ));

        // Vehicle 2
        vehicles.add(new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Moto',
            VRT_NUM_Passengers__c = 2,
            VRT_SEL_EnergyType__c = 'Diesel',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_CA',
            VRT_TXT_Brand__c = 'Kawasaki',
            VRT_TXT_Model__c = 'Ninja',
            VRT_NUM_Usage__c = 100,
            VRT_NUM_Mileage__c = 10000
        ));

        // Vehicle 3
        vehicles.add(new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_NUM_Passengers__c = 2,
            VRT_SEL_EnergyType__c = 'Eléctrico',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_AL',
            VRT_TXT_Brand__c = 'Peugeot',
            VRT_TXT_Model__c = 'e-208',
            VRT_NUM_Usage__c = 499,
            VRT_NUM_Mileage__c = 150000
        ));

        // Vehicle 4
        vehicles.add(new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Moto',
            VRT_NUM_Passengers__c = 2,
            VRT_SEL_EnergyType__c = 'Híbrido',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_BA',
            VRT_TXT_Brand__c = 'BMW',
            VRT_TXT_Model__c = 'CE 02',
            VRT_NUM_Usage__c = 800,
            VRT_NUM_Mileage__c = 200000
        ));

        // Vehicle 5
        vehicles.add(new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_NUM_Passengers__c = 4,
            VRT_SEL_EnergyType__c = 'Otro',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_DE',
            VRT_TXT_Brand__c = 'Citroën',
            VRT_TXT_Model__c = 'Saxo',
            VRT_NUM_Usage__c = 1005,
            VRT_NUM_Mileage__c = 220200
        ));

        insert vehicles;
    }

    @isTest
    static void testUpdateConditionVehicleRecienFabricado() {
        // 1. Get id from a car whit 0-50 usages
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_RE'
            LIMIT 1];

        // 2. Create rental
        List<VRT_Rental__c> rentals = new List<VRT_Rental__c>();

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        rentals.add(rental);

        VRT_Rental__c rental2 = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        rentals.add(rental2);

        insert rentals;

        // 3. Check vehicle status after recorded rental
        VRT_Vehicle__c[] checkVehicle = [
            SELECT VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c];

        for (VRT_Vehicle__c vehicle : checkVehicle) {
            System.assertEquals('Recién fabricado', vehicle.VRT_SEL_Condition__c);
        }
    }

    @isTest
    static void testUpdateConditionVehicleCasiNuevo() {
        // 1. Get id from a car whit 50-200 usages
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_CA'
            LIMIT 1];

        // 2. Create rental
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        insert rental;

        // 3. Check vehicle status after recorded rental
        VRT_Vehicle__c checkVehicle = [
            SELECT VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c
            LIMIT 1];

        System.assertEquals('Casi nuevo', checkVehicle.VRT_SEL_Condition__c);
    }

    @isTest
    static void testUpdateConditionVehicleAlgoDesgastado() {
        // 1. Get id from a car whit 200-500 usages
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_AL'
            LIMIT 1];

        // 2. Create rental
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        insert rental;

        // 3. Check vehicle status after recorded rental
        VRT_Vehicle__c checkVehicle = [
            SELECT VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c
            LIMIT 1];

        System.assertEquals('Algo desgastado', checkVehicle.VRT_SEL_Condition__c);
    }

    @isTest
    static void testUpdateConditionVehicleBastanteDesgastado() {
        // 1. Get id from a car whit 500-1000 usages
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_BA'
            LIMIT 1];

        // 2. Create rental
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        insert rental;

        // 3. Check vehicle status after recorded rental
        VRT_Vehicle__c checkVehicle = [
            SELECT VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c
            LIMIT 1];

        System.assertEquals('Bastante desgastado', checkVehicle.VRT_SEL_Condition__c);
    }

    @isTest
    static void testUpdateConditionVehicleDeplorable() {
        // 1. Get id from a car whit +1000 usages
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_DE'
            LIMIT 1];

        // 2. Create rental
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id
        );
        insert rental;

        // 3. Check vehicle status after recorded rental
        VRT_Vehicle__c checkVehicle = [
            SELECT VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c
            LIMIT 1];

        System.assertEquals('Deplorable', checkVehicle.VRT_SEL_Condition__c);
    }

    @isTest
    static void testUpdateVehicleRentalCompleted () {
        // 1. Get id from a car with 0km
        VRT_Vehicle__c queriedVehicle = [
            SELECT Id
            FROM VRT_Vehicle__c
            WHERE VRT_TXT_LicensePlate__c = 'TEST_RE'
            LIMIT 1];

        // 2. Create rentals
        List<VRT_Rental__c> rentals = new List<VRT_Rental__c>();

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id,
            VRT_DAT_InitialDate__c = Date.newInstance(2026, 4, 20),
            VRT_DAT_FinalDate__c = Date.newInstance(2026, 4, 23)
        );
        rentals.add(rental);

        VRT_Rental__c rental2 = new VRT_Rental__c(
            VRT_SEL_Status__c = 'En curso',
            VRT_LKP_Vehicle__c = queriedVehicle.Id,
            VRT_DAT_InitialDate__c = Date.newInstance(2026, 4, 20),
            VRT_DAT_FinalDate__c = Date.newInstance(2026, 4, 23)
        );
        rentals.add(rental2);

        insert rentals;

        // 3. Update rentals
        for (VRT_Rental__c r : rentals) {
            r.VRT_SEL_Status__c = 'Completado';
        }

        update rentals;

        // 4. Check vehicle status after recorded rental
        VRT_Vehicle__c[] checkVehicle = [
            SELECT VRT_NUM_Mileage__c
            FROM VRT_Vehicle__c
            WHERE Id = :rental.VRT_LKP_Vehicle__c];

        // 5. Save final Mileage and validate Result
        for (VRT_Vehicle__c v : checkVehicle) {
            Decimal finalMileage = v.VRT_NUM_Mileage__c;
            System.assertEquals(600, finalMileage);
        }
    }

    @isTest
    static void testPricingCalculation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        VRT_Vehicle__c veh = [SELECT Id FROM VRT_Vehicle__c LIMIT 1];

        Test.startTest();
        // Caso 1: Cálculo estándar
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = acc.Id,
            VRT_LKP_Vehicle__c = veh.Id,
            VRT_DAT_InitialDate__c = Date.today().addDays(1), // Mes actual (ajusta según tu getTemporada)
            VRT_DAT_FinalDate__c = Date.today().addDays(5)
        );
        insert rental;
        Test.stopTest();

        VRT_Rental__c result = [SELECT VRT_DIV_TotalCost__c FROM VRT_Rental__c WHERE Id = :rental.Id];
        System.assertNotEquals(null, result.VRT_DIV_TotalCost__c, 'El coste debería haberse calculado');
    }

    @isTest
    static void testLoyaltyAndPenalty() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        VRT_Vehicle__c veh = [SELECT Id FROM VRT_Vehicle__c LIMIT 1];

        // Crear 3 alquileres previos para fidelidad
        List<VRT_Rental__c> oldRentals = new List<VRT_Rental__c>();
        for(Integer i=0; i<3; i++) {
            oldRentals.add(new VRT_Rental__c(
                VRT_LKP_Account__c = acc.Id, 
                VRT_LKP_Vehicle__c = veh.Id,
                VRT_DAT_InitialDate__c = Date.today().addDays(-360),
                VRT_DAT_FinalDate__c = Date.today().addDays(-355)
            ));
        }
        insert oldRentals;

        Test.startTest();
        // Crear un nuevo alquiler con retraso
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = acc.Id,
            VRT_LKP_Vehicle__c = veh.Id,
            VRT_DAT_InitialDate__c = Date.today().addDays(1),
            VRT_DAT_FinalDate__c = Date.today().addDays(3),
            VRT_DAT_ReturnDate__c = Date.today().addDays(5) // Retraso!
        );
        insert rental;
        Test.stopTest();

        VRT_Rental__c result = [SELECT VRT_DIV_TotalCost__c, VRT_CHK_Penalty__c FROM VRT_Rental__c WHERE Id = :rental.Id];
        System.assertEquals(true, result.VRT_CHK_Penalty__c, 'Debería estar penalizado');
    }

    @isTest
    static void testMissingFeeError() {
        // Crear vehículo con tipo inexistente en Custom Metadata
        VRT_Vehicle__c veh = new VRT_Vehicle__c(
            VRT_SEL_VehicleType__c = 'Barco',
            VRT_NUM_Passengers__c = 4,
            VRT_SEL_EnergyType__c = 'Otro',
            VRT_SEL_Status__c = 'Listo',
            VRT_TXT_LicensePlate__c = 'TEST_DE',
            VRT_TXT_Brand__c = 'Citroën',
            VRT_TXT_Model__c = 'Saxo',
            VRT_NUM_Usage__c = 1005,
            VRT_NUM_Mileage__c = 220200
        );
        insert veh;
        Account acc = [SELECT Id FROM Account LIMIT 1];

        try {
            insert new VRT_Rental__c(
                VRT_LKP_Account__c = acc.Id,
                VRT_LKP_Vehicle__c = veh.Id,
                VRT_DAT_InitialDate__c = Date.today(),
                VRT_DAT_FinalDate__c = Date.today().addDays(1)
            );
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No existe tarifa'), 'Debería haber lanzado error de tarifa');
        }
    }
}