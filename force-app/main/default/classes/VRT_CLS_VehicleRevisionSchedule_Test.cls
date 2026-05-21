@isTest
public class VRT_CLS_VehicleRevisionSchedule_Test {

    @isTest
    static void testScheduleExecution() {
        // Expresión Cron: 10:00 AM cada día
        String cronExp = '0 0 10 * * ?';
        
        Test.startTest();
        // Programamos el job y guardamos el ID que genera
        String jobId = System.schedule('Test de Programacion Vehiculos', cronExp, new VRT_CLS_VehicleRevisionSchedule());
        Test.stopTest();

        // Verificamos que el registro del Job existe en el sistema
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        Assert.areEqual(cronExp, ct.CronExpression, 'La expresión Cron debe coincidir');
        Assert.areEqual(0, ct.TimesTriggered, 'El job no debería haberse ejecutado aún');
    }
}