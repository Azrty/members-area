module.exports = ({get, post, all}) ->
  get '/', 'static#home'
  all '/login', 'session#login'
  all '/logout', 'session#logout'
  all '/register', 'registration#register'
  all '/verify', 'registration#verify'
  all '/dashboard', 'user#dashboard'
  all '/roles', 'role#index'
  all '/roles/applications', 'role#applications'
  all '/roles/applications/:id', 'role#application'
  all '/settings', 'admin#settings'
  all '/settings/roles', 'role#admin'
  all '/settings/roles/:role_id', 'role#edit'
