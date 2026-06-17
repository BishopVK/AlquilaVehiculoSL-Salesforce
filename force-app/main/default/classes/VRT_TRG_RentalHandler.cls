public class VRT_TRG_RentalHandler {
    public static void onAfterInsert(List<VRT_Rental__c> insertedRental) {
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(insertedRental);
    }

    public static void onAfterUpdate(Map<Id, VRT_Rental__c> oldMap, Map<Id, VRT_Rental__c> newMap) {
        VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);
    }

    // Calculate the total rental amount before inserting or updating the rental record
    public static void onBeforeInsert(List<VRT_Rental__c> newRental) {
        VRT_TRG_RentalHandlerHelper.calculatePricing(newRental);
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
                oldRental.VRT_LKP_Account__c != newRental.VRT_LKP_Account__c) {
                rentalsToRecalculate.add(newRental);
            }
        }
        VRT_TRG_RentalHandlerHelper.calculatePricing(rentalsToRecalculate);
    }
}