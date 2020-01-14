import hljs from "highlight.js/lib/highlight.js";
import json from "highlight.js/lib/languages/json";

hljs.registerLanguage("json", json);

export default function(code) {
  return hljs.highlight("json", code, true).value;
}