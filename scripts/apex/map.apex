// put(key, value): Agrega un nuevo par clave-valor o actualiza el valor si la clave ya existe. 
// get(key): Recupera el valor asociado a una clave específica; devuelve null si la clave no existe. 
// containsKey(key): Devuelve true si el mapa contiene la clave especificada. 
// keySet(): Devuelve un Set con todas las claves del mapa, útil para iterar o usar en cláusulas IN de SOQL.
// values(): Devuelve una List con todos los valores del mapa. 
// size(): Devuelve el número total de pares clave-valor en el mapa. 
// clear(): Elimina todos los pares clave-valor, dejando el mapa vacío. 
// remove(key): Elimina el par asociado a la clave especificada y devuelve el valor eliminado. 
// clone(): Crea una copia superficial del mapa. 
// deepClone(): Crea una copia profunda, incluyendo registros sObject si el mapa los contiene. 

Map<String, String> contacts = new Map<String, String>();

contacts.put('Daniel', 'daniel@gmail.com');
contacts.put('Char', 'char@gmail.com');
contacts.put('Gaia', 'gaia@gmail.com');
contacts.put('Raio', 'raio@gmail.com');

for (String name : contacts.keySet()) {
    String email = contacts.get(name);
    System.debug('Nombre: ' + name + ', email: ' + email);
}

System.debug('----------');

for (String email : contacts.values()) {
    System.debug(email);
}

System.debug('----------');

if (contacts.containsKey('Gaia')) {
    System.debug('Gaia loló');
} else if (contacts.containsKey('Meiga')) {
    System.debug('Meiga no está en la lista');
}

System.debug('----------');

Map<String, String> invert = new Map<String, String>();

for (String name : contacts.keySet()) {
    invert.put(contacts.get(name), name);
}

for (String email : invert.keySet()) {
    String name = invert.get(email);
    System.debug('Email: ' + email + ', name: ' + name);
}
