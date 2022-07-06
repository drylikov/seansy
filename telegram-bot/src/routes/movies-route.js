'use strict';

const _ = require('lodash');
const { ObjectId } = require('mongodb');
const pluralize = require('pluralize-ru');
const Rx = require('rx-lite');

const BaseRoute = require('../base-route');
const request = require('../request');
const utils = require('../utils');

class MoviesRoute extends BaseRoute {
  constructor(...args) {
    super(...args);

    this.commands = {
      show_menu: {
        pattern: '/movies',
        actions: ({ chat }) => this._showMenu(chat),
        description: 'Showing the movies menu'
      },
      handle_menu: {
        actions: ({ text, chat, user }) => this._handleMenu(text, chat, user),
        description: 'Handling the movies menu'
      },
      movie_search: {
        actions: ({ text, chat, user }) => this
          ._showInfoForMovie(text, chat, user),
        description: 'Searching a movie'
      },
      movie_info: {
        pattern: '/movie([0-9a-fA-F]+)',
        actions: ({ text, chat, user }) => this._handleMenu(text, chat, user),
        description: 'Showing information for a movie'
      }
    };
  }

  getMovieShowtimes(movie, chat) {
    return this._dataInteractor
      .getSortedCinemas({
        city: chat.city,
        movieTitle: movie.title,
        favoriteCinemas: chat.favorite_cinemas || [],
        sortCinemas: chat.sort_cinemas || 'showtimes_count',
        onlyShowFavoriteCinemas: chat.only_show_favorite_cinemas
      })
      .map(movieShowtimes => ({
        movieShowtimes: movieShowtimes,
        count: movieShowtimes
          .reduce((count, cinema) => count + cinema.showtimes.length, 0)
      }))
      .map(result => `В городе ${chat.city} на фильм «${movie.title}» ` +
        `сегодня ${pluralize(result.count, 'сеансов нет', 'есть %d сеанс',
          'есть %d сеанса', 'есть %d сеансов')}.` +
        (result.count > 0
          ? '\n\n' + result.movieShowtimes
              .filter(cinema => cinema.showtimes.length)
              .map(cinema => this.constructor._formatCinemaShowtimes(cinema))
              .join('\n\n')
          : '')
    );
  }

  _showMenu(chat, messageText) {
    return this._dataInteractor
      .getSortedNowPlayingMovies({
        city: chat.city,
        sortMovies: chat.sort_movies
      })
      .map(movies => movies
        .slice(0, Math.min(10, movies.length))
        .map((movie, index) => [`${utils.circledNumber(index + 1)} ` +
          `«${movie.title}» - ` + pluralize(
            movie.showtimes.length,
            'нет сеансов', '%d сеанс', '%d сеанса', '%d сеансов'
          )
        ])
      )
      .flatMap(movies => Rx.Observable.merge(
        this._brain.setChatState(chat.id, 'movies:handle_menu'),
        this._dispatcher.sendMessage({
          chat,
          text: messageText || 'Выбери фильм или интересующую тебя опцию 👇',
          reply_markup: {
            keyboard: [ ['🔍 Все фильмы', '🏠 Меню'] ].concat(movies),
            resize_keyboard: true
          },
          parse_mode: 'Markdown'
        })
      ));
  }

  _handleMenu(text, chat, user) {
    switch (text) {
      case '🔍 Все фильмы':
        return this._showMovieList(chat);
      default:
        return this._showInfoForMovie(text, chat, user);
    }
  }

  _showMovieList(chat) {
    return this._dispatcher
      .sendTypingAction(chat.id)
      .flatMap(response => this._dataInteractor
        .getSortedNowPlayingMovies({
          city: chat.city,
          sortMovies: chat.sort_movies
        })
      )
      .flatMap(movies => Rx.Observable.merge(
        this._brain.setChatState(chat.id, 'movies:movie_search'),
        this._dispatcher.sendMessage({
          chat,
          text: 'Ок, напиши название фильма, который тебе нужен 👇',
          reply_markup: {
            keyboard: [ ['👈 Назад', '🏠 Меню'] ]
              .concat(movies.map(movie => [movie.title])),
            resize_keyboard: true
          }
        })
      ));
  }

