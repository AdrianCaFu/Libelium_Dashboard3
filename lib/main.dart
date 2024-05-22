// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables, unnecessary_null_comparison

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: const Color.fromARGB(
          234, 95, 10, 10), // Color gris para la barra de estado
      statusBarIconBrightness:
          Brightness.light, // Iconos de la barra de estado en color claro
    ));
    return MaterialApp(
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
        textTheme: const TextTheme(
          headline6: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight:
                  FontWeight.bold), // Modifiqué el tamaño de fuente aquí
          bodyText2: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class WeatherInfo {
  final String temperature;
  final String skyState;
  final String maxTemperature; // Nueva propiedad para la temperatura máxima
  final String minTemperature;

  WeatherInfo({
    required this.temperature,
    required this.skyState,
    required this.maxTemperature,
    required this.minTemperature,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: json['temperatura_actual'],
      skyState: json['stateSky']['description'],
      maxTemperature: json['temperaturas']['max'],
      minTemperature: json['temperaturas']['min'],
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<AQIData> aqiData;
  late List<HistoricalO3Data> historicalO3Data = [];
  late List<HistoricalPm10Data> historicalPm10Data = [];
  late List<HistoricalPm25Data> historicalPm25Data = [];

  late Timer timer;
  int _currentIndex = 0;

  // Variables para almacenar el zoom inicial
  double initialVisibleMinimum = 0;
  double initialVisibleMaximum = 6;
  double yMinimum = 0;
  double yMaximum = 50;

  @override
  void initState() {
    super.initState();
    fetchAQIData();
    fetchAQIContO3();
    fetchAQIContPm10();
    fetchAQIContPm25();
    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    timer
        .cancel(); // Cancela el temporizador al salir de la pantalla para evitar fugas de memoria
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchAQIData(); // Llama a fetchAQIData cada minuto
      fetchAQIContO3();
      fetchAQIContPm10();
      fetchAQIContPm25();
    });
  }

  Future<void> fetchAQIData() async {
    final response = await http.get(Uri.parse(
        'https://api.waqi.info/feed/@5186/?token=d56ee6d04d97eb26345c726cf095f87b04d247b2'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final pollutants = jsonData['data']['iaqi'];
      aqiData = pollutants.entries
          .where((entry) => !_filteredContaminants.contains(
              entry.key.toLowerCase())) // Filtrar los contaminantes no deseados
          .map<AQIData>(
              (entry) => AQIData(entry.key, entry.value['v'].toDouble()))
          .toList();
      setState(() {});
    } else {
      throw Exception('Failed to load AQI data');
    }
  }

  Future<void> fetchAQIContO3() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.waqi.info/feed/@5186/?token=d56ee6d04d97eb26345c726cf095f87b04d247b2'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dailyO3 = jsonData['data']['forecast']['daily']['o3'];

        setState(() {
          historicalO3Data = dailyO3.map<HistoricalO3Data>((entry) {
            String fechaFormateada = obtenerFechaFormatoDDMM(entry['day']);
            return HistoricalO3Data(
              fechaFormateada,
              entry['avg'].toDouble(),
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load AQI data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Manejar el error de forma adecuada, como mostrar un mensaje al usuario
    }
  }

  Future<void> fetchAQIContPm10() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.waqi.info/feed/@5186/?token=d56ee6d04d97eb26345c726cf095f87b04d247b2'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dailyPm10 = jsonData['data']['forecast']['daily']['pm10'];

        setState(() {
          historicalPm10Data = dailyPm10.map<HistoricalPm10Data>((entry) {
            String fechaFormateada = obtenerFechaFormatoDDMM(entry['day']);
            return HistoricalPm10Data(
              fechaFormateada,
              entry['avg'].toDouble(),
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load AQI data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Manejar el error de forma adecuada, como mostrar un mensaje al usuario
    }
  }

  Future<void> fetchAQIContPm25() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.waqi.info/feed/@5186/?token=d56ee6d04d97eb26345c726cf095f87b04d247b2'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dailyPm25 = jsonData['data']['forecast']['daily']['pm25'];

        setState(() {
          historicalPm25Data = dailyPm25.map<HistoricalPm25Data>((entry) {
            String fechaFormateada = obtenerFechaFormatoDDMM(entry['day']);
            return HistoricalPm25Data(
              fechaFormateada,
              entry['avg'].toDouble(),
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load AQI data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Manejar el error de forma adecuada, como mostrar un mensaje al usuario
    }
  }

  Future<WeatherInfo> fetchWeatherInfo() async {
    final response = await http.get(Uri.parse(
        'https://www.el-tiempo.net/api/json/v2/provincias/30/municipios/30016'));

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final weatherInfo = WeatherInfo.fromJson(decodedData);

      return weatherInfo;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  double getMaxContaminantValue() {
    if (aqiData.isEmpty) return 0.0;
    return aqiData
        .map((data) => data.value)
        .reduce((maxValue, value) => value > maxValue ? value : maxValue);
  }

  final List<Map<String, dynamic>> dashboardData = [
    {
      'title': 'Libelium Dashboards',
      'description': 'assets/resources/libelium.png'
    },
    {
      'title': 'Calidad del Aire',
    },
    {
      'title': '', // Título dinámico, se establecerá más adelante
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce sodales metus vel felis sagittis, id ultrices dolor commodo. Proin consectetur risus in nunc condimentum, vel luctus turpis fringilla. Quisque congue turpis id purus faucibus, eget ultrices lectus venenatis. Integer dapibus ultrices lorem, a dictum dolor vehicula a. Cras nec leo at sapien tincidunt tempus non eget odio. Ut vitae tellus non turpis fermentum sodales eget eu dolor. Sed volutpat metus nec erat scelerisque, at vestibulum nunc dapibus.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Cambia el color de fondo de la pantalla
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(234, 95, 10, 10), // Color inicial
                Color.fromARGB(213, 153, 40, 40),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                    height: 20.0), // Espacio entre el título y la gráfica
                if (_currentIndex == 2) // Solo para el dashboard 2

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Gráfica combinada de Syncfusion con zoom y desplazamiento
                          SfCartesianChart(
                            title: ChartTitle(
                                text: 'Evolución de O3 agregado por Día',
                                textStyle:
                                    const TextStyle(color: Colors.white)),
                            primaryXAxis: CategoryAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            primaryYAxis: NumericAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePinching:
                                  true, // Habilitar el zoom con pellizco
                              enablePanning:
                                  true, // Habilitar el desplazamiento
                            ),
                            legend: Legend(
                              isVisible: true, // Mostrar la leyenda
                              position: LegendPosition
                                  .bottom, // Posición de la leyenda (abajo de la gráfica)
                              textStyle: const TextStyle(
                                  color: Colors
                                      .white), // Estilo de texto de la leyenda
                              overflowMode: LegendItemOverflowMode
                                  .wrap, // Modo de desbordamiento de los elementos de la leyenda
                              toggleSeriesVisibility: true,

                              // Espaciado alrededor de la leyenda
                            ),
                            series: <ChartSeries>[
                              // Serie de área
                              SplineAreaSeries<HistoricalO3Data, String>(
                                dataSource: historicalO3Data,
                                name: 'Cantidad de O3',
                                legendIconType: LegendIconType.horizontalLine,
                                xValueMapper: (HistoricalO3Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalO3Data data, _) =>
                                    data.maxO3,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    labelAlignment:
                                        ChartDataLabelAlignment.outer,
                                    // Función para personalizar el texto de la leyenda
                                    color: Colors.white),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(
                                        213, 199, 45, 45), // Color inicial
                                    Color.fromARGB(
                                        172, 252, 120, 120), // Color final
                                  ],
                                ),
                              ),
                              // Serie de área detrás de la línea
                              SplineSeries<HistoricalO3Data, String>(
                                dataSource: historicalO3Data,
                                xValueMapper: (HistoricalO3Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalO3Data data, _) =>
                                    data.maxO3,
                                name: 'O3',

                                color: const Color.fromARGB(
                                    197, 248, 248, 248), // Color degradado 1
                                width: 3, // Ancho de la línea principal
                                isVisibleInLegend: false,

                                // Ocultar en la leyenda
                              ),
                              // Serie de líneas

                              ScatterSeries<HistoricalO3Data, String>(
                                dataSource: historicalO3Data,
                                xValueMapper: (HistoricalO3Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalO3Data data, _) =>
                                    data.maxO3,
                                name: 'Max Día',

                                color: const Color.fromARGB(
                                    235, 255, 122, 122), // Color de los puntos
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  color: Color.fromARGB(235, 248, 175, 175),
                                  shape: DataMarkerType.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          SfCartesianChart(
                            title: ChartTitle(
                                text: 'Evolución de PM10 agregado por Día',
                                textStyle:
                                    const TextStyle(color: Colors.white)),
                            primaryXAxis: CategoryAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            primaryYAxis: NumericAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePinching:
                                  true, // Habilitar el zoom con pellizco
                              enablePanning:
                                  true, // Habilitar el desplazamiento
                            ),
                            legend: Legend(
                              isVisible: true, // Mostrar la leyenda
                              position: LegendPosition
                                  .bottom, // Posición de la leyenda (abajo de la gráfica)
                              textStyle: const TextStyle(
                                  color: Colors
                                      .white), // Estilo de texto de la leyenda
                              overflowMode: LegendItemOverflowMode
                                  .wrap, // Modo de desbordamiento de los elementos de la leyenda
                              toggleSeriesVisibility: true,

                              // Espaciado alrededor de la leyenda
                            ),
                            series: <ChartSeries>[
                              // Serie de área
                              SplineAreaSeries<HistoricalPm10Data, String>(
                                dataSource: historicalPm10Data,
                                name: 'Cantidad de PM10',
                                legendIconType: LegendIconType.horizontalLine,
                                xValueMapper: (HistoricalPm10Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm10Data data, _) =>
                                    data.maxPm10,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    labelAlignment:
                                        ChartDataLabelAlignment.outer,
                                    // Función para personalizar el texto de la leyenda
                                    color: Colors.white),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(
                                        213, 199, 45, 45), // Color inicial
                                    Color.fromARGB(
                                        172, 252, 120, 120), // Color final
                                  ],
                                ),
                              ),
                              // Serie de área detrás de la línea
                              SplineSeries<HistoricalPm10Data, String>(
                                dataSource: historicalPm10Data,
                                xValueMapper: (HistoricalPm10Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm10Data data, _) =>
                                    data.maxPm10,
                                name: 'PM10',

                                color: const Color.fromARGB(
                                    197, 248, 248, 248), // Color degradado 1
                                width: 3, // Ancho de la línea principal
                                isVisibleInLegend: false,

                                // Ocultar en la leyenda
                              ),
                              // Serie de líneas

                              ScatterSeries<HistoricalPm10Data, String>(
                                dataSource: historicalPm10Data,
                                xValueMapper: (HistoricalPm10Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm10Data data, _) =>
                                    data.maxPm10,
                                name: 'Max Día',

                                color: const Color.fromARGB(
                                    235, 255, 122, 122), // Color de los puntos
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  color: Color.fromARGB(235, 248, 175, 175),
                                  shape: DataMarkerType.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          SfCartesianChart(
                            title: ChartTitle(
                                text: 'Evolución de PM2.5 agregado por Día',
                                textStyle:
                                    const TextStyle(color: Colors.white)),
                            primaryXAxis: CategoryAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            primaryYAxis: NumericAxis(
                              majorGridLines:
                                  const MajorGridLines(color: Colors.white),
                              axisLine: const AxisLine(color: Colors.white),
                              majorTickLines:
                                  const MajorTickLines(color: Colors.white),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePinching:
                                  true, // Habilitar el zoom con pellizco
                              enablePanning:
                                  true, // Habilitar el desplazamiento
                            ),
                            legend: Legend(
                              isVisible: true, // Mostrar la leyenda
                              position: LegendPosition
                                  .bottom, // Posición de la leyenda (abajo de la gráfica)
                              textStyle: const TextStyle(
                                  color: Colors
                                      .white), // Estilo de texto de la leyenda
                              overflowMode: LegendItemOverflowMode
                                  .wrap, // Modo de desbordamiento de los elementos de la leyenda
                              toggleSeriesVisibility: true,

                              // Espaciado alrededor de la leyenda
                            ),
                            series: <ChartSeries>[
                              // Serie de área
                              SplineAreaSeries<HistoricalPm25Data, String>(
                                dataSource: historicalPm25Data,
                                name: 'Cantidad de PM2.5',
                                legendIconType: LegendIconType.horizontalLine,
                                xValueMapper: (HistoricalPm25Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm25Data data, _) =>
                                    data.maxPm25,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    labelAlignment:
                                        ChartDataLabelAlignment.outer,
                                    // Función para personalizar el texto de la leyenda
                                    color: Colors.white),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(
                                        213, 199, 45, 45), // Color inicial
                                    Color.fromARGB(
                                        172, 252, 120, 120), // Color final
                                  ],
                                ),
                              ),
                              // Serie de área detrás de la línea
                              SplineSeries<HistoricalPm25Data, String>(
                                dataSource: historicalPm25Data,
                                xValueMapper: (HistoricalPm25Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm25Data data, _) =>
                                    data.maxPm25,
                                name: 'PM10',

                                color: const Color.fromARGB(
                                    197, 248, 248, 248), // Color degradado 1
                                width: 3, // Ancho de la línea principal
                                isVisibleInLegend: false,

                                // Ocultar en la leyenda
                              ),
                              // Serie de líneas

                              ScatterSeries<HistoricalPm25Data, String>(
                                dataSource: historicalPm25Data,
                                xValueMapper: (HistoricalPm25Data data, _) =>
                                    data.day,
                                yValueMapper: (HistoricalPm25Data data, _) =>
                                    data.maxPm25,
                                name: 'Max Día',

                                color: const Color.fromARGB(
                                    235, 255, 122, 122), // Color de los puntos
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  color: Color.fromARGB(235, 248, 175, 175),
                                  shape: DataMarkerType.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                        ],
                      ),
                    ),
                  ),
                if (_currentIndex == 1) // Solo para el dashboard 1

                  if (aqiData != null && aqiData.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: getGradientColors(getMaxContaminantValue()),
                          ),
                          border: Border.all(
                            color: Colors.white, // Color del borde
                            width: 2.0, // Ancho del borde
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              '${getMaxContaminantValue()}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Calidad del aire - ${getAirQuality(getMaxContaminantValue())}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                if (_currentIndex == 1) // Solo para el dashboard 1
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Título del Dashboard 1 con un tamaño de fuente mayor
                          const SizedBox(
                              height:
                                  20.0), // Espacio entre el título y el contenido

                          aqiData == null
                              ? const CircularProgressIndicator()
                              : SfCartesianChart(
                                  primaryXAxis: CategoryAxis(
                                    majorGridLines: const MajorGridLines(
                                        color: Colors.white),
                                    axisLine:
                                        const AxisLine(color: Colors.white),
                                    majorTickLines: const MajorTickLines(
                                        color: Colors.white),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  primaryYAxis: NumericAxis(
                                    majorGridLines: const MajorGridLines(
                                        color: Colors.white),
                                    axisLine:
                                        const AxisLine(color: Colors.white),
                                    majorTickLines: const MajorTickLines(
                                        color: Colors.white),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  zoomPanBehavior: ZoomPanBehavior(
                                    enablePinching:
                                        true, // Habilitar el zoom con pellizco
                                    enablePanning:
                                        true, // Habilitar el desplazamiento
                                  ),
                                  legend: Legend(
                                    isVisible: true, // Mostrar la leyenda
                                    position: LegendPosition
                                        .bottom, // Posición de la leyenda (abajo de la gráfica)
                                    textStyle: const TextStyle(
                                        color: Colors
                                            .white), // Estilo de texto de la leyenda
                                    overflowMode: LegendItemOverflowMode
                                        .wrap, // Modo de desbordamiento de los elementos de la leyenda
                                    toggleSeriesVisibility: true,

                                    // Espaciado alrededor de la leyenda
                                  ),
                                  title: ChartTitle(
                                      text: 'Valores de los contaminantes',
                                      textStyle:
                                          const TextStyle(color: Colors.white)),
                                  series: <ChartSeries>[
                                    ColumnSeries<AQIData, String>(
                                      name: 'Valor Actual',

                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      dataSource: aqiData,
                                      xValueMapper: (AQIData data, _) =>
                                          data.contaminant.toUpperCase(),
                                      yValueMapper: (AQIData data, _) =>
                                          data.value,
                                      pointColorMapper: (AQIData data, _) =>
                                          getColorForAQI(data.value),
                                      borderColor: Colors
                                          .white, // Color blanco para el borde de las barras
                                      borderWidth: 2,
                                      dataLabelSettings:
                                          const DataLabelSettings(
                                              isVisible: true,
                                              labelAlignment:
                                                  ChartDataLabelAlignment.outer,
                                              // Función para personalizar el texto de la leyenda
                                              color: Colors.white),
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 20.0),

                          // Descripción del dashboard 1
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      width: 1.5), // Color y ancho del borde
                                  borderRadius: BorderRadius.circular(
                                      15.0), // Borde redondeado opcional
                                ),
                                child: DataTable(
                                  columns: [
                                    const DataColumn(
                                        label: Text(
                                            'Niveles de Calidad del Aire')),
                                  ],
                                  rows: [
                                    _buildDataRow('0 - 50: Buena',
                                        const Color.fromARGB(213, 45, 199, 45)),
                                    _buildDataRow(
                                        '51 - 100: Moderada',
                                        const Color.fromARGB(
                                            213, 199, 199, 45)),
                                    _buildDataRow(
                                        '101 - 150: Regular',
                                        const Color.fromARGB(
                                            212, 233, 161, 29)),
                                    _buildDataRow('151 - 200: Desfavorable',
                                        const Color.fromARGB(211, 219, 55, 14)),
                                    _buildDataRow('201 - 300: Muy Desfavorable',
                                        const Color.fromARGB(216, 9, 84, 196)),
                                    _buildDataRow(
                                      '300+: Peligrosa',
                                      const Color.fromARGB(211, 146, 11, 173),
                                    ),
                                  ],
                                  dataTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_currentIndex == 0) // Solo para el dashboard 0
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Column(
                          children: [
                            // Título del Dashboard 1 con un tamaño de fuente mayor
                            const Text(
                              "Estación de Mompean", // Cambiar el texto del título
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32.0, // Tamaño de fuente aumentado
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 5.0), // Espaciado entre elementos

                            // Texto "Cartagena" debajo del título
                            const Text(
                              "CARTAGENA", // Texto debajo del título
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    15.0, // Tamaño de fuente para el texto debajo del título
                              ),
                            ),

                            const SizedBox(
                                height: 12.0), // Espaciado entre elementos

                            // Texto de temperatura y condición
                            FutureBuilder<WeatherInfo>(
                                future: fetchWeatherInfo(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text(
                                        'Error fetching weather data');
                                  } else if (snapshot.hasData) {
                                    final weatherInfo = snapshot.data!;

                                    if (weatherInfo.temperature != null &&
                                        weatherInfo.skyState != null &&
                                        weatherInfo.maxTemperature != null &&
                                        weatherInfo.minTemperature != null) {
                                      final temperature =
                                          snapshot.data!.temperature;
                                      final skyState = snapshot.data!.skyState;
                                      final maxTemperature =
                                          snapshot.data!.maxTemperature;
                                      final minTemperature =
                                          snapshot.data!.minTemperature;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Texto de temperatura actual y estado del cielo
                                          Text(
                                            "$temperature°",
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: 50.0,
                                            ),
                                          ),

                                          Text(
                                            "$skyState",
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: 20.0,
                                            ),
                                          ),

                                          const SizedBox(
                                              height:
                                                  8.0), // Espaciado entre elementos

                                          // Texto de temperatura máxima
                                          Text(
                                            "Máx.$maxTemperature° Mín.$minTemperature°",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20.0,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const Text(
                                          'Weather data not available');
                                    }
                                  } else {
                                    return const SizedBox
                                        .shrink(); // Mostrar un widget vacío mientras se carga
                                  }
                                }),

                            const SizedBox(
                                height: 35.0), // Espaciado entre elementos

                            Center(
                              child: Container(
                                width: MediaQuery.of(context).size.width *
                                    0.85, // Ancho del contenedor
                                height:
                                    MediaQuery.of(context).size.height * 0.4,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Radio de borde
                                  //border: Border.all(color: Color.fromARGB(255, 252, 250, 250), width: 2.0), // Borde blanco
                                ),

                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: OverflowBox(
                                  child: FlutterMap(
                                    options: MapOptions(
                                      center:
                                          LatLng(37.60339, -0.9749027186018782),
                                      zoom: 17.0,
                                      minZoom: 13.0,
                                      maxZoom: 17.0
                                    ),
                                    nonRotatedChildren: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}@2x?access_token={accessToken}',
                                        additionalOptions: const {
                                          'accessToken':
                                              'pk.eyJ1IjoiYWNhbm8yMyIsImEiOiJjbHc5YWNkNnEwMWM0MmptOHUxdm5seG9iIn0.-fAHnuFckERtf4Yvmn3wjw',
                                          'id':
                                              'mapbox/streets-v12', // Estilo de mapa, puedes cambiarlo según tu preferencia
                                        },
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(37.60339,
                                                -0.9749027186018782), // Coordenadas del marcador
                                            builder: (ctx) => Container(
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 50.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              ),
                            ),

                            const SizedBox(
                                height: 30.0), // Espaciado entre elementos

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Libelium Dashboards",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 18.0,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        10), // Espacio entre el texto y la imagen
                                ClipOval(
                                  child: Image.asset(
                                    'assets/resources/libelium.png',
                                    width: 32.0,
                                    height: 32.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(213, 199, 45, 45), // Color inicial
              Color.fromARGB(172, 252, 120, 120),
            ],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(172, 245, 245, 245),
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedFontSize: 12, // Tamaño de fuente para el ícono seleccionado
          unselectedFontSize:
              10, // Tamaño de fuente para el ícono no seleccionado
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold), // Estilo del texto seleccionado
          unselectedLabelStyle: const TextStyle(
              fontWeight:
                  FontWeight.normal), // Estilo del texto no seleccionado
          unselectedIconTheme:
              const IconThemeData(color: Color.fromARGB(213, 199, 45, 45)),
          unselectedItemColor:
              const Color.fromARGB(213, 199, 45, 45), // Color inicial,
          selectedIconTheme: const IconThemeData(color: Colors.white),
          selectedItemColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home), // Icono para la pantalla de inicio
              label: 'Inicio', // Etiqueta para la pantalla de inicio
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.chartColumn),
              label: 'Calidad del Aire',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.chartLine),
              label: 'Contaminantes',
            ),
          ],
        ),
      ),
    );
  }
}

class SalesData {
  final String year;
  final double sales;

  SalesData(this.year, this.sales);
}

class AQIData {
  final String contaminant;
  final double value;

  AQIData(this.contaminant, this.value);
}

class HistoricalO3Data {
  final String day;
  final double maxO3;

  HistoricalO3Data(this.day, this.maxO3);
}

class HistoricalPm10Data {
  final String day;
  final double maxPm10;

  HistoricalPm10Data(this.day, this.maxPm10);
}

class HistoricalPm25Data {
  final String day;
  final double maxPm25;

  HistoricalPm25Data(this.day, this.maxPm25);
}

DataRow _buildDataRow(String text, Color color) {
  return DataRow(
    cells: [
      DataCell(
        Row(
          children: [
            Container(
              width: 16, // Tamaño del círculo de color
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.white, // Color del borde
                  width: 0.9, // Ancho del borde
                ),
              ),
              margin: const EdgeInsets.only(
                  right: 8), // Espacio entre el círculo y el texto
            ),
            Text(text),
          ],
        ),
      ),
    ],
  );
}

