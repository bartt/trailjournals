class Trailjournals {
  constructor (id, hiker_id) {
    this.id = id;
    this.hiker_id = hiker_id;
    this.activateTheme(Trailjournals.getActiveTheme());
    this.addThemeListener();
    this.addNavLinks();
  }

  activateTheme (theme) {
    if (Trailjournals.THEMES.find((el) => {
        return el == theme;})) {
      this.theme = theme;
    } else {
      this.theme = Trailjournals.THEMES[0];
    }
    document.cookie = 'theme=' + this.theme + '; max-age=' + Trailjournals.YEAR + '; path=/;';
    document.querySelector('.theme .light').classList.toggle('selected', this.theme == 'light');
    document.querySelector('.theme .dark').classList.toggle('selected', this.theme == 'dark');
    Trailjournals.THEMES.forEach((theme) => {
      document.body.classList.remove(theme);
    });
    document.body.classList.add(this.theme);
  }

  addThemeListener () {
    document.querySelector('.theme').addEventListener('click', (e) => {
      this.handleThemeClick(e);
    });
  }

  handleThemeClick (e) {
    if (!e.target.classList.contains(this.theme)) {
      let theme;
      e.target.classList.forEach((c) => {
        if (!!Trailjournals.THEMES.find((t) => {
            return t == c;})) {
          theme = c;
        }
      });
      this.activateTheme(theme);
    }
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
            html += '" id="' + link.text.toLowerCase() + '">' + link.text + '</a> ';
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

  static getActiveTheme () {
    const cookieStr = document.cookie;
    const cookies = {};
    cookieStr.split(';').forEach((pair) => {
      const cookie = pair.split('=');
      cookies[cookie[0]] = cookie[1];
    });
    return cookies['theme'];
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

Trailjournals.YEAR = 60 * 60 * 24 * 365;
Trailjournals.THEMES = ['light', 'dark'];

new Trailjournals(
  Trailjournals.getQueryParameter('id'),
  Trailjournals.getQueryParameter('hiker_id'));
