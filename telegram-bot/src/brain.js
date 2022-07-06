'use strict';

const stringify = require('json-stringify-safe');
const Rx = require('rx-lite');

class Brain {
  constructor({ redisClient, logger }) {
    this._redisClient = redisClient;
    this._logger = logger;
  }

  getUser(userId) {
    return this._getObject('user', userId);
  }

  saveUser(user) {
    return this._saveObject('user', user);
  }

  setUserKey(userId, key, value) {
    return this._setObjectKey('user', userId, key, value);
  }

  getChat(chatId) {
    return this._getObject('chat', chatId);
  }

  saveChat(chat) {
    return this._saveObject('chat', chat);
  }

  setChatKey(chatId, key, value) {
    return this._setObjectKey('chat', chatId, key, value);
  }

  setChatState(chatId, state) {
    return this
      ._runCommand('hset', `chat:${chatId}`, 'state', state)
      .do(
        created => {
          this._logger.debug(`Updated state for chat ${chatId} to ${state}`);
        },
        err => {
          this._logger.error(`Failed to update state for chat ${chatId}: ` +
            err.message);
        }
      );
  }

  setPosterFileId(movieTitle, fileId) {
    return this
      ._runCommand('hset', 'movie_posters', movieTitle, fileId)
      .do(
        created => {
          this._logger.debug(`Set poster file id for movie "${movieTitle}": ` +
            fileId);
        },
        err => {
          this._logger.error(`Failed to set poster file id ${fileId} for ` +
            `movie "${movieTitle}": ${err.message}`);
        }
      );
  }

  getPosterFileId(movieTitle) {
    return this
      ._runCommand('hget', 'movie_posters', movieTitle)
      .do(
        fileId => {
          if (fileId) {
            this._logger.debug('Got poster file id for movie ' +
              `"${movieTitle}": ${fileId}`);
          }
        },
        err => {
          this._logger.error('Failed to get poster file id for movie ' +
            `"${movieTitle}": ${err.message}`);
        }
      );
  }

  _getObject(type, id) {
    return this
      ._runCommand('hgetall', `${type}:${id}`)
      .do(
        object => {
          if (object) {
            this._logger.debug(`Got ${type} ${id}: ${stringify(object)}`);
          }
        },
        err => {
          this._logger.error(`Failed to get ${type} ${id}: ${err.message}`);
        }
      );
  }

  _saveObject(type, object) {
    return this
      ._runCommand('hmset', `${type}:${object.id}`, object)
      .do(
        response => {
          this._logger.debug(`Saved ${type} ${object.id}: ` +
            stringify(object));
        },
        err => {
          this._logger.error(`Failed to save a ${type} ${object.id}: ` +
            err.message);
        }
      );
  }

  _setObjectKey(type, id, key, value) {
    return this
      ._runCommand('hset', `${type}:${id}`, key, value)
      .do(
        created => {
          this._logger.debug(`Set ${key} for ${type} ${id}: ${value}`);
        },
        err => {
          this._logger.error(`Failed to set ${key} for ${type} ${id}: ` +
            err.message);
        }
      );
  }

  _runCommand(command, ...options) {
    return Rx.Observable.fromNodeCallback(
      this._redisClient[command],
      this._redisClient
    )(...options);
  }
}

module.exports = Brain;