// Lista de contaminantes que deseas filtrar
List<String> _filteredContaminants = ['p', 'h', 't', 'w', 'wg'];

List<Color> getGradientColors(double value) {
  if (value >= 0 && value <= 50) {
    return [
      const Color.fromARGB(213, 45, 199, 45), // Verde
      const Color.fromARGB(172, 120, 252, 120), // Verde claro
    ];
  } else if (value > 51 && value <= 100) {
    return [
      const Color.fromARGB(213, 199, 199, 45), // Amarillo
      const Color.fromARGB(172, 252, 252, 120), // Verde claro
    ];
  } else if (value > 101 && value <= 150) {
    return [
      const Color.fromARGB(212, 233, 161, 29), // Amarillo
      const Color.fromARGB(172, 255, 197, 72), // Amarillo claro
    ];
  } else if (value > 151 && value <= 200) {
    return [
      const Color.fromARGB(211, 219, 55, 14), // Amarillo
      const Color.fromARGB(210, 211, 86, 55), // Amarillo claro
    ];
  } else if (value > 201 && value <= 300) {
    return [
      const Color.fromARGB(216, 9, 84, 196), // Amarillo
      const Color.fromARGB(215, 53, 113, 202), // Amarillo claro
    ];
  } else if (value > 300) {
    return [
      const Color.fromARGB(211, 146, 11, 173), // Amarillo
      const Color.fromARGB(210, 152, 78, 167), // Amarillo claro
    ];
  } else {
    return [
      const Color.fromARGB(213, 199, 45, 45), // Color inicial
      const Color.fromARGB(172, 252, 120, 120), // Color de error
    ];
  }
}

