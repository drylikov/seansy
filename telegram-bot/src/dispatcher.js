'use strict';

const _ = require('lodash');
const { expect } = require('code');
const crypto = require('crypto');
const path = require('path');
const removeMarkdown = require('remove-markdown');
const requireAll = require('require-all');
const Rx = require('rx-lite');
const stringify = require('json-stringify-safe');

const { similarity } = require('./utils');

class Dispatcher {
  constructor({ bot, brain, dataInteractor, analytics, logger }) {
    this._bot = bot;
    this._brain = brain;
    this._dataInteractor = dataInteractor;
    this._analytics = analytics;
    this._logger = logger;

    this._routes = requireAll({
      dirname: path.join(__dirname, './routes'),
      map: name => name.replace(/(.*)-route$/, '$1'),
      resolve: Route => new Route({
        brain,
        dataInteractor,
        analytics,
        dispatcher: this
      })
    });

    this.commands = _.transform(
      this._routes,
      (commands, route, routeKey) => {
        _.forEach(route.commands, (command, commandKey) => {
          commands[`${routeKey}:${commandKey}`] = command;
        });
      },
      {}
    );
  }

  runCommand(commandKey, { text, location, chat, user }) {
    if (!chat.city) {
      if (chat.state !== 'settings:set_city') {
        return Rx.Observable.merge(
          this._brain.setChatState(chat.id, 'settings:set_city'),
          this.sendMessage({
            chat,
            text: 'Для начала скажи, пожалуйста, в каком городе ты живешь?'
          })
        );
      }

      commandKey = chat.state;
    } else {
      commandKey = commandKey || chat.state;
      if (text === '🏠 Меню' || !commandKey) {
        commandKey = 'main:show_menu';
      } else if (text === '👈 Назад' && chat.state) {
        const [route] = chat.state.split(':');
        commandKey = `${route}:show_menu`;
      }
    }

    const command = this.commands[commandKey];

    this._logger.info(`${command.description} for chat ` +
      stringify(_.pick(chat, [
        'id', 'type', 'title', 'username', 'first_name', 'last_name'
      ])));

    return command
      .actions({ text, location, chat, user })
      .catch(err => {
        this._logger.error(`Failed to process command ${commandKey}: ` +
          err.message);

        return this.sendMessage({
          chat,
          text: 'Что-то пошло не так. Пожалуйста, попробуйте еще раз чуть ' +
            'позже.'
        });
      })
      .catch(() => Rx.Observable.empty());
  }

  runInlineQuery({ inlineQueryId, user, query }) {
    if (!query || !query.length) {
      return Rx.Observable.empty();
    }

    if (!user.city) {
      return this.answerInlineQuery({
        inlineQueryId,
        results: [],
        is_personal: true,
        switch_pm_text: 'Укажи свой город',
        switch_pm_parameter: '/start'
      });
    }

    return Rx.Observable
      .zip(
        this._dataInteractor
          .findMovies(query, user.city)
          .flatMap(movies => Rx.Observable
            .merge(movies.map(movie => this._routes.movies
              .getMovieShowtimes(movie, { city: user.city })
              .map(text => ({
                text,
                movie: _.pick(movie, ['_id', 'title', 'posterUrl'])
              }))
            ))
          )
          .toArray(),
        this._dataInteractor
          .findCinemas(query, user.city)
          .flatMap(cinemas => Rx.Observable
            .merge(cinemas.map(cinema => this._routes.cinemas
              .getCinemaShowtimes(cinema, { city: user.city })
              .map(text => ({
                text,
                cinema: _.pick(cinema, ['name', 'photoUrl'])
              }))
            ))
          )
          .toArray()
      )
      .map(([movieResults, cinemaResults]) => {
        movieResults = movieResults.map(result => ({
          title: result.movie.title,
          input_message_content: {
            message_text: result.text,
            parse_mode: 'Markdown'
          },
          thumb_url: result.movie.posterUrl
        }));
        cinemaResults = cinemaResults.map(result => ({
          title: result.cinema.name,
          input_message_content: {
            message_text: result.text,
            parse_mode: 'Markdown'
          },
          thumb_url: result.cinema.photoUrl
        }));

        this._logger.info(`Answering an inline query "${query}" ${user.id}: ` +
          `${movieResults.length} movie results, ` +
          `${cinemaResults.length} cinema results`);

        if (movieResults.length || cinemaResults.length) {
          this._analytics
            .trackEvent(user.id, 'Sent an inline query', {
              query,
              total_results: movieResults.length + cinemaResults.length,
              movie_results: movieResults.length,
              cinema_results: cinemaResults.length
            })
            .subscribe();
        }

        return movieResults
          .concat(cinemaResults)
          .map(result => _.assign(result, {
            type: 'article',
            id: crypto
              .createHash('md5')
              .update(`${result.title}${user.id}${user.city}`, 'utf8')
              .digest('hex'),
            description: removeMarkdown(
              result.input_message_content.message_text
            ),
            score: similarity(result.title, query)
          }))
          .sort((a, b) => b.score - a.score)
          .map(result => _.omit(result, ['score']));
      })
      .flatMap(results => results.length
        ? this.answerInlineQuery({ inlineQueryId, results, is_personal: true })
        : Rx.Observable.empty()
      );
  }

