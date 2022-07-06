'use strict';

const _ = require('lodash');
const config = require('getconfig');
const mailgun = require('mailgun-js');
const Rx = require('rx-lite');

const BaseRoute = require('../base-route');

const sender = mailgun({
  apiKey: config.mailgun.apiKey,
  domain: config.mailgun.domain
}).messages();

class FeedbackRoute extends BaseRoute {
  constructor(...args) {
    super(...args);

    this.commands = {
      get_feedback: {
        pattern: '/feedback',
        actions: ({ text, chat }) => this._getFeedback(chat),
        description: 'Getting feedback'
      },
      send_feedback: {
        actions: ({ text, chat, user }) => this._sendFeedback(text, chat, user),
        description: 'Sending feedback'
      }
    };
  }

  _getFeedback(chat) {
    return Rx.Observable.merge(
      this._brain.setChatState(chat.id, 'feedback:send_feedback'),
      this._dispatcher.sendMessage({
        chat,
        text: 'Хочешь улучшить Сеансы? Отправь нам свои идеи!',
        reply_markup: {
          keyboard: [ ['🏠 Меню'] ],
          resize_keyboard: true
        }
      }));
  }

  _sendFeedback(text, chat, user) {
    if (!text) {
      return this._dispatcher.sendMessage({
        chat,
        text: 'Пожалуйста, напиши свое сообщение 👇'
      });
    }

    let name = _.compact([user.first_name, user.last_name]).join(' ');
    if (!name) {
      name = user.username ? `@${user.username}` : `user ${user.id}`;
    } else if (user.username) {
      name += ` (@${user.username})`;
    }

    const data = {
      from: 'SeansyBot <telegram.bot@seansy.kz>',
      to: config.mailgun.toEmail,
      subject: '@SeansyBot Feedback',
      text: `From ${name}:\n\n${text}\n\n—\nUser ID: ${user.id}`
    };

    this._analytics
      .trackEvent(user.id, 'Sent feedback')
      .subscribe();

    return this._dispatcher
      .sendTypingAction(chat.id)
      .flatMap(response => Rx.Observable
        .fromNodeCallback(sender.send, sender)(data)
      )
      .flatMap(body => this._dispatcher.sendMessage({
        chat,
        text: 'Спасибо! Твой отзыв был получен 👍'
      }))
      .flatMap(response => this._dispatcher
        .runCommand('main:show_menu', { chat, user })
      );
  }
}

module.exports = FeedbackRoute;
