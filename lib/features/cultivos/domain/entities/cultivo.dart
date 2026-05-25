import 'package:equatable/equatable.dart';

class Cultivo extends Equatable {
  final String id;
  final String nombre;
  final int altitudMin;
  final int altitudMax;
  final double tempOptima;
  final double lluviaRequerida;
  final String cicloCosecha;
  final List<String> consejosLocales;
  final bool activo;

  const Cultivo({
    required this.id,
    required this.nombre,
    required this.altitudMin,
    required this.altitudMax,
    required this.tempOptima,
    required this.lluviaRequerida,
    required this.cicloCosecha,
    required this.consejosLocales,
    this.activo = false,
  });

  Cultivo copyWith({bool? activo}) {
    return Cultivo(
      id: id,
      nombre: nombre,
      altitudMin: altitudMin,
      altitudMax: altitudMax,
      tempOptima: tempOptima,
      lluviaRequerida: lluviaRequerida,
      cicloCosecha: cicloCosecha,
      consejosLocales: consejosLocales,
      activo: activo ?? this.activo,
    );
  }

  @override
  List<Object?> get props => [id, nombre, activo];
}

final List<Cultivo> cultivosList = [
  Cultivo(
    id: 'papa',
    nombre: 'Papa',
    altitudMin: 2000,
    altitudMax: 3500,
    tempOptima: 12.0,
    lluviaRequerida: 800.0,
    cicloCosecha: '5-7 meses',
    consejosLocales: [
      'Aporcar bien para evitar que la luz dañe el tubérculo.',
      'Controlar la Gota con productos sistémicos en días nublados.',
      'Rotar con leguminosas (arveja o haba) para nutrir el suelo.',
      'En Nariño, sembrar preferiblemente en "menguante" según tradición.',
    ],
  ),
  Cultivo(
    id: 'mora',
    nombre: 'Mora',
    altitudMin: 1800,
    altitudMax: 2800,
    tempOptima: 16.0,
    lluviaRequerida: 1200.0,
    cicloCosecha: 'Cosecha continua',
    consejosLocales: [
      'Podar ramas "macho" que no cargan fruto.',
      'Fertilizar con potasio para mejorar el dulzor y color.',
      'Recoger frutos maduros cada 4 días para evitar botrytis.',
      'En la zona de La Unión, se recomienda tutorado en espaldera.',
    ],
  ),
  Cultivo(
    id: 'cafe',
    nombre: 'Café',
    altitudMin: 1200,
    altitudMax: 2100,
    tempOptima: 20.0,
    lluviaRequerida: 1500.0,
    cicloCosecha: 'Anual (Mitaca en oct-dic)',
    consejosLocales: [
      'Controlar la broca con trampas artesanales.',
      'Mantener sombra regulada con guamos o plátano.',
      'Hacer beneficio ecológico para no contaminar quebradas.',
      'Nariño tiene cafés especiales por su alta luminosidad.',
    ],
  ),
  Cultivo(
    id: 'maiz',
    nombre: 'Maíz',
    altitudMin: 1000,
    altitudMax: 2800,
    tempOptima: 22.0,
    lluviaRequerida: 600.0,
    cicloCosecha: '6-8 meses',
    consejosLocales: [
      'Sembrar con frijol voluble para fijar nitrógeno.',
      'Cuidar el cultivo de loros en el primer mes de siembra.',
      'Almacenar en "soberado" para evitar el gorgojo.',
      'Usa variedades criollas como el maíz capio de Nariño.',
    ],
  ),
  Cultivo(
    id: 'frijol',
    nombre: 'Frijol',
    altitudMin: 1500,
    altitudMax: 2600,
    tempOptima: 18.0,
    lluviaRequerida: 500.0,
    cicloCosecha: '4-5 meses',
    consejosLocales: [
      'No sembrar en terrenos muy húmedos o se pudre la raíz.',
      'Controlar la mosca blanca en los primeros 20 días.',
      'Cosechar cuando la vaina esté "seca como papel".',
      'El frijol cargamanto es el más buscado en el mercado local.',
    ],
  ),
  Cultivo(
    id: 'lulo',
    nombre: 'Lulo',
    altitudMin: 1600,
    altitudMax: 2400,
    tempOptima: 19.0,
    lluviaRequerida: 1800.0,
    cicloCosecha: 'Cosecha continua',
    consejosLocales: [
      'Es muy exigente en agua, use riego en verano.',
      'Cuidado con el pasador del fruto, use trampas de luz.',
      'Fertilizar con materia orgánica descompuesta.',
      'En Nariño, el lulo "la selva" es el más resistente.',
    ],
  ),
  Cultivo(
    id: 'tomate',
    nombre: 'Tomate',
    altitudMin: 1400,
    altitudMax: 2200,
    tempOptima: 21.0,
    lluviaRequerida: 700.0,
    cicloCosecha: '4-5 meses',
    consejosLocales: [
      'Requiere tutorado fuerte para que no toque el suelo.',
      'Regar a la base, no moje las hojas para evitar hongos.',
      'Quitar chupones laterales para que el fruto crezca grande.',
      'El tomate chonto es ideal para el clima de Sandoná.',
    ],
  ),
  Cultivo(
    id: 'cebolla',
    nombre: 'Cebolla',
    altitudMin: 2200,
    altitudMax: 3200,
    tempOptima: 14.0,
    lluviaRequerida: 900.0,
    cicloCosecha: '4 meses',
    consejosLocales: [
      'Sembrar en eras elevadas para drenar el exceso de lluvia.',
      'Controlar el "trips" que seca las puntas de las hojas.',
      'Usar abonos altos en fósforo al inicio.',
      'En Ipiales se produce cebolla junca de excelente calidad.',
    ],
  ),
  Cultivo(
    id: 'ajo',
    nombre: 'Ajo',
    altitudMin: 2300,
    altitudMax: 3000,
    tempOptima: 13.0,
    lluviaRequerida: 600.0,
    cicloCosecha: '6-7 meses',
    consejosLocales: [
      'Sembrar los dientes más grandes para obtener mejores bulbos.',
      'No regar 15 días antes de la cosecha.',
      'Secar al sol colgado en manojos.',
      'El ajo nariñense es famoso por su fuerte aroma y sabor.',
    ],
  ),
  Cultivo(
    id: 'arveja',
    nombre: 'Arveja',
    altitudMin: 2000,
    altitudMax: 2900,
    tempOptima: 15.0,
    lluviaRequerida: 700.0,
    cicloCosecha: '4 meses',
    consejosLocales: [
      'Usar espalderas de hilo para que la planta trepe bien.',
      'Cosechar cuando el grano esté tierno pero lleno.',
      'Atacar el "cenizillo" apenas aparezcan manchas blancas.',
      'Variedades como la "andina" son muy productivas aquí.',
    ],
  ),
  Cultivo(
    id: 'habichuela',
    nombre: 'Habichuela',
    altitudMin: 1200,
    altitudMax: 2000,
    tempOptima: 22.0,
    lluviaRequerida: 800.0,
    cicloCosecha: '2-3 meses',
    consejosLocales: [
      'Cosechar diariamente para estimular nueva floración.',
      'Requiere suelos sueltos y con buena materia orgánica.',
      'Mantener libre de malezas en el primer mes.',
      'Ideal para diversificar ingresos por su ciclo corto.',
    ],
  ),
  Cultivo(
    id: 'frutilla',
    nombre: 'Frutilla',
    altitudMin: 1800,
    altitudMax: 2600,
    tempOptima: 17.0,
    lluviaRequerida: 1000.0,
    cicloCosecha: 'Continua',
    consejosLocales: [
      'Usar acolchado plástico (mulch) para proteger el fruto.',
      'Quitar estolones si quiere frutos más grandes.',
      'Cuidado con las babosas en épocas de mucha lluvia.',
      'En la sabana de Túquerres se dan fresas muy dulces.',
    ],
  ),
];