Color getColorForAQI(double aqiValue) {
  if (aqiValue >= 0 && aqiValue <= 50) {
    return const Color.fromARGB(213, 45, 199, 45); // Verde

    // Gradiente verde para AQI de 0 a 50
  } else if (aqiValue > 51 && aqiValue <= 100) {
    return const Color.fromARGB(213, 199, 199, 45); // Amarillo
  } else if (aqiValue > 101 && aqiValue <= 150) {
    return const Color.fromARGB(212, 233, 161, 29); // Amarillo
  } else if (aqiValue > 151 && aqiValue <= 200) {
    return const Color.fromARGB(211, 219, 55, 14); // Amarillo
  } else if (aqiValue > 201 && aqiValue <= 300) {
    return const Color.fromARGB(216, 9, 84, 196); // Amarillo
  } else if (aqiValue > 300) {
    return const Color.fromARGB(211, 146, 11, 173); // Amarillo
  } else {
    return const Color.fromARGB(255, 128, 0, 0); // Rojo oscuro
  }
}

String getAirQuality(double value) {
  if (value >= 0 && value <= 50) {
    return 'Buena';
  } else if (value > 50 && value <= 100) {
    return 'Moderada';
  } else if (value > 100 && value <= 150) {
    return 'Regular';
  } else if (value > 150 && value <= 200) {
    return 'Desfavorable';
  } else if (value > 200 && value <= 300) {
    return 'Muy Desfavorable';
  } else if (value > 300) {
    return 'Peligrosa';
  } else {
    return 'Desconocida';
  }
}

String obtenerNombreMes(int numeroMes) {
  switch (numeroMes) {
    case 1:
      return 'Ene';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Abr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Ago';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dic';
    default:
      return 'Mes Desconocido';
  }
}

String obtenerFechaFormatoDDMM(String fecha) {
  final partesFecha = fecha.split('-');
  final dia = partesFecha[2];
  final numeroMes = int.parse(partesFecha[1]);
  final nombreMes = obtenerNombreMes(numeroMes);
  return '$dia $nombreMes';
}
