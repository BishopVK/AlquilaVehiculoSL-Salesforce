public class VRT_TRG_RentalHandlerHelper {
    public static void updateConditionVehicle(List<VRT_Rental__c> insertedRental) {
        // 1. Contar usos por vehículo
        Map<Id, Integer> vehicleUsageCount = new Map<Id, Integer>();

        for (VRT_Rental__c rental : insertedRental) {
            if (rental.VRT_LKP_Vehicle__c != null) {

                if (!vehicleUsageCount.containsKey(rental.VRT_LKP_Vehicle__c)) {
                    vehicleUsageCount.put(rental.VRT_LKP_Vehicle__c, 1);
                } else {
                    vehicleUsageCount.put(
                        rental.VRT_LKP_Vehicle__c,
                        vehicleUsageCount.get(rental.VRT_LKP_Vehicle__c) + 1
                    );
                }
            }
        }

        if (vehicleUsageCount.isEmpty()) return;

        // 2. Query de vehículos
        List<VRT_Vehicle__c> vehicles = [
            SELECT Id, VRT_NUM_Usage__c, VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id IN :vehicleUsageCount.keySet()
        ];

        // 3. Aplicar lógica
        for (VRT_Vehicle__c v : vehicles) {
            Decimal currentUsage = (v.VRT_NUM_Usage__c == null) ? 0 : v.VRT_NUM_Usage__c;

            Integer increment = vehicleUsageCount.get(v.Id);

            Decimal newUsage = currentUsage + increment;

            v.VRT_NUM_Usage__c = newUsage;

            if (newUsage <= 50) {
                v.VRT_SEL_Condition__c = 'Recién fabricado';
            } else if (newUsage <= 200) {
                v.VRT_SEL_Condition__c = 'Casi nuevo';
            } else if (newUsage <= 500) {
                v.VRT_SEL_Condition__c = 'Algo desgastado';
            } else if (newUsage <= 1000) {
                v.VRT_SEL_Condition__c = 'Bastante desgastado';
            } else {
                v.VRT_SEL_Condition__c = 'Deplorable';
            }
        }

        // 4. Update masivo (1 DML)
        update vehicles;
    }

    public static void updateVehicleRentalCompleted(Map<Id, VRT_Rental__c> oldMap, Map<Id, VRT_Rental__c> newMap) {
        // 1. Lista donde guardamos los vehículos a actualizar y los días de transcurridos de alquiler
        Map<Id, Decimal> vehiclesIdsDays = new Map<Id, Decimal>();

        // 2. Recorrer el mapa y guardar los vehículos que debo actualizar el kilometraje:
        for (Id id : oldMap.keySet()) {
            VRT_Rental__c oldRental = oldMap.get(id);
            VRT_Rental__c newRental = newMap.get(id);
            if (oldRental.VRT_SEL_Status__c == 'En curso' &&
                newRental.VRT_SEL_Status__c == 'Completado') {
                if (newRental.VRT_LKP_Vehicle__c != null) {
                    Decimal daysToAdd = (newRental.VRT_FOR_Duration__c == null)
                    ? 0
                    : newRental.VRT_FOR_Duration__c;

                    if (!vehiclesIdsDays.containsKey(newRental.VRT_LKP_Vehicle__c)) {
                        vehiclesIdsDays.put(newRental.VRT_LKP_Vehicle__c, daysToAdd);
                    } else {
                        vehiclesIdsDays.put(newRental.VRT_LKP_Vehicle__c,
                        vehiclesIdsDays.get(newRental.VRT_LKP_Vehicle__c) + daysToAdd);
                    }
                }
            }
        }

        // 3. Query de vehículos
        List<VRT_Vehicle__c> vehicles = [
            SELECT id, VRT_NUM_Mileage__c
            FROM VRT_Vehicle__c
            WHERE Id IN :vehiclesIdsDays.keySet()
        ];

        // 4. Aplicar lógica
        for (VRT_Vehicle__c v : vehicles) {
            Decimal currentMileage = (v.VRT_NUM_Mileage__c == null)
            ? 0
            : v.VRT_NUM_Mileage__c;

            Decimal days = vehiclesIdsDays.get(v.Id);

            Decimal newMileage = currentMileage + (days * 200);

            v.VRT_NUM_Mileage__c = newMileage;
        }

        // 5. Update masivo (1 DML)
        update vehicles;
    }
}