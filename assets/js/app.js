// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from '../css/app.css';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import 'phoenix_html';

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import {Socket} from 'phoenix';
import LiveSocket from 'phoenix_live_view';

let Hooks = {};
Hooks.CommandInput = {
  mounted() {
    const input = document.getElementById('commandInput');
    const sendCursorPosition = e => {
      if (input.selectionStart === input.selectionEnd) {
        this.pushEventTo('#commandInput', 'caret-position', { position: input.selectionEnd });
      }
    };

    ['keyup', 'click', 'focus'].forEach(event => {
      input.addEventListener(event, sendCursorPosition, true);
    });
  },
  updated() {
    const newValue = this.el.getAttribute('data-input_value');
    const newCaretPosition = parseInt(this.el.getAttribute('data-caret_position'));

    if (newValue !== '') {
      this.el.value = newValue;
      this.el.setSelectionRange(newCaretPosition, newCaretPosition);
    }
  }
};

let csrfToken = document.querySelector('meta[name=\'csrf-token\']').getAttribute('content');
let liveSocket = new LiveSocket('/live', Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}});
liveSocket.connect();

document.addEventListener('DOMContentLoaded', function(event) {
  let input = document.getElementById('commandInput');
  input.addEventListener('keydown', function(e) {
    if (e.keyCode === 9) {
      e.preventDefault();
    }
  }, true);
})
