public class VRT_CLS_CheckVehicleRevision implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Aquí va la QUERY
        Database.QueryLocator query = Database.getQueryLocator(
            'SELECT Id, VRT_DAT_ManufacturedYear__c, VRT_SEL_VehicleType__c, VRT_FLG_NeedsInspection__c FROM VRT_Vehicle__c WHERE VRT_FLG_NeedsInspection__c = false');

        return query;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        // Aquí va la lógica de Coche/Moto y el Update

        // Creamos una lista para los que realmente cambien
        List<VRT_Vehicle__c> vehiclesToUpdate = new List<VRT_Vehicle__c>();


        for (VRT_Vehicle__c vehicle : (List<VRT_Vehicle__c>)scope) {
            if (vehicle.VRT_DAT_ManufacturedYear__c != null) {
                Integer anioFabricacion = vehicle.VRT_DAT_ManufacturedYear__c.year();
                Integer anioActual = Date.today().year();

                if (vehicle.VRT_SEL_VehicleType__c == 'Coche' &&
                    (anioActual - anioFabricacion >= 4) ||
                    vehicle.VRT_SEL_VehicleType__c == 'Moto' &&
                    (anioActual - anioFabricacion >= 3)) {
                        vehicle.VRT_FLG_NeedsInspection__c = true;
                        vehiclesToUpdate.add(vehicle);
                }
            }
        }

        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Tareas finales (o vacío si no necesitas nada)
    }
}