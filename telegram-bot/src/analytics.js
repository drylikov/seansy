'use strict';

const _ = require('lodash');
const { expect } = require('code');
const Rx = require('rx-lite');
const stringify = require('json-stringify-safe');

class Analytics {
  constructor({ mixpanel, logger }) {
    this._mixpanel = mixpanel;
    this._logger = logger;
  }

  trackUser(user) {
    if (!this._mixpanel) {
      return Rx.Observable.empty();
    }

    expect(user).to.be.an.object().and.to.include(['id']);

    const people = this._mixpanel.people;

    return Rx.Observable
      .fromNodeCallback(people.set, people)(user.id, {
        $first_name: user.first_name,
        $last_name: user.last_name,
        username: user.username,
        chats: user.chats,
        city: user.city
      })
      .catch(err => {
        this._logger.error(`Failed to track user ${stringify(user)} to ` +
          `Mixpanel: ${err.message}`);

        return Rx.Observable.empty();
      });
  }

  trackEvent(userId, event, properties = {}) {
    if (!this._mixpanel) {
      return Rx.Observable.empty();
    }

    return Rx.Observable
      .fromNodeCallback(this._mixpanel.track, this._mixpanel)(
        event,
        _.set(properties, 'distinct_id', userId)
      )
      .catch(err => {
        this._logger.error(`Failed to track event ${event} for user ` +
          `${userId} to Mixpanel: ${err.message}`);

        return Rx.Observable.empty();
      });
  }
}

module.exports = Analytics;
