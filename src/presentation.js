/* globals window */

let module = window.Elm;
window.moduleName.split(".").forEach(segment => {
  module = module[segment];
});
module.init();
