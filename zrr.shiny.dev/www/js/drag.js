$(document).on("change", "div.drag", function(evt) {

  // evt.target is the button that was clicked
  var el = $(evt.target);

  // alert the value to see if this event is triggered properly
  alert(el.html());

  // Raise an event to signal that the value changed
  el.trigger("change");
});

var dragBinding = new Shiny.InputBinding();
$.extend(dragBinding, {
  find: function(scope) {
    return $(scope).find(".increment");
  },
  getValue: function(el) {
    return $(el).html();
  },
  setValue: function(el, value) {
    $(el).html(value);
  },
  subscribe: function(el, callback) {
    $(el).on("change.dragBinding", function(e) {
      callback();
    });
  },
  unsubscribe: function(el) {
    $(el).off(".dragBinding");
  }
});

Shiny.inputBindings.register(dragBinding);