'use strict';

const _ = require('lodash');
const geocoder = require('node-geocoder')('google', 'http', { language: 'ru' });
const Rx = require('rx-lite');

const { similarity } = require('../utils');
const BaseRoute = require('../base-route');

const cities = [
  'Астана',
  'Алматы',
  'Актау',
  'Аксу',
  'Атырау',
  'Жанаозен',
  'Караганда',
  'Кокшетау',
  'Костанай',
  'Кызылорда',
  'Павлодар',
  'Петропавловск',
  'Семей',
  'Степногорск',
  'Талдыкорган',
  'Тараз',
  'Темиртау',
  'Уральск',
  'Усть-Каменогорск',
  'Шу',
  'Шымкент',
  'Щучинск',
  'Экибастуз'
];
const sortMoviesOptions = {
  popularity: 'По популярности',
  title: 'По названию',
  rating: 'По рейтингу',
  showtimes_count: 'По количеству сеансов'
};
const sortCinemasOptions = {
  name: 'По названию',
  price: 'По средней цене билета',
  showtimes_count: 'По количеству сеансов'
};

class SettingsRoute extends BaseRoute {
  constructor(...args) {
    super(...args);

    this.commands = {
      show_menu: {
        pattern: '/settings',
        actions: ({ chat }) => this._showMenu(chat),
        description: 'Showing the settings menu'
      },
      handle_menu: {
        actions: ({ text, chat }) => this._handleMenu(text, chat),
        description: 'Handling the settings menu'
      },
      set_city: {
        actions: ({ text, location, chat, user }) => this
          ._setCity(text, location, chat, user)
          .flatMap(city => city
            ? this._dispatcher.runCommand(
                chat.city ? 'settings:show_menu' : 'main:show_menu',
                { chat: _.set(chat, 'city', city), user }
              )
            : Rx.Observable.empty()
          ),
        description: 'Setting city'
      },
      set_sort_movies: {
        actions: ({ text, chat, user }) => this
          ._setSortMovies(text, chat, user),
        description: 'Setting movies sorting preference'
      },
      set_sort_cinemas: {
        actions: ({ text, chat, user }) => this
          ._setSortCinemas(text, chat, user),
        description: 'Setting cinemas sorting preference'
      },
      set_favorite_cinemas: {
        actions: ({ text, chat, user }) => this
          ._setFavoriteCinemas(text, chat, user),
        description: 'Setting favorite cinemas'
      }
    };
  }

  _showMenu(chat) {
    return Rx.Observable.merge(
      this._brain.setChatState(chat.id, 'settings:handle_menu'),
      this._dispatcher.sendMessage({
        chat,
        text: `
Текущие настройки:
🏙 Город: ${chat.city}
🎥 Сортировка фильмов: ${sortMoviesOptions[chat.sort_movies]}
🎟 Сортировка кинотеатров: ${sortCinemasOptions[chat.sort_cinemas]}
⭐️ Любимые кинотеатры: ${chat.favorite_cinemas.length
  ? `\n${chat.favorite_cinemas.map(name => `    • ${name}`).join('\n')}`
  : '0'}
❗️ Показывать только любимые кинотеатры: ${chat.only_show_favorite_cinemas
  ? '✔︎'
  : '✘'}

Чтобы изменить, выбери пункт ниже 👇`,
        reply_markup: {
          keyboard: [
            ['🏙 Город'],
            ['🎥 Сортировка фильмов'],
            ['🎟 Сортировка кинотеатров'],
            ['⭐️ Любимые кинотеатры'],
            ['❗️ Показывать только любимые кинотеатры'],
            ['🏠 Меню']
          ],
          resize_keyboard: true
        }
      })
    );
  }

