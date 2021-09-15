// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../css/app.css';

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
    const el = this.el;
    this.handleEvent('reset', () => {
      el.value = '';
    });
    el.addEventListener('keydown', (e) => {
      if (e.code === 'Tab') {
        this.pushEventTo(
          '#commandInput',
          'suggest',
          {'value': el.value, 'caret_position': el.selectionEnd}
        );
      } else if (e.code === 'ArrowUp' || e.code === 'ArrowDown') {
        this.pushEventTo('#commandInput', 'cycle_history', { key: e.code });
      } else {
        this.pushEventTo('#commandInput', 'reset_history', {});
      }
    });
  },
  updated() {
    const newValue = this.el.dataset.input_value;
    const newCaretPosition = parseInt(this.el.dataset.caret_position);

    if (newValue !== '') {
      this.el.value = newValue;
      this.el.setSelectionRange(newCaretPosition, newCaretPosition);
    }
  }
};

let csrfToken = document.querySelector('meta[name=\'csrf-token\']').getAttribute('content');
/* eslint-disable camelcase */
let liveSocket = new LiveSocket(
  '/live',
  Socket,
  {
    hooks: Hooks,
    params: {_csrf_token: csrfToken},
    metadata: {
      keydown: (_e, el) => {
        return {caret_position: el.selectionEnd};
      }
    }
  }
);
/* eslint-enable camelcase */
liveSocket.connect();

document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('commandInput');
  input.addEventListener('keydown', (e) => {
    if (e.code === 'Tab') {
      e.preventDefault();
    }
  }, true);
});
