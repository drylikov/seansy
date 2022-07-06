'use strict';

const _ = require('lodash');
const Rx = require('rx-lite');
const stringify = require('json-stringify-safe');

class Collection {
  constructor({ db, key, logger }) {
    this._collection = db.collection(key);
    this._key = key;
    this._logger = logger;
  }

  aggregate(stages) {
    const cursor = this._collection.aggregate(stages);

    return Rx.Observable
      .fromNodeCallback(cursor.toArray, cursor)()
      .do(
        results => {
          this._logger.debug(`Got ${results.length} results for ` +
            `${this._key} aggregation`);
        },
        err => {
          this._logger.error(`Failed to aggregate ${this._key}: ` +
            err.message);
        }
      );
  }

  find(filter) {
    const cursor = this._collection.find(filter);

    return Rx.Observable
      .fromNodeCallback(cursor.toArray, cursor)()
      .do(
        results => {
          this._logger.debug(`Got ${results.length} results for ` +
            `${this._key} find with filter ${stringify(filter)}: `);
        },
        err => {
          this._logger.error(`Failed to find ${this._key} with filter ` +
            `${stringify(filter)}: ${err.message}`);
        }
      );
  }

  findOne(filter) {
    return Rx.Observable
      .fromNodeCallback(this._collection.findOne, this._collection)(filter)
      .do(
        result => {
          this._logger.debug(`Got result for ${this._key} find with filter ` +
            `${stringify(filter)}: ` +
            stringify(_.pick(result, ['_id', 'name', 'title'])));
        },
        err => {
          this._logger.error(`Failed to find ${this._key} with filter ` +
            `${stringify(filter)}: ${err.message}`);
        }
      );
  }
}

module.exports = Collection;
