'use strict';

const _ = require('lodash');
require('colors');

const levels = {
  debug: 1,
  info: 2,
  warn: 3,
  error: 4
};

class Logger {
  constructor(level = 'info', tags = []) {
    this.level = levels[level] || levels.info;
    this.tags = tags;

    _(levels).keys().forEach(level => {
      this[level] = (...args) => {
        this.log(level, ...args);
      };
    });
  }

  log(level, ...args) {
    if (!args.length || (levels[level] || levels.info) < this.level) return;

    const tags = _.isArray(args[0]) ? [...this.tags, ...args[0]] : this.tags;
    let message = (_.isArray(args[0]) ? _.drop(args) : args).join(' ');

    message = message
      ? `[${level}] ${tags.length ? `[${tags.join(',')}] ` : ''}` +
        message.replace(new RegExp(`^${level}:?\\s*`, 'ig'), '')
      : null;

    switch (level) {
      case 'error':
        console.error(message.red);
        break;
      case 'warn':
        console.error(message.yellow);
        break;
      case 'debug':
        console.log(message.cyan);
        break;
      default:
        console.log(message);
        break;
    }
  }
}

module.exports = Logger;
