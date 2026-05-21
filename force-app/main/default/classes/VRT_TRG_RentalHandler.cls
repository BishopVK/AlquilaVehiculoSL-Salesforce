public class VRT_TRG_RentalHandler {
    public static void onAfterInsert(List<VRT_Rental__c> insertedRental) {
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(insertedRental);
    }
    
    public static void onAfterUpdate(Map<Id, VRT_Rental__c> oldMap, Map<Id, VRT_Rental__c> newMap) {
        VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);
    }
}