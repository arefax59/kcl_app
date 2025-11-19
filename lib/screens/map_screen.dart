import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<Map<String, dynamic>> _stopPoints = [];
  List<Map<String, dynamic>> _optimizedRoute = [];
  List<LatLng> _routePolyline = []; // Points de la route réelle
  static const int maxStopPoints = 90;
  bool _isLoadingLocation = true;
  TimeOfDay? _startTime;
  int? _endPointIndex;
  bool _isOptimizing = false;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadStopPoints().then((_) {
      // Calculer la route après le chargement des points
      if (_stopPoints.isNotEmpty) {
        _calculateRoute();
      }
    });
  }

  Future<void> _saveStopPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_stopPoints.map((point) {
        final pointCopy = Map<String, dynamic>.from(point);
        // Convertir LatLng en Map pour JSON
        final latLng = pointCopy['point'] as LatLng;
        pointCopy['point'] = {'lat': latLng.latitude, 'lng': latLng.longitude};
        return pointCopy;
      }).toList());
      await prefs.setString('optim_stop_points', jsonData);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _loadStopPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('optim_stop_points');
      if (jsonData != null && jsonData.isNotEmpty) {
        final decoded = jsonDecode(jsonData) as List<dynamic>;
        setState(() {
          _stopPoints = decoded.map((point) {
            final pointMap = Map<String, dynamic>.from(point);
            // Convertir Map en LatLng
            final pointData = pointMap['point'] as Map<String, dynamic>;
            pointMap['point'] = LatLng(pointData['lat'] as double, pointData['lng'] as double);
            return pointMap;
          }).toList();
        });
      }
    } catch (e) {
      print('Erreur lors du chargement: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les services de localisation sont désactivés.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _userLocation = const LatLng(48.8566, 2.3522);
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Les permissions de localisation sont refusées.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
            _userLocation = const LatLng(48.8566, 2.3522);
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les permissions de localisation sont définitivement refusées.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _userLocation = const LatLng(48.8566, 2.3522);
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController.move(_userLocation!, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la récupération de la position: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        _userLocation = const LatLng(48.8566, 2.3522);
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_stopPoints.length >= maxStopPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez atteint la limite de $maxStopPoints points d\'arrêt.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showAddStopPointDialog(point);
  }

  Future<LatLng?> _searchAddress(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        _mapController.move(latLng, 15.0);
        return latLng;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adresse non trouvée: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
  }

  Future<void> _showAddStopPointDialog(LatLng? point) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    LatLng? selectedPoint = point;
    String? scheduleType; // 'predefined', 'custom', 'rdv', 'none'
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;
    List<Map<String, TimeOfDay>>? rdvRanges = []; // [{start: TimeOfDay, end: TimeOfDay}]
    String? predefinedTime;

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ajouter un point d\'arrêt',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du point d\'arrêt *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse complète',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: 123 Rue Example, Paris',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          if (addressController.text.trim().isNotEmpty) {
                            final latLng = await _searchAddress(addressController.text);
                            if (latLng != null) {
                              setDialogState(() {
                                selectedPoint = latLng;
                              });
                            }
                          }
                        },
                        tooltip: 'Rechercher l\'adresse',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Horaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Aucun horaire'),
                    value: 'none',
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setDialogState(() {
                        scheduleType = value;
                        openingTime = null;
                        closingTime = null;
                        rdvRanges = [];
                        predefinedTime = null;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Horaires prédéfinis'),
                    value: 'predefined',
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setDialogState(() {
                        scheduleType = value;
                        openingTime = null;
                        closingTime = null;
                        rdvRanges = [];
                        predefinedTime = '9h';
                      });
                    },
                  ),
                  if (scheduleType == 'predefined') ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['9h', '10h', '13h', '18h'].map((time) {
                        return ChoiceChip(
                          label: Text(time),
                          selected: predefinedTime == time,
                          onSelected: (selected) {
                            setDialogState(() {
                              predefinedTime = selected ? time : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  RadioListTile<String>(
                    title: const Text('Heure d\'ouverture / fermeture'),
                    value: 'custom',
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setDialogState(() {
                        scheduleType = value;
                        rdvRanges = [];
                        predefinedTime = null;
                        if (openingTime == null) openingTime = TimeOfDay.now();
                        if (closingTime == null) closingTime = TimeOfDay.now();
                      });
                    },
                  ),
                  if (scheduleType == 'custom') ...[
                    ListTile(
                      title: const Text('Heure d\'ouverture'),
                      trailing: Text(
                        openingTime != null
                            ? '${openingTime!.hour.toString().padLeft(2, '0')}:${openingTime!.minute.toString().padLeft(2, '0')}'
                            : 'Non définie',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: openingTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            openingTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Heure de fermeture'),
                      trailing: Text(
                        closingTime != null
                            ? '${closingTime!.hour.toString().padLeft(2, '0')}:${closingTime!.minute.toString().padLeft(2, '0')}'
                            : 'Non définie',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: closingTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            closingTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                  RadioListTile<String>(
                    title: const Text('Rendez-vous'),
                    value: 'rdv',
                    groupValue: scheduleType,
                    onChanged: (value) {
                      setDialogState(() {
                        scheduleType = value;
                        openingTime = null;
                        closingTime = null;
                        predefinedTime = null;
                        if (rdvRanges!.isEmpty) {
                          rdvRanges = [
                            {'start': TimeOfDay.now(), 'end': TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: TimeOfDay.now().minute)}
                          ];
                        }
                      });
                    },
                  ),
                  if (scheduleType == 'rdv') ...[
                    ...rdvRanges!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final range = entry.value;
                      final start = range['start'] as TimeOfDay;
                      final end = range['end'] as TimeOfDay;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('Rendez-vous ${index + 1}'),
                          subtitle: Text(
                            '${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                rdvRanges!.removeAt(index);
                              });
                            },
                          ),
                          onTap: () async {
                            // Modifier le début
                            final pickedStart = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (pickedStart != null) {
                              setDialogState(() {
                                rdvRanges![index]['start'] = pickedStart;
                                // Ajuster la fin si nécessaire
                                if (end.hour < pickedStart.hour || 
                                    (end.hour == pickedStart.hour && end.minute <= pickedStart.minute)) {
                                  rdvRanges![index]['end'] = TimeOfDay(
                                    hour: (pickedStart.hour + 2) % 24,
                                    minute: pickedStart.minute,
                                  );
                                }
                              });
                            }
                          },
                          onLongPress: () async {
                            // Modifier la fin
                            final pickedEnd = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (pickedEnd != null) {
                              setDialogState(() {
                                rdvRanges![index]['end'] = pickedEnd;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un rendez-vous'),
                      onPressed: () {
                        setDialogState(() {
                          final now = TimeOfDay.now();
                          rdvRanges!.add({
                            'start': now,
                            'end': TimeOfDay(hour: (now.hour + 2) % 24, minute: now.minute)
                          });
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez entrer un nom pour le point d\'arrêt'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (selectedPoint == null && addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez entrer une adresse ou cliquer sur la carte'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      // Si une adresse a été saisie mais pas de point sélectionné, rechercher
      if (selectedPoint == null && addressController.text.trim().isNotEmpty) {
        final latLng = await _searchAddress(addressController.text);
        if (latLng != null) {
          selectedPoint = latLng;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de trouver l\'adresse. Veuillez cliquer sur la carte.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (selectedPoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un point sur la carte ou entrer une adresse.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> scheduleData = {};
      if (scheduleType == 'predefined' && predefinedTime != null) {
        scheduleData = {'type': 'predefined', 'time': predefinedTime};
      } else if (scheduleType == 'custom') {
        scheduleData = {
          'type': 'custom',
          'openingTime': openingTime != null
              ? '${openingTime!.hour.toString().padLeft(2, '0')}:${openingTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'closingTime': closingTime != null
              ? '${closingTime!.hour.toString().padLeft(2, '0')}:${closingTime!.minute.toString().padLeft(2, '0')}'
              : null,
        };
      } else if (scheduleType == 'rdv' && rdvRanges != null && rdvRanges!.isNotEmpty) {
        scheduleData = {
          'type': 'rdv',
          'ranges': rdvRanges!.map((range) {
            final start = range['start'] as TimeOfDay;
            final end = range['end'] as TimeOfDay;
            return '${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')}-${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}';
          }).toList(),
        };
      }

      setState(() {
        _stopPoints.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': nameController.text.trim(),
          'address': addressController.text.trim(),
          'point': selectedPoint,
          'schedule': scheduleData,
        });
      });
      await _saveStopPoints();
      _calculateRoute();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Point d\'arrêt ajouté (${_stopPoints.length}/$maxStopPoints)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeStopPoint(int id) async {
    setState(() {
      _stopPoints.removeWhere((point) => point['id'] == id);
      _optimizedRoute.clear();
    });
    await _saveStopPoints();
    _calculateRoute();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Point d\'arrêt supprimé'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editStopPoint(Map<String, dynamic> stopPoint) {
    _showAddStopPointDialog(stopPoint['point'] as LatLng);
    _removeStopPoint(stopPoint['id'] as int);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  Future<List<LatLng>> _getRouteFromOSRM(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return [];

    try {
      // Construire l'URL OSRM avec les waypoints
      // Format: lng,lat;lng,lat;...
      final coordinates = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = 'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors du calcul de la route');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['code'] == 'Ok' && data['routes'] != null) {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final geometry = route['geometry'] as Map<String, dynamic>;
            final coordinatesList = geometry['coordinates'] as List;
            
            // Convertir les coordonnées GeoJSON [lng, lat] en LatLng [lat, lng]
            return coordinatesList.map((coord) {
              final coords = coord as List;
              return LatLng(coords[1] as double, coords[0] as double);
            }).toList();
          }
        } else {
          print('OSRM Error: ${data['code']} - ${data['message']}');
        }
      } else {
        print('OSRM HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du calcul de la route OSRM: $e');
    }
    
    // En cas d'erreur, retourner une ligne droite entre les waypoints
    return waypoints;
  }

  Future<void> _calculateRoute() async {
    if (_userLocation == null) return;
    
    final pointsToRoute = _optimizedRoute.isNotEmpty ? _optimizedRoute : _stopPoints;
    if (pointsToRoute.isEmpty) {
      setState(() {
        _routePolyline = [];
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Construire la liste des waypoints : position utilisateur + tous les points
      List<LatLng> waypoints = [_userLocation!];
      waypoints.addAll(pointsToRoute.map((p) => p['point'] as LatLng));

      // Obtenir la route depuis OSRM
      final route = await _getRouteFromOSRM(waypoints);
      
      setState(() {
        _routePolyline = route;
        _isLoadingRoute = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du calcul de la route: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _optimizeRoute() {
    if (_stopPoints.isEmpty || _userLocation == null) return [];

    List<Map<String, dynamic>> route = [];
    List<Map<String, dynamic>> remaining = List.from(_stopPoints);
    
    // Point de départ : toujours la position de l'utilisateur
    LatLng currentPoint = _userLocation!;
    
    // Si un point de fin est défini, le retirer de la liste
    Map<String, dynamic>? endPoint;
    if (_endPointIndex != null && _endPointIndex! < _stopPoints.length) {
      endPoint = _stopPoints[_endPointIndex!];
      remaining.removeWhere((p) => p['id'] == endPoint!['id']);
    }

    // Algorithme de plus proche voisin avec contraintes temporelles
    while (remaining.isNotEmpty) {
      Map<String, dynamic>? nearest;
      double minDistance = double.infinity;

      for (var point in remaining) {
        final distance = _calculateDistance(currentPoint, point['point'] as LatLng);
        
        // Vérifier les contraintes temporelles
        bool canVisit = _canVisitAtTime(point, route.length);
        
        if (distance < minDistance && canVisit) {
          minDistance = distance;
          nearest = point;
        }
      }

      // Si aucun point ne peut être visité à cause des contraintes, prendre le plus proche
      if (nearest == null && remaining.isNotEmpty) {
        nearest = remaining.reduce((a, b) {
          final distA = _calculateDistance(currentPoint, a['point'] as LatLng);
          final distB = _calculateDistance(currentPoint, b['point'] as LatLng);
          return distA < distB ? a : b;
        });
      }

      if (nearest != null) {
        route.add(nearest);
        remaining.remove(nearest);
        currentPoint = nearest['point'] as LatLng;
      }
    }

    // Ajouter le point de fin à la fin si défini
    if (endPoint != null) {
      route.add(endPoint);
    }

    return route;
  }

  bool _canVisitAtTime(Map<String, dynamic> point, int routeIndex) {
    // Logique simplifiée pour vérifier si on peut visiter le point
    // En fonction des horaires définis
    final schedule = point['schedule'] as Map<String, dynamic>?;
    if (schedule == null || schedule.isEmpty) return true;

    // Pour l'instant, on accepte tous les points
    // Une implémentation complète nécessiterait de calculer le temps de trajet
    return true;
  }

  Future<void> _optimizeRouteAction() async {
    if (_stopPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins 2 points pour optimiser l\'itinéraire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Demander l'heure de départ
    if (_startTime == null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time == null) return;
      setState(() {
        _startTime = time;
      });
    }

    setState(() {
      _isOptimizing = true;
    });

    // Simuler un calcul (dans une vraie app, cela prendrait du temps)
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _optimizedRoute = _optimizeRoute();
      _isOptimizing = false;
    });

    // Calculer la route réelle après optimisation
    await _calculateRoute();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Itinéraire optimisé avec ${_optimizedRoute.length} points'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optim - Carte'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _generateTestPoints,
            tooltip: 'Générer 15 points de test (Bapaume)',
          ),
          if (_stopPoints.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.list),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_stopPoints.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () => _showStopPointsList(),
              tooltip: 'Liste des points d\'arrêt',
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Centrer sur ma position',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(48.8566, 2.3522),
              initialZoom: _userLocation != null ? 15.0 : 10.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kcl.app',
                maxZoom: 19,
              ),
              // Tracé de l'itinéraire suivant les routes réelles
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 5.0,
                      color: _optimizedRoute.isNotEmpty ? Colors.green : Colors.blue,
                    ),
                  ],
                )
              // Tracé de secours (ligne droite) si la route n'est pas encore calculée
              else if ((_optimizedRoute.isNotEmpty ? _optimizedRoute : _stopPoints).isNotEmpty && 
                       _userLocation != null && 
                       !_isLoadingRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        _userLocation!,
                        ...(_optimizedRoute.isNotEmpty ? _optimizedRoute : _stopPoints)
                            .map((p) => p['point'] as LatLng)
                            .toList(),
                      ],
                      strokeWidth: 3.0,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ...(_optimizedRoute.isNotEmpty ? _optimizedRoute : _stopPoints).asMap().entries.map((entry) {
                    final index = entry.key;
                    final stopPoint = entry.value;
                    final point = stopPoint['point'] as LatLng;
                    final isOptimized = _optimizedRoute.isNotEmpty;
                    return Marker(
                      point: point,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showStopPointDetails(stopPoint),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isOptimized ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_isLoadingRoute)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Calcul de la route...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: safeAreaBottom + 80, // Espace pour éviter le menu système
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () {
                    if (_stopPoints.length >= maxStopPoints) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vous avez atteint la limite de $maxStopPoints points d\'arrêt.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _showAddStopPointDialog(null);
                  },
                  child: const Icon(Icons.add_location),
                  tooltip: 'Ajouter un point d\'arrêt',
                ),
                if (_stopPoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'optimize',
                    onPressed: _isOptimizing ? null : _optimizeRouteAction,
                    backgroundColor: Colors.green,
                    child: _isOptimizing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.route),
                    tooltip: 'Optimiser l\'itinéraire',
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'clear',
                    onPressed: () => _confirmClearAll(),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.clear_all),
                    tooltip: 'Supprimer tous les points',
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Points: ${_stopPoints.length}/$maxStopPoints',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (_startTime != null)
                    Text(
                      'Départ: ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _stopPoints.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _showRouteSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Paramètres'),
              backgroundColor: const Color(0xFF1E3A8A),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _showRouteSettings() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Paramètres d\'itinéraire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Heure d\'arrivée au premier point'),
                trailing: Text(
                  _startTime != null
                      ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                      : 'Non définie',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setDialogState(() {
                      _startTime = time;
                    });
                  }
                },
              ),
              const Divider(),
              const Text('Point de fin (optionnel)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _endPointIndex,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner le point de fin',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Aucun'),
                  ),
                  ..._stopPoints.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text('${entry.key + 1}. ${entry.value['name']}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _endPointIndex = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _optimizeRouteAction();
              },
              child: const Text('Optimiser'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopPointsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Points d\'arrêt'),
        content: SizedBox(
          width: double.maxFinite,
          child: _stopPoints.isEmpty
              ? const Center(child: Text('Aucun point d\'arrêt ajouté'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _stopPoints.length,
                  itemBuilder: (context, index) {
                    final stopPoint = _stopPoints[index];
                    final schedule = stopPoint['schedule'] as Map<String, dynamic>?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(stopPoint['name'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stopPoint['address'] != null && (stopPoint['address'] as String).isNotEmpty)
                            Text('📍 ${stopPoint['address']}'),
                          if (schedule != null && schedule.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _buildScheduleText(schedule),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pop(context);
                              _editStopPoint(stopPoint);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeStopPoint(stopPoint['id'] as int);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleText(Map<String, dynamic> schedule) {
    final type = schedule['type'] as String?;
    if (type == 'predefined') {
      return Text('🕐 ${schedule['time']}');
    } else if (type == 'custom') {
      final opening = schedule['openingTime'] as String?;
      final closing = schedule['closingTime'] as String?;
      return Text('🕐 ${opening ?? '?'} - ${closing ?? '?'}');
    } else if (type == 'rdv') {
      final ranges = schedule['ranges'] as List<dynamic>?;
      if (ranges != null && ranges.isNotEmpty) {
        return Text('📅 RDV: ${ranges.join(', ')}');
      }
    }
    return const SizedBox.shrink();
  }

  void _generateTestPoints() async {
    // Coordonnées de Bapaume (50.1042, 2.8536)
    const double bapaumeLat = 50.1042;
    const double bapaumeLng = 2.8536;
    const double radius = 0.05; // Rayon d'environ 5km

    List<Map<String, dynamic>> testPoints = [];

    // Générer 15 points autour de Bapaume
    for (int i = 0; i < 15; i++) {
      // Générer des coordonnées dans un cercle autour de Bapaume
      final distance = radius * (0.3 + (i % 4) * 0.2); // Distance variable
      final lat = bapaumeLat + (distance * (i.isEven ? 1 : -1) * (1 + (i % 3) * 0.3));
      final lng = bapaumeLng + (distance * (i.isOdd ? 1 : -1) * (1 + (i % 2) * 0.4));

      testPoints.add({
        'id': DateTime.now().millisecondsSinceEpoch + i,
        'name': 'Point ${i + 1} - Bapaume',
        'address': 'Adresse test ${i + 1}, Bapaume',
        'point': LatLng(lat, lng),
        'schedule': i % 3 == 0
            ? {'type': 'predefined', 'time': ['9h', '10h', '13h', '18h'][i % 4]}
            : i % 3 == 1
                ? {
                    'type': 'custom',
                    'openingTime': '${8 + (i % 4)}:00',
                    'closingTime': '${12 + (i % 4)}:00',
                  }
                : {
                    'type': 'rdv',
                    'ranges': [
                      '${9 + (i % 3)}h${(i % 2) * 30}0-${11 + (i % 3)}h${(i % 2) * 30}0',
                      '${14 + (i % 2)}h00-${16 + (i % 2)}h00',
                    ],
                  },
      });
    }

    setState(() {
      _stopPoints = testPoints;
      _optimizedRoute.clear();
    });
    await _saveStopPoints();
    
    // Calculer la route pour les points de test
    await _calculateRoute();

    // Centrer la carte sur Bapaume
    _mapController.move(const LatLng(bapaumeLat, bapaumeLng), 12.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('15 points de test générés autour de Bapaume'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showStopPointDetails(Map<String, dynamic> stopPoint) {
    final schedule = stopPoint['schedule'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stopPoint['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stopPoint['address'] != null && (stopPoint['address'] as String).isNotEmpty)
              Text('📍 ${stopPoint['address']}'),
            const SizedBox(height: 8),
            if (schedule != null && schedule.isNotEmpty)
              _buildScheduleText(schedule),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editStopPoint(stopPoint);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les points'),
        content: const Text('Êtes-vous sûr de vouloir supprimer tous les points d\'arrêt ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
            setState(() {
              _stopPoints.clear();
              _optimizedRoute.clear();
              _routePolyline.clear();
              _startTime = null;
              _endPointIndex = null;
            });
            await _saveStopPoints();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tous les points d\'arrêt ont été supprimés'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
