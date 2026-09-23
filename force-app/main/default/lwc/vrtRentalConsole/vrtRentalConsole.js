import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Invocación de métodos de la clase Apex Controladora
import getActiveRentals from '@salesforce/apex/VRT_LWC_RentalConsoleController.getActiveRentals';
import simulateRentalPrice from '@salesforce/apex/VRT_LWC_RentalConsoleController.simulateRentalPrice';
import createRental from '@salesforce/apex/VRT_LWC_RentalConsoleController.createRental';

// Definición de columnas con la API exacta de campos del objeto VRT_Rental__c
const COLUMNS = [
    { label: 'Número de Alquiler', fieldName: 'Name', type: 'text' },
    { label: 'Vehículo', fieldName: 'vehicleName', type: 'text' },
    { label: 'Fecha Inicio', fieldName: 'VRT_DAT_InitialDate__c', type: 'date-local' },
    { label: 'Fecha Fin', fieldName: 'VRT_DAT_FinalDate__c', type: 'date-local' },
    { label: 'Estado', fieldName: 'VRT_SEL_Status__c', type: 'text' },
    { label: 'Coste Total', fieldName: 'VRT_DIV_TotalCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR' } }
];

export default class VrtRentalConsole extends LightningElement {
    // ID de la Cuenta inyectado automáticamente por la plataforma
    @api recordId;

    // Variables de estado para el formulario
    vehicleId = '';
    startDate = '';
    endDate = '';
    simulatedPrice = null;
    searchKey = '';
    paymentStatus = 'Pagado';

    columns = COLUMNS;

    @track activeRentals = [];
    @track filteredRentals = [];
    
    // Almacena la respuesta raw de @wire para refrescar con refreshApex()
    wiredRentalsResult;

    // 1. Configura qué campos se muestran en el menú desplegable de resultados
    vehicleDisplayInfo = {
        primaryField: 'Name',
        additionalFields: ['VRT_TXT_SearchKey__c']
    };

    // 2. Configura por qué campos buscar cuando el usuario escribe en el input (máximo 1 campo adicional)
    vehicleMatchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [
            { fieldPath: 'VRT_TXT_SearchKey__c'}
        ]
    };

    // ============================
    // 1. LECTURA DE BBDD VÍA @WIRE
    // ============================
    @wire(getActiveRentals, { accountId: '$recordId' })
    wiredRentals(result) {
        this.wiredRentalsResult = result;
        const { data, error } = result;

        if (data) {
            // "Aplanamos" el nombre del vehículo (relación Lookup) para mostrarlo en el datatable
            this.activeRentals = data.map(rental => ({
                ...rental,
                vehicleName: rental.VRT_LKP_Vehicle__r ? rental.VRT_LKP_Vehicle__r.Name : ''
            }));
            this.applyFilter();
        } else if (error) {
            this.showNotification('Error al cargar la lista', this.reduceErrors(error), 'error');
        }
    }

    get simulatedPriceFormatted() {
        return this.simulatedPrice !== null ? `${this.simulatedPrice.toFixed(2)} €` : '';
    }

    // Handlers de los inputs del formulario
    handleVehicleChange(event) {
        // event.detail.recordId contiene el ID de 18 caracteres seleccionado en el buscador
        this.vehicleId = event.detail.recordId;
        // this.vehicleId = event.target.value;
    }
    handleStartDateChange(event) { this.startDate = event.target.value; }
    handleEndDateChange(event) { this.endDate = event.target.value; }

    // Manejo de la caja de búsqueda/filtro
    handleSearchKeyChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFilter();
    }

    applyFilter() {
        if (this.searchKey) {
            this.filteredRentals = this.activeRentals.filter(rental => 
                (rental.vehicleName && rental.vehicleName.toLowerCase().includes(this.searchKey)) ||
                (rental.VRT_SEL_Status__c && rental.VRT_SEL_Status__c.toLowerCase().includes(this.searchKey)) ||
                (rental.Name && rental.Name.toLowerCase().includes(this.searchKey))
            );
        } else {
            this.filteredRentals = [...this.activeRentals];
        }
    }

    get paymentOptions() {
        return [
            { label: 'Pagado', value: 'Pagado' },
            { label: 'Pendiente', value: 'Pendiente' },
            { label: 'Atrasado', value: 'Atrasado' }
        ];
    }

    handlePaymentStatusChange(event) {
        this.paymentStatus = event.target.value;
    }

    // =========================================================================
    // 2. SIMULACIÓN DE PRECIO EN APEX (Llamada Imperativa)
    // =========================================================================
    handleSimulatePrice() {
        if (!this.vehicleId || !this.startDate || !this.endDate) {
            this.showNotification('Formulario incompleto', 'Por favor, indica el vehículo y el rango de fechas.', 'warning');
            return;
        }

        if (this.startDate >= this.endDate) {
            this.showNotification('Fechas incorrectas', 'Por favor, asegurate de que la fecha de fin sea posterior a la fecha de inicio.', 'warning');
            return;
        }

        simulateRentalPrice({
            vehicleId: this.vehicleId,
            accountId: this.recordId,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(result => {
            this.simulatedPrice = result;
            this.showNotification('Simulación lista', 'Coste estimado calculado según las tarifas vigentes.', 'info');
        })
        .catch(error => {
            this.showNotification('Error en la simulación', this.reduceErrors(error), 'error');
        });
    }

    // =========================================================================
    // 3. CREACIÓN DEL REGISTRO EN BBDD (Llamada Imperativa)
    // =========================================================================
    handleCreateRental() {
        if (!this.vehicleId || !this.startDate || !this.endDate) {
            this.showNotification('Formulario incompleto', 'Faltan campos obligatorios para crear el alquiler.', 'warning');
            return;
        }

        // Construcción del objeto SObject con los API Names de Salesforce
        const newRentalRecord = {
            VRT_LKP_Vehicle__c: this.vehicleId,
            VRT_LKP_Account__c: this.recordId,
            VRT_DAT_InitialDate__c: this.startDate,
            VRT_DAT_FinalDate__c: this.endDate,
            VRT_SEL_Status__c: 'Reservado',
            VRT_SEL_PaymentStatus__c: this.paymentStatus
        };

        createRental({ newRental: newRentalRecord })
        .then(result => {
            this.showNotification('Alquiler creado', `El registro ${result.Name || ''} se guardó con éxito.`, 'success');
            
            // Limpiar los campos tras un guardado exitoso
            this.vehicleId = '';
            this.startDate = '';
            this.endDate = '';
            this.simulatedPrice = null;

            // Solicitar a Salesforce refrescar la caché de @wire para actualizar la tabla
            return refreshApex(this.wiredRentalsResult);
        })
        .catch(error => {
            // Captura de errores de lógica de negocio (por ejemplo, addError() de triggers por solapamiento)
            this.showNotification('Error al guardar', this.reduceErrors(error), 'error');
        });
    }

    // =========================================================================
    // UTILIDADES DE INTERFAZ Y MANEJO DE ERRORES DE PLATAFORMA
    // =========================================================================
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // Extrae y desempaqueta los mensajes de excepción nativos de Apex (Triggers/AuraHandledException)
    reduceErrors(errors) {
        if (!errors) return 'Error desconocido';
        if (typeof errors === 'string') return errors;
        if (Array.isArray(errors.body)) return errors.body.map(e => e.message).join(', ');
        if (errors.body && typeof errors.body.message === 'string') return errors.body.message;
        return errors.message || 'Error en la operación';
    }
}