  _showInfoForMovie(text, chat, user) {
    if (!text) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, выбери одну из представленных опций ' +
          'или напиши название фильма 👇'
      });
    }

    let observable = this._dataInteractor
      .findMovies(text, chat.city, 1)
      .map(([movie]) => movie);
    let type = 'summary';

    const patterns = [{
      regex: /^Подробнее о фильме «(.+)»$/,
      getter: title => this._dataInteractor.getMovie({ title }),
      type: 'details'
    }, {
      regex: /^. «(.+)» - (?:.*)$/,
      getter: title => this._dataInteractor.getMovie({ title }),
      type: 'summary'
    }, {
      regex: /\/movie([0-9a-fA-F]+)/,
      getter: id => this._dataInteractor.getMovie({ _id: new ObjectId(id) }),
      type: 'summary'
    }];

    for (let pattern of patterns) {
      const match = text.match(pattern.regex);

      if (match && match.length > 1) {
        observable = pattern.getter(match[1]);
        type = pattern.type;
        break;
      }
    }

    return this._dispatcher
      .sendTypingAction(chat.id)
      .flatMap(response => observable)
      .flatMap(movie => {
        if (!movie) {
          return this._dispatcher.sendMessage({
            chat,
            text: 'Не удалось найти такой фильм в репертуаре.'
          });
        }

        switch (type) {
          case 'summary':
            this._analytics
              .trackEvent(user.id, 'Viewed showtimes for movie', {
                movie: movie.title
              })
              .subscribe();

            return this
              ._showMovieSummary(movie, chat)
              .flatMap(response => this.getMovieShowtimes(movie, chat))
              .flatMap(text => this._dispatcher.sendMessage({
                chat,
                text,
                reply_markup: {
                  keyboard: _.compact([
                    movie.synopsis
                      ? [`Подробнее о фильме «${movie.title}»`]
                      : null,
                    ['👈 Назад', '🏠 Меню']
                  ]),
                  resize_keyboard: true
                },
                parse_mode: 'Markdown'
              }));
          case 'details':
            this._analytics
              .trackEvent(user.id, 'Viewed details for movie', {
                movie: movie.title
              })
              .subscribe();

            return this._showMenu(chat, movie.synopsis);
        }

        return Rx.Observable.empty();
      });
  }

  _showMovieSummary(movie, chat) {
    return this._brain
      .getPosterFileId(movie.title)
      .flatMap(fileId => {
        if (fileId) {
          return Rx.Observable.return(_.set(movie, 'poster', fileId));
        } else if (movie.posterUrl) {
          return request(movie.posterUrl)
            .map(poster => _.assign(movie, { poster }));
        } else {
          return Rx.Observable.return(movie);
        }
      })
      .flatMap(movie => {
        return Rx.Observable
          .merge(
            this._brain.setChatState(chat.id, 'movies:handle_menu'),
            movie.poster
              ? this._dispatcher
                  .sendPhoto({
                    chat,
                    photo: movie.poster,
                    caption: this.constructor._movieCaption(movie)
                  })
                  .flatMap(response => this._brain.setPosterFileId(
                    movie.title,
                    response.photo[response.photo.length - 1].file_id
                  ))
              : this._dispatcher.sendMessage({
                chat,
                text: this.constructor._movieCaption(movie)
              })
          )
          .toArray();
      })
      .flatMap(response => {
        const trailer = _.get(movie, 'trailers.youtube[0]');

        if (trailer) {
          return this._dispatcher.sendMessage({ chat, text: trailer });
        } else {
          return Rx.Observable.return(response);
        }
      });
  }

  static _formatCinemaShowtimes(cinema) {
    const title = `*${cinema.name}*` +
      `${cinema.minPrice ? ` — от _${cinema.minPrice}тг_` : ''}`;
    const showtimes = cinema.showtimes.map(showtime => showtime.title);

    return `${title}:\n${showtimes.join(', ')}`;
  }

  static _movieCaption(movie) {
    let starRating, runtime, countries, directors, genres, cast;

    if (movie.averageRating) {
      const stars = Math.ceil(movie.averageRating / 20);

      starRating = ` ${'★'.repeat(stars)}${'☆'.repeat(5 - stars)} ` +
        `(${movie.averageRating}%)`;
    }
    if (movie.runtime) {
      const minutes = movie.runtime % 60;
      const hours = Math.floor(movie.runtime / 60);

      runtime = pluralize(hours, '', '%d час', '%d часа', '%d часов') +
        pluralize(minutes, '', ' %d минута', ' %d минуты', ' %d минут');
    }
    if (movie.countries) {
      countries = movie.countries.join(', ');
    }
    if (_.get(movie, 'crew.directors')) {
      directors = 'реж. ' +
        movie.crew.directors.map(person => person.name).join(', ');
    }
    if (movie.genres) {
      genres = `(${movie.genres.join(', ')})`;
    }
    if (_.get(movie, 'crew.cast')) {
      cast = '\n' + movie.crew.cast
        .slice(0, 3)
        .map((person, index) =>
          index < movie.crew.cast.length && index < 2
            ? person.name
            : '...'
        )
        .join(', ');
    }

    let caption = [
      _.compact([movie.title, movie.year]).join(', ') + (starRating || ''),
      _.compact([movie.originalTitle, runtime]).join(', ') + '\n',
      _.compact([countries, directors]).join(', '),
      genres || '',
      cast || ''
    ].join('\n');

    return caption.length > 200 ? caption.slice(0, 197) + '...' : caption;
  }
}

module.exports = MoviesRoute;
