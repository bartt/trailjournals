function addNavLinks() {
  var id = window.location.search.split('=').pop();
  if (id) {
    getNavIds(id)
      .then(function(links) {
        var nav = document.querySelector('.nav');
        var html = '';
        links.forEach(function(link){
          html += '<a href="/entry?id=' + link.id + '" id="' + link.text + '">' + link.text + '</a> '
        })
        nav.innerHTML = html
      })
      .then(addNavKeyListener);
  }
};

function getNavIds(id) {
  return fetch(new Request('/proxy?id=' + id))
    .then(function(response) {
        return response.text();
      })
    .then(function(html) {
      var el = document.createElement("div");
      el.innerHTML = html;
      var ls = el.querySelectorAll('a.link');
      // Navigation links are repeated below the post. Only need then once.
      ls = Array.prototype.slice.call(ls, 0, ls.length / 2);
      return ls.map(function(l) {
        return {
          text: l.text,
          id: l.getAttribute('href').split('=').pop()}
        });
    });
};

function addNavKeyListener() {
  document.addEventListener('keydown', function(event) {
    var navId;
    switch (event.keyCode) {
      case 70 /* f */:
        navId = 'first';
        break;
      case 74 /* j */:
        navId = 'previous';
        break;
      case 75 /* k */:
        navId = 'next';
        break;
      case 76 /* l */:
        navId = 'last';
        break;
      default:
    }
    if (navId) {
      var navLink = document.querySelector('a#' + navId);
      if (navLink) {
        navLink.click();
      }
    }
  })
};

addNavLinks();
