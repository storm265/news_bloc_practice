import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_bloc_practice/domain/entities/top_headline_entity.dart';
import 'package:todo_bloc_practice/domain/repository/news_remote_repository.dart';
import 'package:todo_bloc_practice/services/connection_status_service.dart';
import 'package:todo_bloc_practice/services/storage_service.dart';

part 'news_event.dart';
part 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> with ConnectionStatusMixin {
  final NewsRemoteRepository _newsRemoteRepository;
  final StorageService _storageService;

  NewsBloc(
      {required NewsRemoteRepository newsRemoteRepository,
      required StorageService storageService})
      : _newsRemoteRepository = newsRemoteRepository,
        _storageService = storageService,
        super(NewsInitialState()) {
    on<NewsEvent>((event, emit) async {
      await _onGetNewsEvent(event, emit);
    });
  }

  Future<void> _onGetNewsEvent(NewsEvent event, Emitter<NewsState> emit) async {
    if (event is GetNewsEvent) {
      emit(NewsLoadingState());
      try {
        if (await isConnected()) {
          final topTitlesModel = await _getTopTitles();
          emit(NewsLoadedState(topHeadlineEntity: topTitlesModel));
        } else {
          emit(const NewsNoNetworkState(error: 'Check internet connection'));
        }
      } catch (e) {
        emit(NewsErrorState(error: e.toString()));
      }
    }
  }

  Future<TopHeadlineEntity> _getTopTitles({
    String countryCode = 'us',
    String category = 'general',
  }) async =>
      await _newsRemoteRepository.getTopHeadlines(
        category: category,
        countryCode: await _storageService.getLocalRegion() ?? countryCode,
      );
}
