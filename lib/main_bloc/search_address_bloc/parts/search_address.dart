part of '../search_address_bloc.dart';

extension SearchAddress on SearchAddressBloc {
  Future<void> _searchAddress(
    _SearchAddress event,
    Emitter<SearchAddressState> emit,
  ) async {
    if (event.search.isEmpty) {
      emit(state.copyWith(places: []));
      return;
    }
    emit(state.copyWith(loadingAddress: true));

    List<PlaceSearch> placesSearch = [];
    final responsePlaces = await api.getAddressesGoogle(
      event.search,
      '${bloc.state.maybeCurrentLat()},${bloc.state.maybeCurrentLng()}',
    );

    if (responsePlaces.error != null) {
      emit(state.copyWith(
        error: S.current.dataNoLoaded,
        loadingAddress: false,
      ));
      return;
    }
    for (PlaceSearch item in responsePlaces.data ?? []) {
      if (item.placeId != null) {
        final responsePlace = await api.getPlaceGoogle(item.placeId!);

        if (responsePlace.error != null) {
          emit(state.copyWith(
            error: S.current.dataNoLoaded,
            loadingAddress: false,
          ));
          return;
        }
        placesSearch.add(PlaceSearch(
          placeId: item.placeId,
          address: item.address,
          place: responsePlace.data,
        ));
      }
    }
    emit(state.copyWith(
      places: placesSearch,
      loadingAddress: false,
      error: Constants.empty,
    ));
  }
}
