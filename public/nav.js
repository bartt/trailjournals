class Trailjournals {
  constructor (id, hiker_id) {
    this.id = id;

    this.hiker_id = hiker_id;
  }

  addNavLinks () {
    if (this.id) {
      this.getNavIds()
        .then((links) => {
          const nav = document.querySelector('.nav');
          let html = '';
          links.forEach((link) => {
            html += '<a href="/entry?id=' + link.id;
            if (this.hiker_id) {
              html += '&hiker_id=' + this.hiker_id;
            }
            html += '">' + link.text + '</a> ';
          });
          nav.innerHTML = html;
        })
        .then(Trailjournals.addNavKeyListener);
    }
  }

  getNavIds () {
    return fetch(new Request('/proxy?id=' + this.id))
      .then((response) => {
        return response.text();
      })
      .then((html) => {
        const el = document.createElement('div');
        el.innerHTML = html;
        let ls = el.querySelectorAll('.entry-nav-nexprev a');
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
      let navId;
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
        const navLink = document.querySelector('a#' + navId);
        if (navLink) {
          navLink.click();
        }
      }
    });
  }

  static getQueryParameter (name) {
    const queryStr = window.location.search.replace(/^\?/, '');
    const params = {};
    queryStr.split('&').forEach((paramStr) => {
      const param = paramStr.split('=');
      params[param[0]] = param[1] || '';
    });
    return params[name];
  }
}

const trailjournals = new Trailjournals(
  Trailjournals.getQueryParameter('id'),
  Trailjournals.getQueryParameter('hiker_id'));
trailjournals.addNavLinks();
