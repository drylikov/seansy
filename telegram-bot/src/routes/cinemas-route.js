'use strict';

const pluralize = require('pluralize-ru');
const Rx = require('rx-lite');

const BaseRoute = require('../base-route');

class CinemasRoute extends BaseRoute {
  constructor(...args) {
    super(...args);

    this.commands = {
      show_menu: {
        pattern: '/cinemas',
        actions: ({ chat }) => this._showMenu(chat),
        description: 'Showing the cinemas menu'
      },
      handle_menu: {
        actions: ({ text, chat, user }) => this._handleMenu(text, chat, user),
        description: 'Handling the cinemas menu'
      }
    };
  }

  getCinemaShowtimes(cinema, chat) {
    return this._dataInteractor
      .getSortedNowPlayingMovies({
        city: chat.city,
        cinemaName: cinema.name,
        favoriteCinemas: chat.favorite_cinemas || [],
        sortMovies: chat.sort_movies || 'popularity'
      })
      .map(cinemaShowtimes => ({
        cinemaShowtimes: cinemaShowtimes,
        count: cinemaShowtimes
          .reduce((count, movie) => count + movie.showtimes.length, 0)
      }))
      .map(result => this.constructor._cinemaDescription(cinema) +
        (result.count > 0
          ? '\n\n' + result.cinemaShowtimes
              .filter(movie => movie.showtimes.length)
              .map(movie => this.constructor._formatMovieShowtimes(movie))
              .join('\n\n')
          : '\n\nрасписания пока нет.')
      );
  }

  _showMenu(chat, messageText) {
    return this._dataInteractor
      .getSortedCinemas({
        city: chat.city,
        favoriteCinemas: chat.favorite_cinemas,
        sortCinemas: chat.sort_cinemas,
        onlyShowFavoriteCinemas: chat.only_show_favorite_cinemas
      })
      .map(cinemas => cinemas.map((cinema, index) => [
        `${index + 1}. ${cinema.name} - ` + pluralize(
          cinema.showtimes.length,
          'нет сеансов', '%d сеанс', '%d сеанса', '%d сеансов'
        )
      ]))
      .flatMap(cinemas => Rx.Observable.merge(
        this._brain.setChatState(chat.id, 'cinemas:handle_menu'),
        this._dispatcher.sendMessage({
          chat,
          text: messageText || 'Выбери кинотеатр 👇',
          reply_markup: {
            keyboard: [ ['🏠 Меню'] ].concat(cinemas),
            resize_keyboard: true
          },
          parse_mode: 'Markdown'
        })
      ));
  }

  _handleMenu(text, chat, user) {
    if (text) {
      const match = text.match(/^\d+.(?: ⭐️)? (.+) - (?:.*)$/);
      if (match && match.length > 1) {
        return this._showInfoForCinema(match[1], chat, user);
      }
    }

    return this._dispatcher.sendMessage({
      chat,
      text: 'Пожалуйста, выбери одну из представленных опций 👇'
    });
  }

  _showInfoForCinema(cinemaName, chat, user) {
    return this._dispatcher
      .sendTypingAction(chat.id)
      .flatMap(response => this._dataInteractor.getCinema({ name: cinemaName }))
      .flatMap(cinema => {
        this._analytics
          .trackEvent(user.id, 'Viewed showtimes for cinema', {
            cinema: cinema.name,
            city: chat.city,
            is_favorite: chat.favorite_cinemas.indexOf(cinema.name) > -1
          })
          .subscribe();

        return this.getCinemaShowtimes(cinema, chat);
      })
      .flatMap(text => this._showMenu(chat, text));
  }

  static _cinemaDescription(cinema) {
    let phone;

    if (cinema.phone && cinema.phone.length === 11) {
      phone = `+${cinema.phone.charAt(0) === '8'
        ? '7'
        : cinema.phone.charAt(0)
      } (${cinema.phone.substring(1, 4)}) ` +
        `${cinema.phone.substring(4, 7)}-${cinema.phone.substring(7, 11)}`;
    }

    return [cinema.name, cinema.address, phone].join('\n');
  }

  static _formatMovieShowtimes(movie) {
    const title = `*${movie.title}*` +
      `${movie.minPrice ? ` — от _${movie.minPrice}тг_` : ''}`;
    const showtimes = movie.showtimes.map(showtime => showtime.title);

    return `${title}:\n${showtimes.join(', ')}`;
  }
}

module.exports = CinemasRoute;
