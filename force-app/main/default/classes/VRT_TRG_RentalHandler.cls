public class VRT_TRG_RentalHandler {
    public static void onAfterInsert(List<VRT_Rental__c> insertedRental) {
        // Review and update the vehicle status if necessary
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(insertedRental);
    }

    public static void onAfterUpdate(Map<Id, VRT_Rental__c> oldMap, Map<Id, VRT_Rental__c> newMap) {
        // Calculate the total number of kilometers the vehicle has traveled
        VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);
    }

    public static void onBeforeInsert(List<VRT_Rental__c> newRental) {
        // Calculate the total rental amount before inserting or updating the rental record
        VRT_TRG_RentalHandlerHelper.calculatePricing(newRental);

        // Vehicle fleet availability control
        List<VRT_Rental__c> rentalsToControlFleet = new List<VRT_Rental__c>();
        for (VRT_Rental__c r : newRental) {
            if (newRental.VRT_SEL_Status__c == 'Reservado' ||
            newRental.VRT_SEL_Status__c == 'En curso') {
                rentalsToControlFleet.add(r);
            }
        }
        VRT_TRG_RentalHandlerHelper.vehicleFleetAvailabilityControl(rentalsToControlFleet);
    }

    public static void onBeforeUpdate(Map<Id, VRT_Rental__c> oldMap, Map<Id, VRT_Rental__c> newMap) {
        // Calculate if VRT_DAT_InitialDate__c, VRT_DAT_FinalDate__c, VRT_LKP_Vehicle__c or VRT_LKP_Account__c have changed, then recalculate the total rental amount
        List<VRT_Rental__c> rentalsToRecalculate = new List<VRT_Rental__c>();
        for (Id rentalId : newMap.keySet()) {
            VRT_Rental__c oldRental = oldMap.get(rentalId);
            VRT_Rental__c newRental = newMap.get(rentalId);
            if (oldRental.VRT_DAT_InitialDate__c != newRental.VRT_DAT_InitialDate__c ||
                oldRental.VRT_DAT_FinalDate__c != newRental.VRT_DAT_FinalDate__c ||
                oldRental.VRT_LKP_Vehicle__c != newRental.VRT_LKP_Vehicle__c ||
                oldRental.VRT_LKP_Account__c != newRental.VRT_LKP_Account__c ||
                oldRental.VRT_DAT_ReturnDate__c != newRental.VRT_DAT_ReturnDate__c) {
                rentalsToRecalculate.add(newRental);
            }
        }
        // Calculate the total rental amount before inserting or updating the rental record
        VRT_TRG_RentalHandlerHelper.calculatePricing(rentalsToRecalculate);

        List<VRT_Rental__c> rentalsToUpdateAvailability = new List<VRT_Rental__c>();
        for (Id rentalId : newMap.keySet()) {
            VRT_Rental__c oldRental = oldMap.get(rentalId);
            VRT_Rental__c newRental = newMap.get(rentalId);

            // El registro está o pasa a un estado que requiere bloquear el vehículo
            Boolean isActiveStatus = (newRental.VRT_SEL_Status__c == 'Reservado' ||
                                        newRental.VRT_SEL_Status__c == 'En curso');

            // Evaluamos si cambió algún dato crítico
            Boolean dataChanged = (oldRental.VRT_SEL_Status__c != newRental.VRT_SEL_Status__c ||
                                    oldRental.VRT_DAT_InitialDate__c != newRental.VRT_DAT_InitialDate__c ||
                                    oldRental.VRT_DAT_FinalDate__c != newRental.VRT_DAT_FinalDate__c ||
                                    oldRental.VRT_LKP_Vehicle__c != newRental.VRT_LKP_Vehicle__c);

            if (isActiveStatus && dataChanged) {
                rentalsToUpdateAvailability.add(newRental);
            }
        }
        // Vehicle fleet availability control
        VRT_TRG_RentalHandlerHelper.vehicleFleetAvailabilityControl(rentalsToUpdateAvailability);
    }
}