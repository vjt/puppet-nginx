document.addEventListener ('DOMContentLoaded', function () {
  var name = document.querySelector ('.banner');
  name.addEventListener ('click', function () {
    name.className = 'roll';
    setTimeout (function () { name.className = '' }, 4001);
  });
});
