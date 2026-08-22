// Dotstash — public API
const dotstash = require("../lib/dotstash");

module.exports = {
  stash: dotstash.stash,
  link: dotstash.link,
  linkAll: dotstash.linkAll,
  list: dotstash.list,
  remove: dotstash.remove,
  status: dotstash.status,
};
