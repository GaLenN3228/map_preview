import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:map_flutter/constants/assets.dart';
import 'package:map_flutter/main_bloc/address_bloc/address_bloc.dart';
import 'package:map_flutter/main_bloc/location_bloc/location_bloc.dart';

ValueNotifier<MarkersOsm> removeMarkerOsm = ValueNotifier(MarkersOsm.init);

enum MarkersOsm { init, currentLocation, goLocation, addMarker }

class OsmAppMap extends StatefulWidget {
  const OsmAppMap({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);
  final double? latitude;
  final double? longitude;

  @override
  State<OsmAppMap> createState() => _OsmAppMapState();
}

class _OsmAppMapState extends State<OsmAppMap> {
  late ValueNotifier<MapController> markerController;
  double? lat;
  double? lng;

  @override
  void initState() {
    markerController = ValueNotifier(MapController(
      initMapWithUserPosition: false,
      initPosition: GeoPoint(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      ),
    ));

    removeMarkerOsm.addListener(() async {
      if (removeMarkerOsm.value == MarkersOsm.currentLocation) {
        await moveToCurrentLocation();
      }
    });
    markerController.value.listenerMapSingleTapping.addListener(() async {
      if (markerController.value.listenerMapSingleTapping.value != null) {
        initAddress(markerController.value.listenerMapSingleTapping.value!);
      }
    });
    super.initState();
  }

  void initAddress(GeoPoint map) {
    if (removeMarkerOsm.value == MarkersOsm.currentLocation) {
      removeMarkerOsm.value = MarkersOsm.addMarker;
    } else {
      removeMarkerOsm.value = MarkersOsm.goLocation;
    }
    BlocProvider.of<AddressBloc>(context).add(AddressEvent.initAddress(
      lat: map.latitude,
      lng: map.longitude,
      currentLng: widget.longitude!,
      currentLat: widget.latitude!,
      selectionObject: true,
    ));
  }

  Future<void> moveToCurrentLocation() async {
    markerController.value.removeMarker(
      GeoPoint(
        latitude: lat!,
        longitude: lng!,
      ),
    );
    markerController.value.goToLocation(
      GeoPoint(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      ),
    );
  }

  Future<void> goToLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (lat != null && lng != null && removeMarkerOsm.value != MarkersOsm.addMarker) {
      markerController.value.changeLocationMarker(
        oldLocation: GeoPoint(
          latitude: lat!,
          longitude: lng!,
        ),
        newLocation: GeoPoint(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } else {
      markerController.value.addMarker(
        GeoPoint(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
    markerController.value.goToLocation(
      GeoPoint(
        latitude: latitude,
        longitude: longitude,
      ),
    );
    lat = latitude;
    lng = longitude;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        state.maybeMap(
          orElse: () {},
          map: (osm) async {
            if (osm.moveToCurrentLocation) {
              removeMarkerOsm.value = MarkersOsm.currentLocation;
            }
          },
        );
      },
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) async {
          if (state.setMarkersOsm && removeMarkerOsm.value != MarkersOsm.currentLocation) {
            await goToLocation(
              latitude: state.location!.lat!,
              longitude: state.location!.lng!,
            );
          }
        },
        builder: (context, state) {
          return OSMFlutter(
            controller: markerController.value,
            initZoom: 18,
            stepZoom: 5,
            onMapIsReady: (value) async {
              await markerController.value.enableTracking();
            },
            staticPoints: [
              StaticPositionGeoPoint(
                '1',
                MarkerIcon(
                  assetMarker: AssetMarker(
                    image: AssetImage(AppAssets.images.location),
                  ),
                ),
                [
                  GeoPoint(
                    latitude: widget.latitude!,
                    longitude: widget.longitude!,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}