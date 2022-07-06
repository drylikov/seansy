'use strict';

class Route {
  constructor({ dispatcher, brain, dataInteractor, analytics }) {
    this._dispatcher = dispatcher;
    this._brain = brain;
    this._dataInteractor = dataInteractor;
    this._analytics = analytics;
  }
}

module.exports = Route;