  _handleMenu(text, chat) {
    switch (text) {
      case '🏙 Город':
        return Rx.Observable.merge(
          this._brain.setChatState(chat.id, 'settings:set_city'),
          this._dispatcher.sendMessage({
            chat,
            text: 'Ок, в каком городе ты живешь? Напиши название города или ' +
              'отправь свое местоположение 👇',
            reply_markup: {
              keyboard: [
                ['👈 Назад', '🏠 Меню']
              ],
              resize_keyboard: true
            }
          })
        );
      case '🎥 Сортировка фильмов':
        const selectedSortMovies = sortMoviesOptions[chat.sort_movies];

        return Rx.Observable.merge(
          this._brain.setChatState(chat.id, 'settings:set_sort_movies'),
          this._dispatcher.sendMessage({
            chat,
            text: 'Пожалуйста, выбери, как ты хочешь сортировать фильмы 👇',
            reply_markup: {
              keyboard: [
                ['👈 Назад', '🏠 Меню']
              ].concat(_
                .values(sortMoviesOptions)
                .map(option => option === selectedSortMovies
                  ? [`${option} ✔︎`]
                  : [option]
                )
              ),
              resize_keyboard: true
            }
          })
        );
      case '🎟 Сортировка кинотеатров':
        const selectedSortCinemas = sortCinemasOptions[chat.sort_cinemas];

        return Rx.Observable.merge(
          this._brain.setChatState(chat.id, 'settings:set_sort_cinemas'),
          this._dispatcher.sendMessage({
            chat,
            text: 'Пожалуйста, выбери, как ты хочешь сортировать кинотеатры 👇',
            reply_markup: {
              keyboard: [ ['👈 Назад', '🏠 Меню'] ].concat(_
                .values(sortCinemasOptions)
                .map(option => option === selectedSortCinemas
                  ? [`${option} ✔︎`]
                  : [option]
                )
              ),
              resize_keyboard: true
            }
          })
        );
      case '⭐️ Любимые кинотеатры':
        return Rx.Observable.merge(
          this._brain.setChatState(chat.id, 'settings:set_favorite_cinemas'),
          this._dispatcher
            .sendTypingAction(chat.id)
            .flatMap(response => this._dataInteractor
              .getSortedCinemas({
                city: chat.city,
                favoriteCinemas: chat.favorite_cinemas,
                sortCinemas: chat.sort_cinemas
              })
              .map(cinemas => cinemas.map(cinema => [cinema.name]))
            )
            .flatMap(cinemas => this._dispatcher.sendMessage({
              chat,
              text: 'Нажми на название кинотеатра, чтобы добавить его в ' +
                'любимые 👇',
              reply_markup: {
                keyboard: [ ['👈 Назад', '🏠 Меню'] ].concat(cinemas),
                resize_keyboard: true
              }
            }))
        );
      case '❗️ Показывать только любимые кинотеатры':
        chat.only_show_favorite_cinemas = !chat.only_show_favorite_cinemas;

        return this._brain
          .setChatKey(
            chat.id,
            'only_show_favorite_cinemas',
            chat.only_show_favorite_cinemas
          )
          .flatMap(() => this._showMenu(chat));
      default:
        return this._dispatcher.sendMessage({
          chat,
          text: 'Пожалуйста, выбери одну из представленных опций 👇'
        });
    }
  }

