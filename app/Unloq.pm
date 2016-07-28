package Unloq;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/authenticate')->to('authenticate#authenticate');
  $r->get('/authorize')->to('authenticate#authorize');
  $r->get('/encryption')->to('authenticate#encryption');
  $r->get('/login')->to('authenticate#login');
}

1;
