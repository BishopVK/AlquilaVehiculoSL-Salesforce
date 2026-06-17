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

    // Calculate the total rental amount before inserting or updating the rental record
    public static void calculatePricing(List<VRT_Rental__c> rentals) {
        Set<Id> vehicleIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (VRT_Rental__c r : rentals) {
            vehicleIds.add(r.VRT_LKP_Vehicle__c);
            accountIds.add(r.VRT_LKP_Account__c);
        }
        
        // 1. Obtener Vehículos (para saber su tipo)
        Map<Id, VRT_Vehicle__c> vehiclesMap = new Map<Id, VRT_Vehicle__c>(
            [SELECT Id, VRT_SEL_VehicleType__c FROM VRT_Vehicle__c WHERE Id IN :vehicleIds]
        );

        // 2. Obtener Historial de Fidelidad (Cuentas con >= 3 alquileres en 365 días)
        Set<Id> loyalAccounts = new Set<Id>();
        for (AggregateResult ar : [SELECT VRT_LKP_Account__c accId FROM VRT_Rental__c 
                                   WHERE VRT_LKP_Account__c IN :accountIds 
                                   AND VRT_DAT_InitialDate__c = LAST_N_DAYS:365 
                                   GROUP BY VRT_LKP_Account__c HAVING COUNT(Id) >= 3]) {
            loyalAccounts.add((Id)ar.get('accId'));
        }

        // 3. Obtener todas las Tarifas en un Mapa para acceso rápido
        Map<String, Decimal> feeMap = new Map<String, Decimal>();
        for (VRT_Fee__c fee : [SELECT Tipo_de_vehiculo__c, Temporada__c, Precio_por_dia__c
                                FROM VRT_Fee__c]) {
            feeMap.put(fee.Tipo_de_vehiculo__c + '-' + fee.Temporada__c, fee.Precio_por_dia__c);
        }

        // 4. Lógica de cálculo
        for (VRT_Rental__c r : rentals) {
            String season = getTemporada(r.VRT_DAT_InitialDate__c);
            String vehicleType = vehiclesMap.get(r.VRT_LKP_Vehicle__c)?.VRT_SEL_VehicleType__c;
            Decimal dailyRate = feeMap.get(vehicleType + '-' + season);

            if (dailyRate == null) {
                r.addError('No existe tarifa configurada para el tipo ' + vehicleType + ' en temporada ' + season);
                continue;
            }

            Integer days = r.VRT_DAT_InitialDate__c.daysBetween(r.VRT_DAT_FinalDate__c);
            Decimal total = dailyRate * days;
            String info = 'Base: ' + total + '€. ';

            // Aplicar fidelidad
            if (loyalAccounts.contains(r.VRT_LKP_Account__c)) {
                total *= 0.95;
                info += 'Descuento 5% aplicado. ';
            }

            // Aplicar penalización por retraso (VRT_DAT_ReturnDate__c)
            if (r.VRT_DAT_ReturnDate__c != null && r.VRT_DAT_ReturnDate__c > r.VRT_DAT_FinalDate__c) {
                Integer lateDays = r.VRT_DAT_FinalDate__c.daysBetween(r.VRT_DAT_ReturnDate__c);
                Decimal penalty = (dailyRate * 1.25) * lateDays; // 25% extra sobre tarifa
                total += penalty;
                r.VRT_CHK_Penalty__c = true;
                info += 'Penalización 25% por ' + lateDays + ' días extra.';
            }

            r.VRT_DIV_TotalCost__c = total;
            r.VRT_TXT_Cost_Info__c = info;
        }
    }

    private static String getTemporada(Date d) {
        Integer month = d.month();
        if (month == 1 || month == 4 || month == 7 || month == 8 || month == 12) return 'Alta';
        if (month == 2 || month == 5 || month == 6 || month == 9) return 'Media';
        return 'Baja';
    }
}
