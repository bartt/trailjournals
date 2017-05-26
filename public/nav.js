class Trailjournals {
  static addNavLinks () {
    var id = Trailjournals.getQueryParameter('id');
    var hiker_id = Trailjournals.getQueryParameter('hiker_id');
    if (id) {
      Trailjournals.getNavIds(id)
        .then((links) => {
          var nav = document.querySelector('.nav');
          var html = '';
          links.forEach((link) => {
            html += '<a href="/entry?id=' + link.id;
            if (hiker_id) {
              html += '&hiker_id=' + hiker_id;
            }
            html += '">' + link.text + '</a> ';
          });
          nav.innerHTML = html;
        })
        .then(Trailjournals.addNavKeyListener);
    }
  }

  static getQueryParameter (name) {
    var queryStr = window.location.search.replace(/^\?/, '');
    var params = {};
    queryStr.split('&').forEach((paramStr) => {
      var param = paramStr.split('=');
      params[param[0]] = param[1] || '';
    });
    return params[name];
  }

  static getNavIds (id) {
    return fetch(new Request('/proxy?id=' + id))
      .then((response) => {
        return response.text();
      })
      .then((html) => {
        var el = document.createElement('div');
        el.innerHTML = html;
        var ls = el.querySelectorAll('.entry-nav-nexprev a');
        // Navigation links are repeated below the post. Only need then once.
        ls = Array.prototype.slice.call(ls, 0, ls.length / 2);
        return ls.map((l) => {
          return {
            text: l.text,
          id: l.getAttribute('href').split('/').pop()};
        });
      });
  }

  static addNavKeyListener () {
    document.addEventListener('keydown', (event) => {
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
    });
  }
}

Trailjournals.addNavLinks();