  getUser(user, chat) {
    return this._brain
      .getUser(user.id)
      .flatMap(savedUser => {
        if (savedUser) {
          savedUser.last_seen_at = new Date().getTime();
          let observable = this._brain
            .setUserKey(user.id, 'last_seen_at', savedUser.last_seen_at);

          if (chat) {
            const chats = savedUser.chats ? savedUser.chats.split(', ') : [];
            if (chats.indexOf(String(chat.id)) === -1) {
              savedUser.chats = chats.concat(chat.id).join(', ');

              observable = observable.flatMap(() => this._brain
                .setUserKey(user.id, 'chats', savedUser.chats)
              );
            }
            if (chat.city && !savedUser.city) {
              savedUser.city = chat.city;

              observable = observable.flatMap(() => this._brain
                .setUserKey(user.id, 'city', savedUser.city)
              );
            }
          }

          return observable.map(() => savedUser);
        }

        user.chats = String((chat || {}).id || '');
        if (chat && chat.city) {
          user.city = chat.city;
        }
        user.created_at = new Date().getTime();
        user.last_seen_at = new Date().getTime();

        return this._brain.saveUser(user).map(() => user);
      })
      .map(user => {
        if (user) {
          user.chats = user.chats ? user.chats.split(', ') : [];
        }

        return user;
      })
      .doOnNext(user => {
        this._analytics.trackUser(user).subscribe();
      });
  }

  getChat(chat) {
    return this._brain
      .getChat(chat.id)
      .flatMap(savedChat => {
        if (savedChat) {
          return Rx.Observable.return(savedChat);
        }

        chat.sort_movies = 'popularity';
        chat.sort_cinemas = 'showtimes_count';
        chat.only_show_favorite_cinemas = false;
        chat.created_at = new Date().getTime();

        return this._brain.saveChat(chat).map(() => chat);
      })
      .map(chat => {
        if (chat) {
          chat.favorite_cinemas = [];
          if (chat.city && chat[`favorite_cinemas_${chat.city}`]) {
            chat.favorite_cinemas = chat[`favorite_cinemas_${chat.city}`]
              .split(', ');
          }
          chat.only_show_favorite_cinemas =
            chat.only_show_favorite_cinemas === 'true';
        }

        return chat;
      });
  }

  sendMessage(message) {
    expect(message).to.be.an.object().and.to.include(['chat', 'text']);

    const chatId = message.chat.id;
    const text = message.text;
    const options = _.omit(message, ['chat', 'text']);
    if (message.chat.type.indexOf('group') > -1) {
      if (!options.reply_markup) {
        options.reply_markup = {};
      }

      options.reply_markup.force_reply = true;
    }

    return Rx.Observable
      .fromPromise(this._bot.sendMessage(chatId, text, options))
      .do(
        response => {
          this._logger.debug(`Sent a message to chat ${chatId}`);
        },
        err => {
          this._logger.error('Failed to send a message to chat ' +
            `${chatId}: ${err.message}`);
        }
      );
  }

  sendPhoto(message) {
    expect(message).to.be.an.object().and.to.include(['chat', 'photo']);

    const chatId = message.chat.id;
    const photo = message.photo;
    const options = _.omit(message, ['chat', 'photo']);

    return Rx.Observable
      .fromPromise(this._bot.sendPhoto(chatId, photo, options))
      .do(
        response => {
          this._logger.debug(`Sent a photo to chat ${chatId}`);
        },
        err => {
          this._logger.error('Failed to send a photo to chat ' +
            `${chatId}: ${err.message}`);
        }
      );
  }

  sendTypingAction(chatId) {
    return Rx.Observable
      .fromPromise(this._bot.sendChatAction(chatId, 'typing'))
      .do(
        response => {
          this._logger.debug(`Sent a typing action to chat ${chatId}`);
        },
        err => {
          this._logger.error('Failed to send a typing action to chat ' +
            `${chatId}: ${err.message}`);
        }
      );
  }

  answerInlineQuery(answer) {
    expect(answer).to.be.an.object().and.to
      .include(['inlineQueryId', 'results']);

    const inlineQueryId = answer.inlineQueryId;
    const results = answer.results;
    const options = _.omit(answer, ['inlineQueryId', 'results']);

    return Rx.Observable
      .fromPromise(this._bot.answerInlineQuery(inlineQueryId, results, options))
      .do(
        response => {
          this._logger.debug(`Answered inline query ${inlineQueryId}`);
        },
        err => {
          this._logger.error('Failed to answer inline query ' +
            `${inlineQueryId}: ${err.message}`);
        }
      );
  }
}

module.exports = Dispatcher;
