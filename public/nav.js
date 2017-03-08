function addNavLinks() {
  var id = window.location.search.split('=').pop();
  if (id) {
    getNavIds(id).then(function(links) {
      var nav = document.querySelector('.nav');
      var html = '';
      links.forEach(function(link){
        html += '<a href="/entry?id=' + link.id + '">' + link.text + '</a> '
      })
      nav.innerHTML = html
    })
  }
}

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
}

addNavLinks();
