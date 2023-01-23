import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:map_flutter/main_bloc/location_bloc/location_bloc.dart';
import 'package:map_flutter/models/location.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:map_flutter/main_bloc/address_bloc/parts/google_markers.dart';
import 'package:map_flutter/main_bloc/address_bloc/parts/yandex_markers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_flutter/l10n/generated/l10n.dart';

part 'address_bloc.freezed.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc({
    required this.bloc,
  }) : super(const AddressState.address()) {
    on<InitAddress>((event, emit) async {

      try {
        double? distanceInMeters;
        double? bearing;
        final currentLng = bloc.state.maybeCurrentLng();
        final currentLat = bloc.state.maybeCurrentLat();
        emit(state.copyWith(loadingAddress: true));

        List<Placemark> placeMarks = await placemarkFromCoordinates(
          event.lat,
          event.lng,
          localeIdentifier: 'en_US',
        );
        final address =
            '${street(placeMarks.first.street)}${placeMarks.first.administrativeArea}, ${placeMarks.first.subAdministrativeArea}, ${placeMarks.first.country}';
        if (event.selectionObject) {
          emit(state.copyWith(selectedAddress: address));
        } else {
          emit(state.copyWith(
            currentAddress: address,
            selectedAddress: '',
          ));
        }
        if (currentLng != null &&
            currentLat != null &&
            bloc.state.maybeLocationStatus() == PermissionStatus.granted) {
          distanceInMeters = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            event.lat,
            event.lng,
          );

          bearing = Geolocator.bearingBetween(
            currentLat,
            currentLng,
            event.lat,
            event.lng,
          );
        }
        emit(
          state.copyWith(
            loadingAddress: false,
            bearing: bearing,
            distanceInMeters: distanceInMeters,
            setMarkersOsm: event.selectionObject,
            markersGoogle: await googleMarkers(event, emit),
            markersYandex: await yandexMarkers(event, emit),
            location: LocationMap(lat: event.lat, lng: event.lng),
            error: '',
          ),
        );
      } catch (error) {
        emit(state.copyWith(
          error: S.current.dataNoLoaded,
          location: LocationMap(lat: event.lat, lng: event.lng),
        ));
      }
    });
  }

  final LocationBloc bloc;

  String street(String? value) {
    if (value?.contains("+") ?? true) {
      return '';
    }
    return '$value, ';
  }
}

@freezed
class AddressEvent with _$AddressEvent {
  const factory AddressEvent.initAddress({
    required double lat,
    required double lng,
    @Default(false) bool selectionObject,
  }) = InitAddress;
}

@freezed
class AddressState with _$AddressState {
  const factory AddressState.address({
    @Default(false) bool loadingAddress,
    @Default(false) bool setMarkersOsm,
    LocationMap? location,
    Set<Marker>? markersGoogle,
    List<PlacemarkMapObject>? markersYandex,
    String? currentAddress,
    String? selectedAddress,
    double? distanceInMeters,
    double? bearing,
    String? error,
  }) = _Address;
}
