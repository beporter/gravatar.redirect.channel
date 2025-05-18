// Credit to: https://css-tricks.com/email-domain-datalist-helper/
const EmailDomainSuggester = {
  domains: [
    "yahoo.com",
    "gmail.com",
    "hotmail.com",
    "me.com",
    "aol.com",
    "mac.com",
    "live.com",
    "comcast.com",
  ],

  bindTo: document.querySelector("#email"),

  init: function() {
    this.addElements();
    this.bindEvents();
  },

  addElements: function() {
    // Create empty datalist
    this.datalist = document.createElement("datalist");
    this.datalist.setAttribute("id", "email-options");
    this.bindTo.parentNode.appendChild(this.datalist);
    // Corelate to input
    this.bindTo.setAttribute("list", "email-options");
  },

  bindEvents: function() {
    this.bindTo.addEventListener("keyup", this.testValue);
  },

  testValue: function(event) {
    var el = this,
        value = el.value;

    if (event.key == "ArrowUp" || event.key == "ArrowDown") {
      return;
    }

    // email has @
    // remove != -1 to open earlier
    if (value.indexOf("@") != -1) {
      value = value.split("@")[0];
      EmailDomainSuggester.addDatalist(value);
    } else {
    // empty list
      EmailDomainSuggester.datalist.replaceChildren();
    }
  },

  addDatalist: function(value) {
    var options = [];
    for (let i = 0; i < this.domains.length; i++) {
      const option = document.createElement('option');
      option.value = value + "@" + this.domains[i];
      options.push(option);
    }
    this.datalist.replaceChildren(...options);
  }
}

export default EmailDomainSuggester;