  _setCity(text, location, chat, user) {
    if (!text && !location) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, напиши название своего города или отправь свое ' +
          'местоположение 👇'
      });
    }

    let observable = Rx.Observable.return(text);

    if (location) {
      observable = Rx.Observable
        .fromNodeCallback(geocoder.reverse, geocoder)({
          lat: location.latitude,
          lon: location.longitude
        })
        .map(response => response && response.length ? response[0].city : null);
    }

    return observable.flatMap(query => {
      const match = _.maxBy(cities, city => similarity(city, query));

      if (match && similarity(match, query) > 0.5) {
        this._analytics
          .trackEvent(user.id, 'Changed city', { city: match })
          .subscribe();

        const observable = chat.type === 'private'
          ? Rx.Observable.zip(
              this._brain.setUserKey(chat.id, 'city', match),
              this._brain.setChatKey(chat.id, 'city', match)
            )
          : this._brain.setChatKey(chat.id, 'city', match);

        return observable
          .flatMap(() => this._dispatcher.sendMessage({
            chat,
            text: `Спасибо. Я запомнил, что ты живешь в городе ${match}.`,
            parse_mode: 'Markdown'
          }))
          .map(() => match);
      }

      return this._dispatcher
        .sendMessage({
          chat,
          text: `
Я не знаю такого города.

Вот список городов, которые я поддерживаю: ${cities.join(', ')}.`
        })
        .map(() => null);
    });
  }

  _setSortMovies(text, chat, user) {
    text = (text || '').replace(' ✔︎', '');

    if (_.values(sortMoviesOptions).indexOf(text) === -1) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, выбери одну из представленных опций 👇'
      });
    }

    const options = _
      .values(sortMoviesOptions)
      .map(option => option === text
        ? [`${option} ✔︎`]
        : [option]
      );
    const sortMovies = _.findKey(sortMoviesOptions, option => option === text);

    this._analytics
      .trackEvent(user.id, 'Changed movie sorting preference', {
        sort_movies: sortMovies
      })
      .subscribe();

    return Rx.Observable.merge(
      this._brain.setChatKey(chat.id, 'sort_movies', sortMovies),
      this._dispatcher.sendMessage({
        chat,
        text: 'Спасибо. Теперь я буду сортировать фильмы ' +
          `${text.toLowerCase()}.`,
        reply_markup: {
          keyboard: [ ['👈 Назад', '🏠 Меню'] ].concat(options),
          resize_keyboard: true
        }
      })
    );
  }

  _setSortCinemas(text, chat, user) {
    text = (text || '').replace(' ✔︎', '');

    if (_.values(sortCinemasOptions).indexOf(text) === -1) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, выбери одну из представленных опций 👇'
      });
    }

    const options = _
      .values(sortCinemasOptions)
      .map(option => option === text
        ? [`${option} ✔︎`]
        : [option]
      );
    const sortCinemas = _
      .findKey(sortCinemasOptions, option => option === text);

    this._analytics
      .trackEvent(user.id, 'Changed cinema sorting preference', {
        sort_cinemas: sortCinemas
      })
      .subscribe();

    return Rx.Observable.merge(
      this._brain.setChatKey(chat.id, 'sort_cinemas', sortCinemas),
      this._dispatcher.sendMessage({
        chat,
        text: 'Спасибо. Теперь я буду сортировать кинотеатры ' +
          `${text.toLowerCase()}.`,
        reply_markup: {
          keyboard: [ ['👈 Назад', '🏠 Меню'] ].concat(options),
          resize_keyboard: true
        }
      })
    );
  }

  _setFavoriteCinemas(text, chat, user) {
    if (!text) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, выбери одну из представленных опций 👇'
      });
    }

    return this._dispatcher
      .sendTypingAction(chat.id)
      .flatMap(response => this._dataInteractor
        .getSortedCinemas({
          city: chat.city,
          favoriteCinemas: chat.favorite_cinemas,
          sortCinemas: chat.sort_cinemas
        })
      )
      .flatMap(cinemas => {
        text = text.replace('⭐️ ', '');

        const foundName = cinemas
          .find(cinema => cinema.name.replace('⭐️ ', '') === text);

        if (!foundName) {
          return this._dispatcher.sendMessage({
            chat,
            text: 'Пожалуйста, выбери одну из представленных опций 👇'
          });
        }

        const index = chat.favorite_cinemas.indexOf(text);

        if (index > -1) {
          chat.favorite_cinemas.splice(index, 1);

          this._analytics
            .trackEvent(user.id, 'Removed a cinema from favorites', {
              removed: text,
              favorite_cinemas: chat.favorite_cinemas
            })
            .subscribe();
        } else {
          chat.favorite_cinemas.push(text);

          this._analytics
            .trackEvent(user.id, 'Added a cinema to favorites', {
              added: text,
              favorite_cinemas: chat.favorite_cinemas
            })
            .subscribe();
        }

        return Rx.Observable.merge(
          this._brain.setChatKey(
            chat.id,
            `favorite_cinemas_${chat.city}`,
            chat.favorite_cinemas.join(', ')
          ),
          this._dataInteractor
            .getSortedCinemas({
              city: chat.city,
              favoriteCinemas: chat.favorite_cinemas,
              sortCinemas: chat.sort_cinemas
            })
            .map(cinemas => cinemas.map(cinema => [cinema.name]))
            .flatMap(cinemas => this._dispatcher.sendMessage({
              chat,
              text: 'Спасибо! ' + (index > -1
                ? 'Я убрал этот кинотеатр из любимых.'
                : 'Я запомнил, что этот кинотеатр один из твоих любимых.'
              ),
              reply_markup: {
                keyboard: [ ['👈 Назад', '🏠 Меню'] ].concat(cinemas),
                resize_keyboard: true
              }
            })
          )
        );
      });
  }
}

module.exports = SettingsRoute;
