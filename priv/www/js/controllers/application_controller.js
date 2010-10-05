// ------------------------ //
// Application "Controller" //
// ------------------------ //

var application_controller = function(app) {
  this.element_selector = '#main';
  this.use(Sammy.Haml);
  this.use(Sammy.JSON);
  this.interval_ids = [];

  this.before(function() {
    var context = this;
    this.clear_intervals();
    if(context.path != "#/login") {
      this.load_current_user();
    }
  });

  this.after(function() {
    var context = this;
    this.render_view(context);
  });

  var _oldredirect = Sammy.EventContext.prototype.redirect;
  Sammy.EventContext.prototype.redirect = function() {
    this.no_swap = true;
    _oldredirect.apply(this, arguments);
  };


  // ======= //
  // Helpers //
  // ======= //

  this.helpers({
    render_view: function(context) {
      if(this.no_swap !== true) {
        if(context.template != undefined) {
          var view_path = this.template_path(context.template);
        } else {
          var view_path = this.view_for_route(context.path);
        }
        this.app.swap();
        this.partial(view_path);
      }
    },

    get_page: function(url, model) {
      var context = this;
      console.log("initiating ajax get: " + url);
      $.ajax({
        type: "GET",
        async: false,
        url: url,
        dataType: "json",
        success: function(data){
          context[model] = data[model];
        }
      });
    },

    post_page: function(url, data, context, model) {
      console.log("initiating ajax post: " + url);
      $.ajax({
        type: "POST",
        async: false,
        url: url,
        data: this.json(data),
        dataType: "json",
        error: function(XMLHttpRequest, textStatus, errorThrown){
          console.log("POST error: ");
          console.log(XMLHttpRequest);
          console.log(textStatus);
          console.log(errorThrown);
          context['error'] = true;
        },
        success: function(data){
          context[model] = data;
        }
      });
    },

    delete_page: function(url, data, context, model) {
      console.log("initiating ajax delete: " + url);
      $.ajax({
        type: "DELETE",
        async: false,
        url: url,
        data: data,
        dataType: "json",
        error: function(XMLHttpRequest, textStatus, errorThrown){
          console.log("DELETE error:");
          console.log(XMLHttpRequest);
          console.log(textStatus);
          console.log(errorThrown);
        },
        success: function(data){
          console.log("DELETE success:");
          context[model] = data;
        }
      });

    },
    load_current_user: function() {
      var user = Sammy.store.get('user');
      if(user == undefined) {
        console.log("Failed.  no user defined");
        this.redirect("#/login");
      } else {
        Sammy.current_user = user;
      }
    },

    auto_reload: function(resource, model, interval, partial) {
      var context = this;
      if(interval === undefined) {
        interval = 5000;
      }

      if(partial === undefined) {
        partial = this.view_for_route(this.path);
      }
      var interval_id = setInterval(function(){
        context.get_page(resource, model);
        context.partial(partial);
      }, interval);

      app.interval_ids.push(interval_id);
    },

    get_token: function(email, password) {
      var auth = {};
      var auth_url = "/auth.json";
      var auth_params = {email: email, password: password};
		  this.post_page(auth_url, auth_params, auth, "response");
		  return auth.response.token;
    },

    clear_intervals: function() {
      $.each(app.interval_ids, function(index, interval_id) {
        clearInterval(interval_id);
      });
      app.interval_ids = [];
    },

    // uses the path to guess the controller/action/view
    view_for_route: function(route) {
      var views_basepath = '/js/views';

      var route_components = route.split("/");
      var controller = route_components[1];
      var action = route_components[2];
      if(action === undefined) {
        action = "index";
      } else if(action === ":*") {
        action = "show";
      }
      return views_basepath + "/" + controller + "/" + action + ".haml";
    },

    template_path: function(template) {
      return '/js/views/' + template + '.haml';
    },

    opts_to_string: function(opts) {
      var opts_string = "";
      $.each(opts, function(key, value) {
        opts_string = " " + opts_string + key + "=" + '"' + value + '"';
      });
      return opts_string;
    },

    link_to: function(link_text, url, opts) {
      if ( opts === undefined ) {
            opts = {};
      }
      var opts_string = this.opts_to_string(opts);
      console.log(opts_string);

      return '<a href="' + url + '"' + opts_string + '>' + link_text + '</a>';
    }

  });

};