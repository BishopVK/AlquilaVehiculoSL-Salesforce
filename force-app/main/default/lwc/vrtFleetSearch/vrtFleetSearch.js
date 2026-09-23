import { LightningElement, wire } from 'lwc';

// Invocación de métodos de la clase Apex Controladora
import getFleetSearched from '@salesforce/apex/VRT_LWC_FleetSearchController.getFleetSearched';

// Definición de columnas con la API exacta de campos del objeto VRT_Vehicle__c
const COLUMNS = [
    {
        label: 'Nombre',
        fieldName: 'vehicleUrl',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            },
            target: '_self' }
    },
    { label: 'Marca', fieldName: 'VRT_TXT_Brand__c', type: 'text' },
    { label: 'Modelo', fieldName: 'VRT_TXT_Model__c', type: 'text' },
    { label: 'Matrícula', fieldName: 'VRT_TXT_LicensePlate__c', type: 'text' },
    { label: 'Tipo', fieldName: 'VRT_SEL_VehicleType__c', type: 'text' },
    { label: 'Estado', fieldName: 'VRT_SEL_Status__c', type: 'text' }
];

export default class VrtFleetSearch extends LightningElement {
    searchTerm = '';
    searchTermInput = '';
    delayTimeout;
    vehicles = []
    error;

    columns = COLUMNS;

    // Almacena la respuesta raw de @wire para refrescar con refreshApex()
    wiredFleetResult;

    // Conexión reactiva con Apex: '$searchTerm' hace que se reejecute cada vez que tecleas
    @wire(getFleetSearched, { searchTerm: '$searchTerm' })
    wiredFleet({ data, error }) {
        if (data) {
            // Creamos una propiedad 'vehicleUrl' en cada registro para convertir el nombre en un enlace
            this.vehicles = data.map(vehicle => {
                return {
                    ...vehicle,
                    vehicleUrl: `/lightning/r/VRT_Vehicle__c/${vehicle.Id}/view`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.vehicles = [];
        }
    }

    // Actualiza la variable cuando el usuario escribe en la caja de texto
    handleInputChange(event) {
        this.searchTermInput = event.target.value;

        clearTimeout(this.delayTimeout);

        this.delayTimeout = setTimeout(() => {
            this.searchTerm = this.searchTermInput;
        }, 300);
    }

    // Getters para controlar qué mensajes o tablas se muestran en la plantilla
    get hasResults() {
        return this.vehicles && this.vehicles.length > 0;
    }

    get isSearchEntered() {
        return this.searchTerm && this.searchTerm.trim().length >= 2;
    }
}