'use strict';

const similarity = require('similarity');
const slug = require('slug');

module.exports.circledNumber = number => {
  switch (number) {
    case 1: return '➊';
    case 2: return '➋';
    case 3: return '➌';
    case 4: return '➍';
    case 5: return '➎';
    case 6: return '➏';
    case 7: return '➐';
    case 8: return '➑';
    case 9: return '➒';
    case 10: return '➓';
    default: return number;
  }
};

module.exports.similarity = (title, query) => {
  if (!title || !query) {
    return 0;
  }

  const slugQuery = slug(query).replace('sine', 'cine');

  let score = Math.max(
    similarity(title, query),
    similarity(title, slugQuery)
  );

  if (score < 0.7 && (
      title.toLowerCase().indexOf(query.toLowerCase()) > -1 ||
      title.toLowerCase().indexOf(slugQuery.toLowerCase()) > -1
    )) {
    score += 0.3;
  }

  return score;
};
