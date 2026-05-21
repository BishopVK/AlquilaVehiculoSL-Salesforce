public class VRT_CLS_VehicleRevisionSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new VRT_CLS_CheckVehicleRevision());
    }
}