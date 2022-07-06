'use strict';

const _ = require('lodash');
const { expect } = require('code');
const moment = require('moment-timezone');
const Rx = require('rx-lite');

const { similarity } = require('./utils');
const Collection = require('./collection');

class DataInteractor {
  constructor({ db, logger }) {
    this._db = db;
    this._logger = logger;

    this.showtimes = new Collection({ db, logger, key: 'showtimes' });
    this.movies = new Collection({ db, logger, key: 'movies' });
    this.cinemas = new Collection({ db, logger, key: 'cinemas' });
  }

  getSortedNowPlayingMovies(options) {
    expect(options).to.be.an.object().and.to.include(['city', 'sortMovies']);

    let match = {
      city: options.city,
      time: {
        $gt: new Date(),
        $lt: this.constructor._endOfDayInAlmaty()
      }
    };
    if (options.cinemaName) {
      match.cinemaName = options.cinemaName;
    }

    return Rx.Observable
      .zip(
        this.showtimes.aggregate([{
          $match: match
        }, {
          $group: {
            _id: '$movieTitle',
            showtimes: {
              $push: {
                time: '$time',
                format: '$format',
                language: '$language',
                prices: '$prices'
              }
            },
            averagePrice: { $avg: '$prices.adult' },
            minPrice: { $min: '$prices.adult' }
          }
        }]),
        this.movies.find({ releaseDate: null })
      )
      .map(([aggregation, movies]) => movies
        .map(movie => {
          const { averagePrice, minPrice, showtimes } = _
            .find(aggregation, ['_id', movie.title]) || {};

          return {
            averagePrice,
            minPrice,
            title: movie.title,
            popularity: movie.popularity,
            showtimes: (showtimes || []).map(showtime => _.set(
              showtime,
              'title',
              this.constructor._showtimeTitle(showtime)
            )),
            averageRating: this.constructor._averageMovieRating(movie.ratings)
          };
        })
        .sort((a, b) => {
          switch (options.sortMovies) {
            case 'popularity':
              if (!a.popularity && b.popularity) {
                return 1;
              } else if (a.popularity && !b.popularity) {
                return -1;
              }

              return a.popularity - b.popularity;
            case 'title':
              if (a.title < b.title) return -1;
              if (a.title > b.title) return 1;

              return 0;
            case 'rating':
              return b.averageRating - a.averageRating;
            case 'showtimes_count':
              return b.showtimes.length - a.showtimes.length;
            default:
              return 0;
          }
        })
      );
  }

  getSortedCinemas(options) {
    expect(options).to.be.an.object().and.to
      .include(['city', 'favoriteCinemas', 'sortCinemas']);

    let match = {
      city: options.city,
      time: {
        $gt: new Date(),
        $lt: this.constructor._endOfDayInAlmaty()
      }
    };
    if (options.movieTitle) {
      match.movieTitle = options.movieTitle;
    }

    return this.showtimes
      .aggregate([{
        $match: match
      }, {
        $group: {
          _id: '$cinemaName',
          showtimes: {
            $push: {
              time: '$time',
              format: '$format',
              language: '$language',
              prices: '$prices'
            }
          },
          averagePrice: { $avg: '$prices.adult' },
          minPrice: { $min: '$prices.adult' }
        }
      }])
      .map(aggregation => aggregation
        .map(cinema => ({
          averagePrice: cinema.averagePrice,
          minPrice: cinema.minPrice,
          name: cinema._id,
          isFavorite: options.favoriteCinemas.indexOf(cinema._id) > -1,
          showtimes: cinema.showtimes.map(showtime => _
            .set(showtime, 'title', this.constructor._showtimeTitle(showtime))
          )
        }))
        .sort((a, b) => {
          if (a.isFavorite && !b.isFavorite) {
            return -1;
          } else if (!a.isFavorite && b.isFavorite) {
            return 1;
          }

          switch (options.sortCinemas) {
            case 'price':
              return a.averagePrice - b.averagePrice;
            case 'name':
              if (a.name < b.name) return -1;
              if (a.name > b.name) return 1;

              return 0;
            case 'showtimes_count':
              return b.showtimes.length - a.showtimes.length;
            default:
              return 0;
          }
        })
        .map(cinema => _
          .set(cinema, 'name', (cinema.isFavorite ? '⭐️ ' : '') + cinema.name)
        )
      )
      .map(cinemas => {
        if (options.onlyShowFavoriteCinemas && options.favoriteCinemas.length) {
          return cinemas.filter(cinema => cinema.isFavorite);
        }

        return cinemas;
      });
  }

  getMovie(filter) {
    return this.movies
      .findOne(filter)
      .filter(movie => !!movie)
      .map(movie => _.set(
        movie,
        'averageRating',
        this.constructor._averageMovieRating(movie.ratings)
      ));
  }

  getCinema(filter) {
    return this.cinemas
      .findOne(filter)
      .filter(cinema => !!cinema);
  }

  findMovies(query, city, limit = 3) {
    return this.showtimes
      .aggregate([{
        $match: { city }
      }, {
        $group: { _id: '$movieTitle' }
      }])
      .map(movies => movies
        .map(movie => ({
          title: movie._id,
          score: similarity(movie._id, query)
        }))
        .filter(movie => movie.title.indexOf(query) > -1 || movie.score >= 0.3)
        .sort((a, b) => b.score - a.score)
      )
      .map(movies => movies
        .slice(0, Math.min(limit, movies.length))
        .map(movie => movie.title)
      )
      .flatMap(movies => movies.length
        ? this.movies.find({ title: { $in: movies } })
        : Rx.Observable.return([])
      );
  }

  findCinemas(query, city, limit = 3) {
    return this.showtimes
      .aggregate([{
        $match: { city }
      }, {
        $group: { _id: '$cinemaName' }
      }])
      .map(cinemas => cinemas
        .map(cinema => ({
          name: cinema._id,
          score: similarity(cinema._id, query)
        }))
        .filter(cinema => cinema.score >= 0.3)
        .sort((a, b) => b.score - a.score)
      )
      .map(cinemas => cinemas
        .slice(0, Math.min(limit, cinemas.length))
        .map(cinema => cinema.name)
      )
      .flatMap(cinemas => cinemas.length
        ? this.cinemas.find({ name: { $in: cinemas } })
        : Rx.Observable.return([])
      );
  }

  static _endOfDayInAlmaty() {
    const now = moment().tz('Asia/Almaty');

    return now.hours() < 4
      ? now.startOf('day').add(4, 'hours').toDate()
      : now.endOf('day').add(4, 'hours').toDate();
  }

  static _averageMovieRating(ratings) {
    const normalizedRatings = _.keys(ratings || {})
      .reduce((normalizedRatings, ratingKey) =>
        ['kinopoisk', 'imdb'].indexOf(ratingKey) > -1
          ? normalizedRatings.concat(ratings[ratingKey] * 10)
          : normalizedRatings.concat(ratings[ratingKey]),
        []
      );

    return normalizedRatings.length
      ? Math.round(_.sum(normalizedRatings) / normalizedRatings.length)
      : 0;
  }

  static _showtimeTitle(showtime) {
    const time = moment.tz(showtime.time, 'Asia/Almaty').format('HH:mm');
    const attributes = _
      .compact([showtime.format, showtime.language])
      .join(', ');

    return time + (attributes && attributes.length ? ` _(${attributes})_` : '');
  }
}

module.exports = DataInteractor;
