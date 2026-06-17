trigger VRT_TRG_UpdateVRTFeeName on VRT_Fee__c (before insert, before update) {
    VRT_CLS_UpdateFeeName.UpdateFeeName(Trigger.new);
}