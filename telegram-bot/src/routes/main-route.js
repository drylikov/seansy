'use strict';

const Rx = require('rx-lite');

const BaseRoute = require('../base-route');

class MainRoute extends BaseRoute {
  constructor(...args) {
    super(...args);

    this.key = 'main';
    this.commands = {
      help: {
        pattern: '/help',
        actions: ({ chat, user }) => {
          this._analytics
            .trackEvent(user.id, 'Requested the help message')
            .subscribe();

          return this._dispatcher.sendMessage({
            chat,
            text: `
*Фильмы* - /movies

*Кинотеатры* - /cinemas

*Настройки* - /settings

*Обратная связь* - /feedback

*Помощь* - /help`,
            parse_mode: 'Markdown'
          });
        },
        description: 'Sending a help message'
      },
      show_menu: {
        pattern: '/(?:start|menu)',
        actions: ({ chat }) => this._showMenu(chat),
        description: 'Showing the main menu'
      },
      handle_menu: {
        actions: ({ text, chat, user }) => this._handleMenu(text, chat, user),
        description: 'Handling the main menu'
      }
    };
  }

  _showMenu(chat) {
    return Rx.Observable.merge(
      this._brain.setChatState(chat.id, 'main:handle_menu'),
      this._dispatcher.sendMessage({
        chat,
        text: 'Выбери, пожалуйста, ниже что тебя интересует 👇',
        reply_markup: {
          keyboard: [
            ['🎥 Фильмы'],
            ['🎟 Кинотеатры'],
            ['⚙ Настройки'],
            ['💡 Предложить идею']
          ],
          resize_keyboard: true
        }
      })
    );
  }

  _handleMenu(text, chat, user) {
    const options = { chat, user };

    switch (text) {
      case '🎥 Фильмы':
        return this._dispatcher.runCommand('movies:show_menu', options);
      case '🎟 Кинотеатры':
        return this._dispatcher.runCommand('cinemas:show_menu', options);
      case '⚙ Настройки':
        return this._dispatcher.runCommand('settings:show_menu', options);
      case '💡 Предложить идею':
        return this._dispatcher.runCommand('feedback:get_feedback', options);
      default:
        return this._dispatcher.sendMessage({
          chat,
          text: 'Пожалуйста, выбери одну из представленных опций 👇'
        });
    }
  }
}

module.exports = MainRoute;
