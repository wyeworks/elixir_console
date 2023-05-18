import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let Hooks = {};
Hooks.CommandInput = {
  mounted() {
    const el = this.el;
    this.handleEvent("reset", () => {
      el.value = "";
    });
    el.addEventListener("keydown", (e) => {
      if (e.code === "Tab") {
        this.pushEventTo(
          "#commandInput",
          "suggest",
          {"value": el.value, "caret_position": el.selectionEnd}
        );
      } else if (e.code === "ArrowUp") {
        this.pushEventTo("#commandInput", "cycle_history_up");
      } else if (e.code === "ArrowDown") {
        this.pushEventTo("#commandInput", "cycle_history_down");
      }
    });
  },
  updated() {
    const newValue = this.el.dataset.input_value;
    const newCaretPosition = parseInt(this.el.dataset.caret_position);

    if (newValue !== "") {
      this.el.value = newValue;
      this.el.setSelectionRange(newCaretPosition, newCaretPosition);
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
/* eslint-disable camelcase */
let liveSocket = new LiveSocket(
  "/live",
  Socket,
  {
    params: {_csrf_token: csrfToken},
    hooks: Hooks,
    metadata: {
      keydown: (_e, el) => {
        return {caret_position: el.selectionEnd};
      }
    }
  }
);
/* eslint-enable camelcase */

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

document.addEventListener("DOMContentLoaded", () => {
  const input = document.getElementById("commandInput");
  input.addEventListener("keydown", (e) => {
    if (e.code === "Tab") {
      e.preventDefault();
    }
  }, true);
});
