'use strict';

const _ = require('lodash');
const got = require('got');
const Rx = require('rx-lite');

const Package = require('../package.json');

const request = (url, options = {}) => {
  return Rx.Observable
    .fromPromise(got(url, _(options)
      .omit(['format', 'decoding'])
      .merge({
        headers: {
          'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4',
          'User-Agent': `${Package.name}v${Package.version}`
        },
        encoding: null
      })
      .value()
    ))
    .map(({ body }) => body)
    .catch(err => Rx.Observable
      .throw(new Error(`${url} can't be reached: ${err.message}`))
    );
};

const methods = [
  'get',
  'post',
  'put',
  'patch',
  'head',
  'delete'
];

methods.forEach(method => {
  request[method] = (url, options) => request(
    url, _.assign({}, options, { method })
  );
});

module.exports = request;
