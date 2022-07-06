'use strict';

const _ = require('lodash');
const { MongoClient } = require('mongodb');
const config = require('getconfig');
const Mixpanel = require('mixpanel');
const Redis = require('redis');
const Rx = require('rx-lite');
const TelegramBot = require('node-telegram-bot-api');

const Analytics = require('./analytics');
const Brain = require('./brain');
const DataInteractor = require('./data-interactor');
const Dispatcher = require('./dispatcher');
const Logger = require('./logger');

const bot = new TelegramBot(config.telegramBotToken, { polling: true });

Rx.Observable
  .fromNodeCallback(MongoClient.connect)(config.mongodb.url)
  .subscribe(db => {
    const dispatcher = new Dispatcher({
      bot,
      brain: new Brain({
        redisClient: Redis.createClient({ port: config.redis.port }),
        logger: new Logger(config.logLevel, ['redis'])
      }),
      dataInteractor: new DataInteractor({
        db,
        logger: new Logger(config.logLevel, ['mongodb'])
      }),
      analytics: new Analytics({
        mixpanel: config.mixpanelToken
          ? Mixpanel.init(config.mixpanelToken, {
            debug: config.logLevel === 'debug'
          })
          : null,
        logger: new Logger(config.logLevel, ['analytics'])
      }),
      logger: new Logger(config.logLevel, ['dispatcher'])
    });

    const patterns = _(dispatcher.commands)
      .filter((command, commandKey) => !!command.pattern)
      .map((command, commandKey) => ({
        commandKey,
        regex: new RegExp(command.pattern, 'i')
      }));

    bot.on('message', ({ text, location, from, chat }) => dispatcher
      .getChat(chat)
      .flatMap(chat => dispatcher
        .getUser(from, chat)
        .map(user => ({ chat, user }))
      )
      .flatMap(({ chat, user }) => dispatcher.runCommand(
        _
          .chain(patterns)
          .find(pattern => pattern.regex.test(text))
          .get('commandKey')
          .value(),
        { text, location, chat, user }
      ))
      .subscribe()
    );

    bot.on('inline_query', ({ id, from, query }) => dispatcher
      .getUser(from)
      .flatMap(user => dispatcher
        .runInlineQuery({ inlineQueryId: id, user, query })
      )
      .subscribe()
    );

    process.stdin.resume();

    process.on('exit', code => {
      db.close();
    });

    process.on('SIGINT', () => {
      process.exit(0);
    });
  }, err => {
    throw new Error(`Failed to connect to MongoDB: ${err.message}`);
  });
