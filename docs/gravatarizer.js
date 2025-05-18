// Credit to ME!!
const Gravatarizer = {
  base_url: "https://gravatar.com/avatar/",
  params: {
    "d": "identicon",
    "s": "200",
  },
  bindTo: document.querySelector("#email"),

  init: async function() {
    const emailInUrl = this.emailFromUrl();
    if (emailInUrl.length > 0) {
      return await this.redirect(emailInUrl);
    }
    this.bindEvents();
  },

  bindEvents: function() {
    this.bindTo.form.addEventListener("submit", () => this.redirect(this.bindTo.value));
  },

  // Credit: https://gist.github.com/HaNdTriX/239f45939ee8b9f012861bb22808ba42
  hasher: async function(email) {
    const arrayBuffer = new TextEncoder("utf-8").encode(email);
    const hashAsArrayBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
    const uint8ViewOfHash = new Uint8Array(hashAsArrayBuffer);
    return Array.from(uint8ViewOfHash).map((b) => b.toString(16).padStart(2, '0')).join('');
  },

  emailFromUrl: function() {
    if (window.location.protocol == "file:") {
      return "";
    }

    const parts = window.location.pathname.split("/");
    if (parts.length < 2) {
      return "";
    }

    const email = window.location.pathname.split("/").at(-1);
    if (email =~ /^\S+@\S+\.\S+$/) {
      return email;
    }

    return "";
  },

  redirect: async function(email) {
    const qs = '?' + new URLSearchParams(this.params).toString();
    const destination = this.base_url + await this.hasher(email) + qs;
    window.location.href = destination;
  }
}

export default Gravatarizer;
