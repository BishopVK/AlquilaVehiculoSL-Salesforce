trigger VRT_TRG_Rental on VRT_Rental__c (after insert, after update, before insert, before update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        VRT_TRG_RentalHandler.onAfterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        VRT_TRG_RentalHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }

    // Calculate the total rental amount before inserting or updating the rental record
    if (Trigger.isBefore && Trigger.isInsert) {
        VRT_TRG_RentalHandler.onBeforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        VRT_TRG_RentalHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}